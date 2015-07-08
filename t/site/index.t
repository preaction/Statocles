
use Statocles::Base 'Test';
use Statocles::App::Static;
use Mojo::DOM;
my $SHARE_DIR = path( __DIR__, '..', 'share' );

sub test_site {
    my ( $site, $build_dir, $deploy_dir ) = @_;

    subtest 'build' => sub {
        $site->build;

        ok $build_dir->child( 'index.html' )->exists,
            'site index renames app page';
        ok !$deploy_dir->child( 'index.html' )->exists, 'not deployed yet';
        ok !$build_dir->child( 'blog', 'index.html' )->exists,
            'site index renames app page';

        my $dom = Mojo::DOM->new( $build_dir->child( '/blog/page/2/index.html' )->slurp_utf8 );
        ok !$dom->at( '[href=/blog]' ), 'no link to /blog';
        ok !$dom->at( '[href=/blog/index.html]' ), 'no link to /blog/index.html';
    };

    subtest 'deploy' => sub {
        $site->deploy;
        ok $deploy_dir->child( 'index.html' )->exists,
            'site index renames app page';
        ok !$deploy_dir->child( 'blog', 'index.html' )->exists,
            'site index renames app page';

        my $dom = Mojo::DOM->new( $deploy_dir->child( '/blog/page/2/index.html' )->slurp_utf8 );
        ok !$dom->at( '[href=/blog]' ), 'no link to /blog';
        ok !$dom->at( '[href=/blog/index.html]' ), 'no link to /blog/index.html';
    };
}

subtest 'full index path' => \&test_site, build_test_site_apps(
    $SHARE_DIR,
    index => '/blog/index.html',
);

subtest 'index.html is optional' => \&test_site, build_test_site_apps(
    $SHARE_DIR,
    index => '/blog',
);

subtest 'error messages' => sub {

    subtest 'index does not exist' => sub {
        throws_ok {
            Statocles::Site->new(
                title => 'Example Site',
                build_store => tempdir,
                deploy => tempdir,
                index => '/DOES_NOT_EXIST',
            )->build;
        } qr{ERROR: Index path "/DOES_NOT_EXIST" does not exist};
    };

};

subtest 'deprecated - index app' => sub {

    subtest 'deprecation message' => sub {
        my $log_str;
        open my $log_fh, '>', \$log_str;
        my $log = Mojo::Log->new( level => 'warn', handle => $log_fh );

        my ( $site, $build_dir, $deploy_dir ) = build_test_site_apps(
            $SHARE_DIR,
            index => 'blog',
            log => $log,
        );

        subtest 'build' => sub {
            $site->build;

            ok $build_dir->child( 'index.html' )->exists,
                'site index renames app page';
            ok !$deploy_dir->child( 'index.html' )->exists, 'not deployed yet';
            ok !$build_dir->child( 'blog', 'index.html' )->exists,
                'site index renames app page';

            my $dom = Mojo::DOM->new( $build_dir->child( '/blog/page/2/index.html' )->slurp_utf8 );
            ok !$dom->at( '[href=/blog]' ), 'no link to /blog';
            ok !$dom->at( '[href=/blog/index.html]' ), 'no link to /blog/index.html';
        };

        like $log_str, qr{\Q[warn] site "index" property should be absolute path to index page (got "blog")};
    };

    subtest 'error messages' => sub {

        subtest 'index_app does not give any pages' => sub {
            my $log_str;
            open my $log_fh, '>', \$log_str;
            my $log = Mojo::Log->new( level => 'warn', handle => $log_fh );

            # Empty Static app
            my $tmpdir = tempdir;
            my $static = Statocles::App::Static->new(
                store => $tmpdir,
                url_root => '/static',
            );

            my ( $site ) = build_test_site_apps(
                $SHARE_DIR,
                apps => {
                    static => $static,
                },
                index => 'static',
                log => $log,
            );

            throws_ok { $site->build } qr{ERROR: Index app "static" did not generate any pages};
        };

    };

};

done_testing;
