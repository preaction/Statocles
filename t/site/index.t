
use Statocles::Base 'Test';
use Statocles::App::Static;
my $SHARE_DIR = path( __DIR__, '..', 'share' );

my ( $site, $build_dir, $deploy_dir ) = build_test_site_apps(
    $SHARE_DIR,
    index => 'blog',
);

my $blog = $site->app( 'blog' );
my $page = ( $blog->pages )[0];

subtest 'build' => sub {
    $site->build;
    # XXX: Test the content
    ok $build_dir->child( 'index.html' )->exists,
        'site index renames app page';
    ok !$deploy_dir->child( 'index.html' )->exists, 'not deployed yet';
    ok !$build_dir->child( 'blog', 'index.html' )->exists,
        'site index renames app page';
};

subtest 'deploy' => sub {
    $site->deploy;
    # XXX: Test the content
    ok $deploy_dir->child( 'index.html' )->exists,
        'site index renames app page';
    ok !$deploy_dir->child( 'blog', 'index.html' )->exists,
        'site index renames app page';
};

subtest 'error messages' => sub {

    subtest 'index_app does not give any pages' => sub {
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
        );

        throws_ok { $site->build } qr{ERROR: Index app "static" did not generate any pages};
    };

};

done_testing;
