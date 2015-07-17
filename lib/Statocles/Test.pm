package Statocles::Test;
# ABSTRACT: Common test routines for Statocles

use Statocles::Base;
use Test::More;
use Test::Exception;
use Test::Deep;
use Statocles::Util qw( dircopy );

use base qw( Exporter );
our @EXPORT_OK = qw(
    test_constructor test_pages build_test_site build_test_site_apps
    build_temp_site
);

=sub build_test_site

    my $site = build_test_site( %site_args )

Build a site for testing. The build and deploy will be set correctly to temporary
directories. C<%site_args> will be given to the L<Statocles::Site|Statocles::Site>
constructor.

You must provide a C<theme> (probably using the one in C<t/share/theme>).

=cut

sub build_test_site {
    my ( %site_args ) = @_;
    require Statocles::Site;
    require Statocles::Store::File;
    require Statocles::Deploy::File;

    my $store   = $site_args{build_store}
                ? Statocles::Store::File->new( delete $site_args{build_store} )
                : Path::Tiny->tempdir
                ;

    my $deploy  = $site_args{deploy}
                ? Statocles::Deploy::File->new( delete $site_args{deploy} )
                : Path::Tiny->tempdir
                ;

    return Statocles::Site->new(
        title => 'Example Site',
        build_store => $store,
        deploy => $deploy,
        %site_args,
    );
}

=sub build_test_site_apps

    my ( $site, $build_dir, $deploy_dir ) = build_test_site_apps( $share_dir, %site_args );

Build a site for testing, with some apps. Returns the site, the build dir, and the
deploy dir.

=cut

sub build_test_site_apps {
    my ( $share_dir, %site_args ) = @_;

    my $build_dir = Path::Tiny->tempdir;
    my $deploy_dir = Path::Tiny->tempdir;

    $site_args{build_store}{path} = $build_dir;
    $site_args{deploy}{path} = $deploy_dir;

    if ( !$site_args{apps} ) {
        require Statocles::App::Blog;
        my $blog = Statocles::App::Blog->new(
            store => $share_dir->child( qw( app blog ) ),
            url_root => '/blog',
            page_size => 2,
        );

        require Statocles::App::Plain;
        my $plain = Statocles::App::Plain->new(
            store => $share_dir->child( qw( app plain ) ),
            url_root => '/',
        );

        require Statocles::App::Static;
        my $static = Statocles::App::Static->new(
            store => $share_dir->child( qw( app static ) ),
            url_root => '/static',
        );

        $site_args{apps} = {
            blog => $blog,
            static => $static,
            plain => $plain,
        };
    }

    return (
        build_test_site(
            theme => $share_dir->child( 'theme' ),
            build_store => delete $site_args{build_store},
            deploy => delete $site_args{deploy},
            %site_args,
        ),
        $build_dir,
        $deploy_dir,
    );
}

=sub test_constructor

    test_constructor( $class, %args )

Test an object constructor. C<class> is the class to test. C<args> is a list of
name/value pairs with the following keys:

=over 4

=item required

A set of name/value pairs for required arguments. These will be tested to ensure they
are required. They will be added to every attempt to construct an object.

=item default

A set of name/value pairs for default arguments. These will be tested to ensure they
are set to the correct defaults.

=back

=cut

sub test_constructor {
    my ( $class, %args ) = @_;

    my %required = $args{required} ? ( %{ $args{required} } ) : ();
    my %defaults = $args{default} ? ( %{ $args{default} } ) : ();

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    subtest $class . ' constructor' => sub {
        isa_ok $class->new( %required ), $class,
            'constructor works with all required args';

        if ( $args{required} ) {
            subtest 'required attributes' => sub {
                for my $key ( keys %required ) {
                    dies_ok {
                        $class->new(
                            map {; $_ => $required{ $_ } } grep { $_ ne $key } keys %required,
                        );
                    } $key . ' is required';
                }
            };
        }

        if ( $args{default} ) {
            subtest 'attribute defaults' => sub {
                my $obj = $class->new( %required );
                for my $key ( keys %defaults ) {
                    if ( ref $defaults{ $key } eq 'CODE' ) {
                        local $_ = $obj->$key;
                        subtest "$key default value" => $defaults{ $key };
                    }
                    else {
                        cmp_deeply $obj->$key, $defaults{ $key }, "$key default value";
                    }
                }
            };
        }

    };
}

=sub test_pages

    test_pages( $site, $app, %tests )

Test the pages of the given app. C<tests> is a set of pairs of C<path> => C<callback>
to test the pages returned by the app.

The C<callback> will be given two arguments:

=over

=item C<output>

The output of the rendered page.

=item C<dom>

If the page is HTML, a L<Mojo::DOM> object ready for testing.

=back

=cut

sub test_pages {
    my ( $site, $app ) = ( shift, shift );

    my %opt;
    if ( ref $_[0] eq 'HASH' ) {
        %opt = %{ +shift };
    }

    my %page_tests = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    my @pages = $app->pages;

    is scalar @pages, scalar keys %page_tests, 'correct number of pages';

    for my $page ( @pages ) {
        ok $page->DOES( 'Statocles::Page' ), 'must be a Statocles::Page';

        isa_ok $page->date, 'Time::Piece', 'must set a date';

        if ( !$page_tests{ $page->path } ) {
            fail "No tests found for page: " . $page->path;
            next;
        }

        my $output = $page->render( site => $site );
        # Handle filehandles from render
        if ( ref $output eq 'GLOB' ) {
            $output = do { local $/; <$output> };
        }

        if ( $page->path =~ /[.](?:html|rss|atom)$/ ) {
            my $dom = Mojo::DOM->new( $output );
            fail "Could not parse dom" unless $dom;
            subtest 'html content: ' . $page->path, $page_tests{ $page->path }, $output, $dom;
        }
        elsif ( $page_tests{ $page->path } ) {
            subtest 'text content: ' . $page->path, $page_tests{ $page->path }, $output;
        }
        else {
            fail "Unknown page: " . $page->path;
        }

    }

    ok !@warnings, "no warnings!" or diag join "\n", @warnings;
}

=sub build_temp_site

    my ( $tmpdir, $config_fn, $config ) = build_temp_site( $share_dir );

Build a config file so we can test config loading and still use
temporary directories

=cut

sub build_temp_site {
    my ( $share_dir ) = @_;

    my $tmp = Path::Tiny->tempdir;
    dircopy $share_dir->child( qw( app blog ) ), $tmp->child( 'blog' );
    dircopy $share_dir->child( 'theme' ), $tmp->child( 'theme' );
    $tmp->child( 'build_site' )->mkpath;
    $tmp->child( 'deploy_site' )->mkpath;
    $tmp->child( 'build_foo' )->mkpath;
    $tmp->child( 'deploy_foo' )->mkpath;

    my $config = {
        theme => {
            class => 'Statocles::Theme',
            args => {
                store => $tmp->child( 'theme' ),
            },
        },

        build => {
            class => 'Statocles::Store::File',
            args => {
                path => $tmp->child( 'build_site' ),
            },
        },

        deploy => {
            class => 'Statocles::Deploy::File',
            args => {
                path => $tmp->child( 'deploy_site' ),
            },
        },

        blog => {
            'class' => 'Statocles::App::Blog',
            'args' => {
                store => {
                    '$class' => 'Statocles::Store::File',
                    '$args' => {
                        path => $tmp->child( 'blog' ),
                    },
                },
                url_root => '/blog',
            },
        },

        plain => {
            'class' => 'Statocles::App::Plain',
            'args' => {
                store => {
                    '$class' => 'Statocles::Store::File',
                    '$args' => {
                        path => "$tmp",
                    },
                },
                url_root => '/',
            },
        },

        site => {
            class => 'Statocles::Site',
            args => {
                title => 'Site Title',
                index => '/blog',
                build_store => { '$ref' => 'build' },
                deploy => { '$ref' => 'deploy' },
                theme => { '$ref' => 'theme' },
                apps => {
                    blog => { '$ref' => 'blog' },
                    plain => { '$ref' => 'plain' },
                },
            },
        },

        build_foo => {
            class => 'Statocles::Store::File',
            args => {
                path => $tmp->child( 'build_foo' ),
            },
        },

        deploy_foo => {
            class => 'Statocles::Deploy::File',
            args => {
                path => $tmp->child( 'deploy_foo' ),
            },
        },

        site_foo => {
            class => 'Statocles::Site',
            args => {
                title => 'Site Foo',
                index => '/blog',
                build_store => { '$ref' => 'build_foo' },
                deploy => { '$ref' => 'deploy_foo' },
                theme => '::default',
                apps => {
                    blog => { '$ref' => 'blog' },
                    plain => { '$ref' => 'plain' },
                },
            },
        },
    };

    my $config_fn = $tmp->child( 'site.yml' );
    YAML::DumpFile( $config_fn, $config );
    return ( $tmp, $config_fn, $config );
}

1;
__END__

=head1 DESCRIPTION

This module provides some common test routines for Statocles tests.

