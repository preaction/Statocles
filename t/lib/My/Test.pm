package My::Test;

# ABSTRACT: Utilities for testing Statocles Tests

use strict;
use warnings;

use base 'Import::Base';

our @IMPORT_MODULES = (
    sub {
        # Disable spurious warnings on platforms that Net::DNS::Native does not
        # support. We don't use this much mojo
        $ENV{MOJO_NO_NDN} = 1;
        return;
    },
    strict => [],
    warnings => [],
    feature => [qw( :5.10 )],
    'Path::Tiny' => [qw( rootdir cwd )],
    'DateTime::Moonpig',
    'Statocles',
    qw( Test::More Test::Deep Test::Differences Test::Exception ),
    'Dir::Self' => [qw( __DIR__ )],
    'Path::Tiny' => [qw( path tempdir cwd )],
    'Statocles::Test' => [qw(
      build_test_site build_test_site_apps
      build_temp_site
    )],
    'Statocles::Types' => [qw( DateTimeObj )],
    'My::Test::_Extras' => [qw( test_constructor test_pages test_page_objects )],
);

package My::Test::_Extras;

$INC{'My/Test/_Extras.pm'} = 1;

require Exporter;
*import = \&Exporter::import;

our @EXPORT_OK = qw( test_constructor test_pages test_page_objects );

sub test_constructor {
    my ( $class, %args ) = @_;

    my %required = $args{required} ? ( %{ $args{required} } ) : ();
    my %defaults = $args{default}  ? ( %{ $args{default} } )  : ();
    require Test::Builder;
    require Scalar::Util;
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $tb = Test::Builder->new();

    $tb->subtest(
        $class . ' constructor' => sub {
            my $got    = $class->new(%required);
            my $want   = $class;
            my $typeof = do {
                    !defined $got                ? 'undefined'
                  : !ref $got                    ? 'scalar'
                  : !Scalar::Util::blessed($got) ? ref $got
                  : eval { $got->isa($want) } ? $want
                  :                             Scalar::Util::blessed($got);
            };
            $tb->is_eq( $typeof, $class,
                'constructor works with all required args' );

            if ( $args{required} ) {
                $tb->subtest(
                    'required attributes' => sub {
                        for my $key ( keys %required ) {
                            require Test::Exception;
                            &Test::Exception::dies_ok(
                                sub {
                                    $class->new(
                                        map { ; $_ => $required{$_} }
                                        grep { $_ ne $key } keys %required,
                                    );
                                },
                                $key . ' is required'
                            );
                        }
                    }
                );
            }

            if ( $args{default} ) {
                $tb->subtest(
                    'attribute defaults' => sub {
                        my $obj = $class->new(%required);
                        for my $key ( keys %defaults ) {
                            if ( ref $defaults{$key} eq 'CODE' ) {
                                local $_ = $obj->$key;
                                $tb->subtest(
                                    "$key default value" => $defaults{$key} );
                            }
                            else {
                                require Test::Deep;
                                Test::Deep::cmp_deeply( $obj->$key,
                                    $defaults{$key}, "$key default value" );
                            }
                        }
                    }
                );
            }

        }
    );
}

sub test_pages {
    my ( $site, $app ) = ( shift, shift );

    require Test::Builder;
    require Scalar::Util;

    my %opt;
    if ( ref $_[0] eq 'HASH' ) {
        %opt = %{ +shift };
    }

    my %page_tests = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $tb = Test::Builder->new();

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    my @pages = $app->pages;

    my %pages_app = map { ($_->path => 1) } @pages;
    my %page_tests_copy = %page_tests;
    delete @page_tests_copy{ keys %pages_app };
    delete @pages_app{ keys %page_tests };

    $tb->cmp_ok(
        scalar(keys %pages_app),
        '==',
        0,
        'No untested pages'
    ) or $tb->diag( "Extra app pages: " . join( ", ", sort keys %pages_app ) );

    $tb->cmp_ok(
        scalar(keys %page_tests_copy),
        '==',
        0,
        'No unpaged tests'
    ) or $tb->diag( "Extra pages tested: " . join( ", ", sort keys %page_tests_copy ) );

    for my $page (@pages) {
        $tb->ok( $page->DOES('Statocles::Role::Page'), 'must be a Statocles::Role::Page' );

        my $date   = $page->date;
        my $want   = 'DateTime::Moonpig';
        my $typeof = do {
                !defined $date                ? 'undefined'
              : !ref $date                    ? 'scalar'
              : !Scalar::Util::blessed($date) ? ref $date
              : eval { $date->isa($want) } ? $want
              :                              Scalar::Util::blessed($date);
        };
        $tb->is_eq( $typeof, $want, 'must set a date' );

        if ( !$page_tests{ $page->path } ) {
            $tb->ok( 0, "No tests found for page: " . $page->path );
            next;
        }

        my $output;

        if ( $page->has_dom ) {
            $output = "".$page->dom;
        }
        else {
            $output = $page->render;
            # Handle filehandles from render
            if ( ref $output eq 'GLOB' ) {
                $output = do { local $/; <$output> };
            }
            # Handle Path::Tiny from render
            elsif ( Scalar::Util::blessed( $output ) && $output->isa( 'Path::Tiny' ) ) {
                $output = $output->slurp_raw;
            }
        }

        if ( $page->path =~ m#(?:/|[.](?:html|rss|atom))$# ) {
            require Mojo::DOM;
            my $dom = Mojo::DOM->new($output);
            $tb->ok( 0, "Could not parse dom" ) unless $dom;
            $tb->subtest(
                'html content: ' . $page->path,
                $page_tests{ $page->path },
                $output, $dom
            );
        }
        elsif ( $page_tests{ $page->path } ) {
            $tb->subtest( 'text content: ' . $page->path,
                $page_tests{ $page->path }, $output );
        }
        else {
            $tb->ok( 0, "Unknown page: " . $page->path );
        }

    }

    $tb->ok( !@warnings, "no warnings!" ) or $tb->diag( join "\n", @warnings );
}

=head2 test_page_objects

Run the given subtests for each page object in the list of pages

=cut

sub test_page_objects {
    my ( $pages, %tests ) = @_;

    require Test::Builder;
    require Scalar::Util;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $tb = Test::Builder->new();

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    ### Check if we're testing all the pages
    my %pages = map { ($_->path => 1) } @$pages;
    my %page_tests_copy = %tests;
    delete @page_tests_copy{ keys %pages };
    delete @pages{ keys %tests };

    $tb->cmp_ok(
        scalar(keys %pages),
        '==',
        0,
        'No untested pages'
    ) or $tb->diag( "Found untested pages: " . join( ", ", sort keys %pages ) );

    $tb->cmp_ok(
        scalar(keys %page_tests_copy),
        '==',
        0,
        'No unpaged tests'
    ) or $tb->diag( "Test defined but no page found: " . join( ", ", sort keys %page_tests_copy ) );

    for my $page (@$pages) {
        $tb->ok( $page->DOES('Statocles::Role::Page'), 'must be a Statocles::Role::Page' );

        my $date   = $page->date;
        my $want   = 'DateTime::Moonpig';
        my $typeof = do {
                !defined $date                ? 'undefined'
              : !ref $date                    ? 'scalar'
              : !Scalar::Util::blessed($date) ? ref $date
              : eval { $date->isa($want) } ? $want
              :                              Scalar::Util::blessed($date);
        };
        $tb->is_eq( $typeof, $want, 'must set a date' );

        if ( !$tests{ $page->path } ) {
            $tb->ok( 0, "No tests found for page: " . $page->path );
            next;
        }

        $tb->subtest(
            'page object test: ' . $page->path,
            $tests{ $page->path }, $page,
        );

    }

    $tb->ok( !@warnings, "no warnings!" ) or $tb->diag( join "\n", @warnings );
}
1;
