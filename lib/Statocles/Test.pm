package Statocles::Test;
our $VERSION = '0.090';
# ABSTRACT: Common test routines for Statocles

use Statocles::Base;
use Statocles::Util qw( dircopy derp );

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
    require Statocles::Store;
    require Statocles::Deploy::File;

    my $store   = $site_args{build_store}
                ? Statocles::Store->new( delete $site_args{build_store} )
                : Path::Tiny->tempdir
                ;

    my $deploy  = $site_args{deploy}
                ? Statocles::Deploy::File->new( delete $site_args{deploy} )
                : Path::Tiny->tempdir
                ;

    # Give a testable logger by default, but only if we haven't asked
    # for some verbose logging from the environment
    my $log     = $site_args{log}
                || Mojo::Log->new(
                    level => 'warn',
                    max_history_size => 500,
                );

    return Statocles::Site->new(
        title => 'Example Site',
        build_store => $store,
        deploy => $deploy,
        log => $log,
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

        require Statocles::App::Basic;
        my $basic = Statocles::App::Basic->new(
            store => $share_dir->child( qw( app basic ) ),
            url_root => '/',
        );

        $site_args{apps} = {
            blog => $blog,
            basic => $basic,
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


sub test_constructor {
    my ( $class, %args ) = @_;
    derp 'Statocles::Test::test_constructor is deprecated and will be removed in v1.000';
    my %required = $args{required} ? ( %{ $args{required} } ) : ();
    my %defaults = $args{default} ? ( %{ $args{default} } ) : ();
    require Test::Builder;
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $tb = Test::Builder->new();

    $tb->subtest( $class . ' constructor' => sub {
        my $got   = $class->new( %required );
        my $want   = $class;
        my $typeof = do {
                !defined $got                ? 'undefined'
              : !ref $got                    ? 'scalar'
              : !Scalar::Util::blessed($got) ? ref $got
              : eval { $got->isa($want) } ? $want
              :                             Scalar::Util::blessed($got);
        };
        $tb->is_eq($typeof, $class, 'constructor works with all required args');

        if ( $args{required} ) {
            $tb->subtest( 'required attributes' => sub {
                for my $key ( keys %required ) {
                    require Test::Exception;
                    &Test::Exception::dies_ok(sub {
                        $class->new(
                            map {; $_ => $required{ $_ } } grep { $_ ne $key } keys %required,
                        );
                    }, $key . ' is required');
                }
            });
        }

        if ( $args{default} ) {
            $tb->subtest( 'attribute defaults' => sub {
                my $obj = $class->new( %required );
                for my $key ( keys %defaults ) {
                    if ( ref $defaults{ $key } eq 'CODE' ) {
                        local $_ = $obj->$key;
                        $tb->subtest( "$key default value" => $defaults{ $key } );
                    }
                    else {
                        require Test::Deep;
                        Test::Deep::cmp_deeply( $obj->$key, $defaults{ $key }, "$key default value" );
                    }
                }
            });
        }

    });
}

sub test_pages {
    my ( $site, $app ) = ( shift, shift );
    derp 'Statocles::Test::test_pages is deprecated and will be removed in v1.000';
    require Test::Builder;

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

    $tb->is_eq( scalar @pages, scalar keys %page_tests, 'correct number of pages' );

    for my $page ( @pages ) {
        $tb->ok( $page->DOES( 'Statocles::Page' ), 'must be a Statocles::Page' );

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

        if ( $page->path =~ /[.](?:html|rss|atom)$/ ) {
            my $dom = Mojo::DOM->new( $output );
            $tb->ok( 0, "Could not parse dom" ) unless $dom;
            $tb->subtest( 'html content: ' . $page->path, $page_tests{ $page->path }, $output, $dom );
        }
        elsif ( $page_tests{ $page->path } ) {
            $tb->subtest( 'text content: ' . $page->path, $page_tests{ $page->path }, $output );
        }
        else {
            $tb->ok( 0, "Unknown page: " . $page->path );
        }

    }

    $tb->ok( !@warnings, "no warnings!" ) or $tb->diag( join "\n", @warnings );
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
            class => 'Statocles::Store',
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
                    '$class' => 'Statocles::Store',
                    '$args' => {
                        path => $tmp->child( 'blog' ),
                    },
                },
                url_root => '/blog',
            },
        },

        plain => {
            'class' => 'Statocles::App::Basic',
            'args' => {
                store => {
                    '$class' => 'Statocles::Store',
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
            class => 'Statocles::Store',
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

