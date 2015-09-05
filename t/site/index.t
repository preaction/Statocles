
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

done_testing;
