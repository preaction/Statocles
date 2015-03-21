
use Statocles::Base 'Test';
use Capture::Tiny qw( capture );
use Statocles::Site;
use Statocles::App::Static;
use Statocles::App::Plain;
use Mojo::DOM;
my $SHARE_DIR = path( __DIR__, '..', 'share' );

subtest 'build two pages with same path' => sub {
    local $ENV{MOJO_LOG_LEVEL} = "warn";

    my $plain = Statocles::App::Plain->new(
        store => $SHARE_DIR->child( qw( app plain ) ),
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
            plain => $plain,
        },
    );

    my ( $out, $err, $exit ) = capture {
        $site->build;
    };
    like $err, qr{\Q[warn] Duplicate page "/index.html" from apps: plain, static. Using plain};
    ok !$out or diag $out;

    my $dom = Mojo::DOM->new( $build_dir->child( 'index.html' )->slurp_utf8 );

    # This test will only fail randomly if it fails, because of hash ordering
    is $dom->at('h1')->text, 'Index Page', q{plain app always wins because it's generated};
};

done_testing;
