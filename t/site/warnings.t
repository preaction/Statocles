
use Statocles::Base 'Test';
use Capture::Tiny qw( capture );
use Statocles::Site;
use Statocles::App::Static;
use Statocles::App::Plain;
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
    like $err, qr{\Q[warn] Duplicate page "/index.html" from apps: plain, static};

};

done_testing;
