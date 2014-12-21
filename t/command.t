
use Statocles::Base 'Test';
my $SHARE_DIR = path( __DIR__, 'share' );
use FindBin;
use Capture::Tiny qw( capture );
use Statocles::Command;
use Statocles::Site;
use File::Copy::Recursive qw( dircopy );
use Mojo::IOLoop;
use Test::Mojo;
use Beam::Wire;
use YAML;

# Build a config file so we can test config loading and still use
# temporary directories
my $tmp = tempdir;
dircopy $SHARE_DIR->child( qw( app blog ) )->stringify, $tmp->child( 'blog' )->stringify;
dircopy $SHARE_DIR->child( 'theme' )->stringify, $tmp->child( 'theme' )->stringify;
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
        class => 'Statocles::Store',
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
            theme => { '$ref' => 'theme' },
        },
    },
    site => {
        class => 'Statocles::Site',
        args => {
            base_url => 'http://example.com',
            title => 'Site Title',
            index => 'blog',
            build_store => { '$ref' => 'build' },
            deploy_store => { '$ref' => 'deploy' },
            apps => {
                blog => { '$ref' => 'blog' },
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
        class => 'Statocles::Store',
        args => {
            path => $tmp->child( 'deploy_foo' ),
        },
    },
    site_foo => {
        class => 'Statocles::Site',
        args => {
            base_url => 'http://example.net',
            title => 'Site Foo',
            index => 'blog',
            build_store => { '$ref' => 'build_foo' },
            deploy_store => { '$ref' => 'deploy_foo' },
            apps => {
                blog => { '$ref' => 'blog' },
            },
        },
    },
};
my $config_fn = $tmp->child( 'site.yml' );
YAML::DumpFile( $config_fn, $config );

subtest 'get help' => sub {
    local $0 = path( $FindBin::Bin )->parent->child( 'bin', 'statocles' )->stringify;
    subtest '-h' => sub {
        my ( $out, $err, $exit ) = capture { Statocles::Command->main( '-h' ) };
        ok !$err, 'help output is on stdout';
        like $out, qr{statocles -h},
            'reports pod from bin/statocles, not Statocles::Command';
        is $exit, 0;
    };
    subtest '--help' => sub {
        my ( $out, $err, $exit ) = capture { Statocles::Command->main( '--help' ) };
        ok !$err, 'help output is on stdout';
        like $out, qr{statocles -h},
            'reports pod from bin/statocles, not Statocles::Command';
        is $exit, 0;
    };
};

subtest 'get version' => sub {
    local $Statocles::Command::VERSION = '1.00';
    my ( $output, $stderr, $exit ) = capture { Statocles::Command->main( '--version' ) };
    is $exit, 0;
    ok !$stderr, 'stderr is empty' or diag "STDERR: $stderr";
    is $output, "Statocles version 1.00 (Perl $^V)\n";
};

subtest 'error messages' => sub {
    local $0 = path( $FindBin::Bin )->parent->child( 'bin', 'statocles' )->stringify;

    my ( $out, $err, $exit ) = capture { Statocles::Command->main };
    ok !$out, 'error output is on stderr';
    like $err, qr{ERROR: Missing command};
    like $err, qr{statocles -h},
        'reports pod from bin/statocles, not Statocles::Command';
    isnt $exit, 0;
};


sub test_site {
    my ( $root, @args ) = @_;
    my $verbose = grep { /^-v$|^--verbose$/ } @args;
    return sub {
        local $ENV{MOJO_LOG_LEVEL}; # Test::Mojo sets this to "debug"
        my ( $out, $err, $exit ) = capture { Statocles::Command->main( @args ) };
        is $exit, 0, 'exit code';
        ok !$err, "no errors/warnings (verbose: $verbose)" or diag $err;
        ok $root->child( 'index.html' )->exists, 'index file exists';
        ok $root->child( 'sitemap.xml' )->exists, 'sitemap.xml exists';
        ok $root->child( 'blog', '2014', '04', '23', 'slug.html' )->exists;
        ok $root->child( 'blog', '2014', '04', '30', 'plug.html' )->exists;
        if ( $verbose ) {
            subtest 'verbose output is verbose' => sub {
                like $out, qr{Write file: /index[.]html};
                like $out, qr{Write file: sitemap[.]xml};
            };
        }
        else {
            ok !$out, 'no output without verbose' or diag $out;
        }
    };
}

subtest 'build site' => sub {
    my @args = (
        '--config' => "$config_fn",
        'build',
    );
    subtest 'default site' => test_site(
        $tmp->child( 'build_site' ),
        @args,
    );
    subtest 'custom site' => test_site(
        $tmp->child( 'build_foo' ),
        '--site' => 'site_foo',
        @args,
    );
    subtest 'verbose' => test_site(
        $tmp->child( 'build_site' ),
        @args,
        '-v',
    );
};

subtest 'deploy site' => sub {
    my @args = (
        '--config' => "$config_fn",
        'deploy',
    );
    subtest 'default site' => test_site(
        $tmp->child( 'deploy_site' ),
        @args,
    );
    subtest 'custom site' => test_site(
        $tmp->child( 'deploy_foo' ),
        '--site' => 'site_foo',
        @args,
    );
    subtest 'verbose' => test_site(
        $tmp->child( 'deploy_site' ),
        @args,
        '--verbose',
    );
};

subtest 'get the app list' => sub {
    my @args = (
        '--config' => "$config_fn",
        'apps',
    );
    my ( $out, $err, $exit ) = capture { Statocles::Command->main( @args ) };
    ok !$err, 'app list is on stdout';
    is $exit, 0;
    is $out, "blog (/blog -- Statocles::App::Blog)\n",
        'contains app name, url root, and app class';
};

subtest 'delegate to app command' => sub {
    my @args = (
        '--config' => "$config_fn",
        'blog' => 'help',
    );
    my ( $out, $err, $exit ) = capture { Statocles::Command->main( @args ) };
    ok !$err, 'blog help is on stdout';
    is $exit, 0;
    like $out, qr{\Qblog post [--date YYYY-MM-DD] <title> -- Create a new blog post},
        'contains blog help information';
};

subtest 'run the http daemon' => sub {
    $tmp->child( 'build_site' )->remove_tree; # We want daemon to rebuild the site
    $tmp->child( 'build_site' )->mkpath;

    # We need to stop the daemon after it starts
    my ( $port, $app );
    my $timeout = Mojo::IOLoop->singleton->timer( 0, sub {
        my $daemon = $Statocles::Command::daemon;
        my $id = $daemon->acceptors->[0];
        $port = $daemon->ioloop->acceptor( $id )->handle->sockport;
        $app = $daemon->app;
        $daemon->stop;
        Mojo::IOLoop->stop;
    } );

    # We want it to pick a random port
    local $ENV{MOJO_LISTEN} = 'http://127.0.0.1';
    local $ENV{MOJO_LOG_LEVEL} = 'info'; # But sometimes this isn't set?

    my @args = (
        '--config' => "$config_fn",
        'daemon',
    );

    my ( $out, $err, $exit ) = capture { Statocles::Command->main( @args ) };
    undef $timeout;

    my $store_path = $app->site->app( 'blog' )->store->path;
    my $theme_path = $app->site->app( 'blog' )->theme->store->path;

    if ( eval { require Mac::FSEvents; 1; } ) {
        like $err, qr{Watching for changes in '$store_path'}, 'watch is reported';
        like $err, qr{Watching for changes in '$theme_path'}, 'watch is reported';
    }
    else {
        ok !$err, 'nothing on stderr' or diag $err;
    }

    is $exit, 0;
    like $out, qr{\QListening on http://127.0.0.1:$port\E\n},
        'contains http port information';

    isa_ok $app, 'Statocles::Command::_MOJOAPP';

    ok $tmp->child( 'build_site', 'index.html' )->exists, 'site was built';

    subtest 'Mojolicious app' => sub {
        subtest 'root site' => sub {

            my $t = Test::Mojo->new(
                Statocles::Command::_MOJOAPP->new(
                    site => Beam::Wire->new( file => "$config_fn" )->get( 'site' ),
                ),
            );

            # Check that / gets index.html
            $t->get_ok( "/" )
                ->status_is( 200 )
                ->content_is( $tmp->child( build_site => 'index.html' )->slurp_utf8 )
                ->content_type_is( 'text/html;charset=UTF-8' )
                ;

            # Check that /index.html gets the right content
            $t->get_ok( "/index.html" )
                ->status_is( 200 )
                ->content_is( $tmp->child( build_site => 'index.html' )->slurp_utf8 )
                ->content_type_is( 'text/html;charset=UTF-8' )
                ;

            # Check that malicious URL gets plonked
            $t->get_ok( '/../../../../../etc/passwd' )
                ->status_is( 400 )
                ->or( sub { diag $t->tx->res->body } )
                ;

            # Check that missing URL gets 404'd
            $t->get_ok( "/MISSING_FILE_THAT_SHOULD_ERROR.html" )
                ->status_is( 404 )
                ->or( sub { diag $t->tx->res->body } )
                ;

            $t->get_ok( "/missing" )
                ->status_is( 404 )
                ->or( sub { diag $t->tx->res->body } )
                ;

            if ( eval { require Mac::FSEvents; 1; } ) {
                subtest 'watch for filesystem events' => sub {

                    subtest 'content store' => sub {
                        my $path = Path::Tiny->new( qw( 2014 06 02 more_tags.yml ) );
                        my $store = $t->app->site->app( 'blog' )->store;
                        my $doc = $store->read_document( $path );
                        $doc->{content} = "This is some new content for our blog!";
                        $store->write_document( $path, $doc );

                        my $ioloop = Mojo::IOLoop->singleton;
                        # It sucks that we have to wait like this...
                        my $wait = $ioloop->timer( 2, sub {
                            # Must stop before running the test because the test will
                            # start the loop again
                            Mojo::IOLoop->stop;

                            # Check that /index.html gets the right content
                            $t->get_ok( "/index.html" )
                                ->status_is( 200 )
                                ->content_is( $tmp->child( build_site => 'index.html' )->slurp_utf8 )
                                ->content_like( qr{This is some new content for our blog!} )
                                ->content_type_is( 'text/html;charset=UTF-8' )
                                ;

                        } );

                        Mojo::IOLoop->start;
                    };

                    subtest 'theme store' => sub {
                        my $path = Path::Tiny->new( qw( site layout.html.ep ) );
                        my $store = $t->app->site->app( 'blog' )->theme->store;
                        my $tmpl = $store->read_file( $path );
                        $tmpl =~ s{\Q</body>}{<p>Extra footer!</p></body>};
                        $store->write_file( $path, $tmpl );

                        my $ioloop = Mojo::IOLoop->singleton;
                        # It sucks that we have to wait like this...
                        my $wait = $ioloop->timer( 2, sub {
                            # Must stop before running the test because the test will
                            # start the loop again
                            Mojo::IOLoop->stop;

                            # Check that /index.html gets the right content
                            $t->get_ok( "/index.html" )
                                ->status_is( 200 )
                                ->content_is( $tmp->child( build_site => 'index.html' )->slurp_utf8 )
                                ->content_like( qr{<p>Extra footer!</p>} )
                                ->content_type_is( 'text/html;charset=UTF-8' )
                                ;

                        } );

                        Mojo::IOLoop->start;
                    };

                };
            }
        };

        subtest 'nonroot site' => sub {
            local $config->{site}{args}{base_url} = 'http://example.com/nonroot';
            my $config_fn = $tmp->child( 'site_nonroot.yml' );
            YAML::DumpFile( $config_fn, $config );

            my $t = Test::Mojo->new(
                Statocles::Command::_MOJOAPP->new(
                    site => Beam::Wire->new( file => "$config_fn" )->get( 'site' ),
                ),
            );

            # Check that / redirects
            $t->get_ok( "/" )
                ->status_is( 302 )
                ->header_is( Location => '/nonroot' )
                ->or( sub { diag $t->tx->res->body } )
                ;

            # Check that /nonroot gets index.html
            $t->get_ok( "/nonroot" )
                ->status_is( 200 )
                ->content_is( $tmp->child( build_site => 'index.html' )->slurp_utf8 )
                ->content_type_is( 'text/html;charset=UTF-8' )
                ;

            # Check that /nonroot/index.html gets the right content
            $t->get_ok( "/nonroot/index.html" )
                ->status_is( 200 )
                ->content_is( $tmp->child( build_site => 'index.html' )->slurp_utf8 )
                ->content_type_is( 'text/html;charset=UTF-8' )
                ;

            # Check that malicious URL gets plonked
            $t->get_ok( '/nonroot/../../../../../etc/passwd' )
                ->status_is( 400 )
                ->or( sub { diag $t->tx->res->body } )
                ;

            # Check that missing URL gets 404'd
            $t->get_ok( "/nonroot/MISSING_FILE_THAT_SHOULD_ERROR.html" )
                ->status_is( 404 )
                ->or( sub { diag $t->tx->res->body } )
                ;

            $t->get_ok( "/missing" )
                ->status_is( 404 )
                ->or( sub { diag $t->tx->res->body } )
                ;

        };
    };
};

subtest 'bundle the necessary components' => sub {
    subtest 'theme' => sub {
        my @args = (
            '--config' => "$config_fn",
            bundle => theme => 'default',
        );
        my @site_layout = qw( share theme default site layout.html.ep );
        my @site_footer = qw( share theme default site footer.html );
        subtest 'first time creates directories' => sub {
            my ( $out, $err, $exit ) = capture { Statocles::Command->main( @args ) };
            #; diag `find $tmp`;
            is $exit, 0;
            ok !$err;
            like $out, qr{Theme "default" written to "share/theme/default"};
            like $out, qr{Make sure to update "$config_fn"};
            is $tmp->child( @site_layout )->slurp_utf8,
                $SHARE_DIR->parent->parent->child( @site_layout )->slurp_utf8;
            ok $tmp->child( @site_footer )->is_file;
        };
        subtest 'second time does not overwrite hooks' => sub {
            # Write new hooks
            $tmp->child( @site_footer )->spew( 'SITE FOOTER' );
            # Templates will get overwritten no matter what
            $tmp->child( @site_layout )->spew( 'TEMPLATE DAMAGED' );

            my ( $out, $err, $exit ) = capture { Statocles::Command->main( @args ) };
            is $exit, 0;
            ok !$err;
            like $out, qr{Theme "default" written to "share/theme/default"};
            like $out, qr{Make sure to update "$config_fn"};

            is $tmp->child( @site_layout )->slurp_utf8,
                $SHARE_DIR->parent->parent->child( @site_layout )->slurp_utf8;
            is $tmp->child( @site_footer )->slurp_utf8, 'SITE FOOTER';
        };
    };
};

done_testing;
