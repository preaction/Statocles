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
    'My::Test::_Extras' => [qw(
      test_constructor test_pages test_page_objects
      make_writable
    )],
);

package My::Test::_Extras;

$INC{'My/Test/_Extras.pm'} = 1;

use constant WIN32 => $^O =~ /Win32/;
require Win32::File if WIN32;
require Exporter;
*import = \&Exporter::import;

our @EXPORT_OK = qw(
  test_constructor test_pages test_page_objects
  make_writable
);

sub make_writable {
    return if !WIN32;
    for (@_) {
        if (-d) {
            make_writable($_->children);
        } else {
            Win32::File::GetAttributes($_, my $attr);
            Win32::File::SetAttributes($_, $attr & ~Win32::File::READONLY());
        }
    }
}

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

    # Also do not test site pages
    delete @pages{ grep { m{robots.txt|sitemap.xml|^/theme} } keys %pages };

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
        # Do not test site pages
        next if $page->path =~ m{/robots.txt|/sitemap.xml|^/theme};

        $tb->ok( $page->DOES('Statocles::Page'), 'must be a Statocles::Page' );

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
