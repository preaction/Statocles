
use Statocles::Base 'Test';
use Capture::Tiny qw( capture );
use Statocles::Site;
use Statocles::Page::Plain;
use Statocles::App::Static;
use Statocles::App::Basic;
use Mojo::DOM;
use Test::Lib;
use TestApp;
my $SHARE_DIR = path( __DIR__, '..', 'share' );

subtest 'build two pages with same path' => sub {
    local $ENV{MOJO_LOG_LEVEL} = "warn";

    my $basic = Statocles::App::Basic->new(
        store => $SHARE_DIR->child( qw( app basic ) ),
        url_root => '/',
    );

    my $static = Statocles::App::Static->new(
        store => $SHARE_DIR->child( qw( app static_index ) ),
        url_root => '/',
    );

    my ( $site, $build_dir, $deploy_dir ) = build_test_site_apps(
        $SHARE_DIR,
        apps => {
            static => $static,
            basic => $basic,
        },
    );

    my ( $out, $err, $exit ) = capture {
        $site->build;
    };
    like $err, qr{\Q[warn] Duplicate page "/index.html" from apps: basic, static. Using basic};
    ok !$out or diag $out;

    my $dom = Mojo::DOM->new( $build_dir->child( 'index.html' )->slurp_utf8 );

    # This test will only fail randomly if it fails, because of hash ordering
    is $dom->at('h1')->text, 'Index Page', q{basic app always wins because it's generated};
};

subtest 'app generates two pages with the same path' => sub {
    my $app = TestApp->new(
        url_root => '/',
        pages => [
            Statocles::Page::Plain->new(
                path => '/index.html',
                content => 'Index',
            ),
            Statocles::Page::Plain->new(
                path => '/foo.html',
                content => 'Foo',
            ),
            Statocles::Page::Plain->new(
                path => '/foo.html',
                content => 'Bar',
            ),
        ],
    );

    my ( $site, $build_dir, $deploy_dir ) = build_test_site_apps(
        $SHARE_DIR,
        apps => {
            test => $app,
        },
    );

    my ( $out, $err, $exit ) = capture {
        $site->build;
    };
    like $err, qr{\Q[warn] Duplicate page with path "/foo.html" from app "test"};
    ok !$out or diag $out;
};

done_testing;
