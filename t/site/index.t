
use Test::Lib;
use My::Test;
use Statocles::App::Blog;
use Statocles::App::Basic;
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

        subtest 'links on index page are correct' => sub {
            my $dom = Mojo::DOM->new( $build_dir->child( '/index.html' )->slurp_utf8 );
            ok $dom->at( '[href=/blog/2014/06/02/more_tags/docs.html]' ), 'relative link is fixed'
                or diag explain [ $dom->find( '[href]' )->map( attr => 'href' )->each ];
        };

        subtest 'links to index page are correct' => sub {
            my $dom = Mojo::DOM->new( $build_dir->child( '/blog/page/2/index.html' )->slurp_utf8 );
            ok !$dom->at( '[href=/blog]' ), 'no link to /blog';
            ok !$dom->at( '[href=/blog/index.html]' ), 'no link to /blog/index.html';
        };

    };

    subtest 'deploy' => sub {
        $site->deploy;
        ok $deploy_dir->child( 'index.html' )->exists,
            'site index renames app page';
        ok !$deploy_dir->child( 'blog', 'index.html' )->exists,
            'site index renames app page';

        subtest 'links on index page are correct' => sub {
            my $dom = Mojo::DOM->new( $build_dir->child( '/index.html' )->slurp_utf8 );
            ok $dom->at( '[href=/blog/2014/06/02/more_tags/docs.html]' ), 'relative link is fixed'
                or diag explain [ $dom->find( '[href]' )->map( attr => 'href' )->each ];
        };

        subtest 'inner pages link to site index' => sub {
            my $dom = Mojo::DOM->new( $deploy_dir->child( '/blog/page/2/index.html' )->slurp_utf8 );
            ok !$dom->at( '[href=/blog]' ), 'no link to /blog';
            ok !$dom->at( '[href=/blog/index.html]' ), 'no link to /blog/index.html';
        };

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

subtest 'index links in basic app' => sub {
    my $basic = Statocles::App::Basic->new(
        url_root => '/page',
        store => $SHARE_DIR->child( qw( app basic ) ),
    );

    my ( $site, $build_dir, $deploy_dir ) = build_test_site_apps(
        $SHARE_DIR,
        base_url => 'http://example.com/mysite',
        index => '/page/foo/other.html',
        apps => {
            basic => $basic,
        },
    );

    $site->build;

    ok $build_dir->child( 'index.html' )->exists,
        'site index renames app page';
    ok !$build_dir->child( 'page', 'foo', 'other.html' )->exists,
        'site index renames app page';

    subtest 'links on index page are correct' => sub {
        my $dom = Mojo::DOM->new( $build_dir->child( '/index.html' )->slurp_utf8 );
        ok $dom->at( '[href=/mysite/page/foo/index.html]' ), 'relative link is fixed'
            or diag explain [ $dom->find( '[href]' )->map( attr => 'href' )->each ];
        ok $dom->at( '[href=http://google.com]' ), 'full url is not touched'
            or diag explain [ $dom->find( '[href]' )->map( attr => 'href' )->each ];
    };

    subtest 'links to index page are correct' => sub {
        my $dom = Mojo::DOM->new( $build_dir->child( '/page/foo/index.html' )->slurp_utf8 );
        ok !$dom->at( '[href=/mysite/page/foo/other.html]' ), 'no link to /page/foo/other.html';
        my $link = $dom->find( 'a[href]' )->grep( text => 'Foo Other' )->first;
        is $link->attr( 'href' ), '/mysite/', 'link to index';
    };
};

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
