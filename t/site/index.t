
use Test::Lib;
use My::Test;
use Statocles::App::Blog;
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

my $blog = Statocles::App::Blog->new(
    store => $SHARE_DIR->child( qw( app blog ) ),
    url_root => '/blog',
    page_size => 2,
);

subtest 'full index path' => \&test_site, build_test_site_apps(
    $SHARE_DIR,
    index => '/blog/index.html',
    apps => {
        blog => $blog,
    },
);

subtest 'index.html is optional' => \&test_site, build_test_site_apps(
    $SHARE_DIR,
    index => '/blog',
    apps => {
        blog => $blog,
    },
);

subtest 'error messages' => sub {

    subtest 'index directory does not exist' => sub {
        throws_ok {
            Statocles::Site->new(
                title => 'Example Site',
                build_store => tempdir,
                deploy => tempdir,
                index => '/DOES_NOT_EXIST',
            )->build;
        } qr{\QERROR: Index path "/DOES_NOT_EXIST" does not exist. Do you need to create "/DOES_NOT_EXIST/index.markdown"?},
        'error message is correct';
    };

    subtest 'index file does not exist' => sub {
        throws_ok {
            Statocles::Site->new(
                title => 'Example Site',
                build_store => tempdir,
                deploy => tempdir,
                index => '/DOES_NOT_EXIST.html',
            )->build;
        } qr{\QERROR: Index path "/DOES_NOT_EXIST.html" does not exist. Do you need to create "/DOES_NOT_EXIST.markdown"?},
        'error message is correct';
    };

};

done_testing;
