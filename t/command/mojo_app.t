
use Test::Lib;
use My::Test;
use Capture::Tiny qw( capture );
use Mojo::IOLoop;
use Test::Mojo;
use Beam::Wire;
use YAML;
use Statocles::Command;
my $SHARE_DIR = path( __DIR__, '..', 'share' );

local $ENV{MOJO_LOG_LEVEL} = 'warn';

my ( $tmp, $config_fn, $config ) = build_temp_site( $SHARE_DIR );

subtest 'root site' => sub {

    my $site = Beam::Wire->new( file => "$config_fn" )->get( 'site' );

    my $t = Test::Mojo->new(
        Statocles::Command::_MOJOAPP->new(
            site => $site,
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

    # Check blog URL
    $t->get_ok( "/blog/2014/04/23/slug/index.html" )
        ->status_is( 200 )
        ->content_is( $tmp->child( build_site => qw( blog 2014 04 23 slug index.html ) )->slurp_utf8 )
        ->content_type_is( 'text/html;charset=UTF-8' )
        ;

    # Check directory redirect
    $t->get_ok( "/blog/2014/04/23/slug" )
        ->status_is( 302 )
        ->header_is( Location => '/blog/2014/04/23/slug/' )
        ;
    $t->get_ok( "/blog/2014/04/23/slug/" )
        ->status_is( 200 )
        ->content_is( $tmp->child( build_site => qw( blog 2014 04 23 slug index.html ) )->slurp_utf8 )
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
                my $path = Path::Tiny->new( qw( 2014 04 23 slug index.markdown ) );
                my $store = $t->app->site->app( 'blog' )->store;
                my $doc = $store->read_document( $path );
                $doc->{content} = "This is some new content for our blog!";
                $store->write_document( $path, $doc );

                # Non-blocking start loop and wait 2
                Mojo::IOLoop->timer( 2, sub { Mojo::IOLoop->stop } );
                Mojo::IOLoop->start;

                # Check that /index.html gets the right content
                $t->get_ok( "/index.html" )
                    ->status_is( 200 )
                    ->content_is( $tmp->child( build_site => 'index.html' )->slurp_utf8 )
                    ->content_like( qr{This is some new content for our blog!} )
                    ->content_type_is( 'text/html;charset=UTF-8' )
                    ;
            };

            subtest 'theme store' => sub {
                my $path = Path::Tiny->new( qw( site layout.html.ep ) );
                my $store = $t->app->site->theme->store;
                my $tmpl = $store->read_file( $path );
                $tmpl =~ s{\Q</body>}{<p>Extra footer!</p></body>};
                $store->write_file( $path, $tmpl );

                # Non-blocking start loop and wait 2
                Mojo::IOLoop->timer( 2, sub { Mojo::IOLoop->stop } );
                Mojo::IOLoop->start;

                # Check that /index.html gets the right content
                $t->get_ok( "/index.html" )
                    ->status_is( 200 )
                    ->content_is( $tmp->child( build_site => 'index.html' )->slurp_utf8 )
                    ->content_like( qr{<p>Extra footer!</p>} )
                    ->content_type_is( 'text/html;charset=UTF-8' )
                    ;
            };

            subtest 'build dir is ignored' => sub {
                $tmp->child( 'build_site', 'index.html' )->spew_utf8( 'Trigger!' );

                # Non-blocking start loop and wait 2
                Mojo::IOLoop->timer( 2, sub { Mojo::IOLoop->stop } );
                Mojo::IOLoop->start;

                # Check that /index.html gets the content we wrote, and was
                # not rebuilt
                $t->get_ok( "/index.html" )
                    ->status_is( 200 )
                    ->content_is( 'Trigger!' )
                    ;
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

    # Check blog URL
    $t->get_ok( "/nonroot/blog/2014/04/23/slug/index.html" )
        ->status_is( 200 )
        ->content_is( $tmp->child( build_site => qw( blog 2014 04 23 slug index.html ) )->slurp_utf8 )
        ->content_type_is( 'text/html;charset=UTF-8' )
        ;

    # Check directory redirect
    $t->get_ok( "/nonroot/blog/2014/04/23/slug" )
        ->status_is( 302 )
        ->header_is( Location => '/nonroot/blog/2014/04/23/slug/' )
        ;
    $t->get_ok( "/nonroot/blog/2014/04/23/slug/" )
        ->status_is( 200 )
        ->content_is( $tmp->child( build_site => qw( blog 2014 04 23 slug index.html ) )->slurp_utf8 )
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

subtest '--date option' => sub {
    my $site = Beam::Wire->new( file => "$config_fn" )->get( 'site' );

    my $t = Test::Mojo->new(
        Statocles::Command::_MOJOAPP->new(
            site => $site,
            options => {
                date => '9999-12-31',
            },
        ),
    );

    is $t->app->options->{ date }, '9999-12-31', 'fake test';

    if ( eval { require Mac::FSEvents; 1; } ) {
        subtest 'rebuild with date option' => sub {

            my $path = Path::Tiny->new( qw( 9999 12 31 forever-is-a-long-time index.markdown ) );
            my $store = $t->app->site->app( 'blog' )->store;
            my $doc = $store->read_document( $path );
            $doc->{content} = "This is some new content for our blog!";
            $store->write_document( $path, $doc );

            # Non-blocking start loop and wait 2
            Mojo::IOLoop->timer( 2, sub { Mojo::IOLoop->stop } );
            Mojo::IOLoop->start;

            # Check that /index.html gets the right content
            $t->get_ok( "/index.html" )
                ->status_is( 200 )
                ->content_is( $tmp->child( build_site => 'index.html' )->slurp_utf8 )
                ->content_like( qr{This is some new content for our blog!} )
                ->content_type_is( 'text/html;charset=UTF-8' )
                ;
        };
    }

};

done_testing;
