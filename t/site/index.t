
use Test::Lib;
use My::Test;
use Statocles::App::Blog;
use Statocles::App::Basic;
use Mojo::DOM;
my $SHARE_DIR = path( __DIR__, '..', 'share' );

sub test_site {
    my ( $site, $build_dir, $deploy_dir ) = @_;

    my @pages = $site->pages;

    my ( $index_page ) = grep { $_->path eq '/index.html' } @pages;
    ok $index_page, 'site index renames app page';
    ok !scalar( grep { $_->path eq '/blog/index.html' } @pages ),
        'site index renames app page';

    subtest 'links on index page are correct' => sub {
        my $dom = $index_page->dom;
        ok $dom->at( '[href=/blog/2014/06/02/more_tags/docs.html]' ), 'relative link is fixed'
            or diag explain [ $dom->find( '[href]' )->map( attr => 'href' )->each ];
    };

    subtest 'links to index page are correct' => sub {
        my ( $nonindex_page ) = grep { $_->path eq '/blog/page/2/index.html' } @pages;
        my $dom = $nonindex_page->dom;
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

    my @pages = $site->pages;

    my ( $index_page ) = grep { $_->path eq '/index.html' } @pages;
    ok $index_page, 'site index renames app page';
    ok !scalar( grep { $_->path eq '/page/foo/other.html' } @pages ),
        'site index renames app page';

    subtest 'links on index page are correct' => sub {
        my $dom = $index_page->dom;
        ok $dom->at( '[href=/mysite/page/foo/index.html]' ), 'relative link is fixed'
            or diag explain [ $dom->find( '[href]' )->map( attr => 'href' )->each ];
        ok $dom->at( '[href=http://google.com]' ), 'full url is not touched'
            or diag explain [ $dom->find( '[href]' )->map( attr => 'href' )->each ];
        ok $dom->at( '[href="#another-part"]' ), 'anchor url is not touched'
            or diag explain [ $dom->find( '[href]' )->map( attr => 'href' )->each ];
    };

    subtest 'links to index page are correct' => sub {
        my ( $nonindex_page ) = grep { $_->path eq '/page/foo/index.html' } @pages;
        my $dom = $nonindex_page->dom;
        ok !$dom->at( '[href=/mysite/page/foo/other.html]' ), 'no link to /page/foo/other.html';
        my $link = $dom->find( 'a[href]' )->grep( text => 'Foo Other' )->first;
        is $link->attr( 'href' ), '/mysite/', 'link to index';
    };
};

subtest 'allow document path in index' => sub {
    my $basic = Statocles::App::Basic->new(
        url_root => '/page',
        store => $SHARE_DIR->child( qw( app basic ) ),
    );

    my ( $site, $build_dir, $deploy_dir ) = build_test_site_apps(
        $SHARE_DIR,
        index => '/page/foo/other.markdown',
        apps => {
            basic => $basic,
        },
    );

    my @pages = $site->pages;

    my ( $index_page ) = grep { $_->path eq '/index.html' } @pages;
    ok $index_page, 'site index renames app page';
    ok !scalar( grep { $_->path eq '/page/foo/other.html' } @pages ),
        'site index renames app page';

    subtest 'content on index is correct' => sub {
        my $dom = $index_page->dom;
        is $dom->at( 'h1' )->text, 'Foo Other', 'index content is from correct page';
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
            )->pages;
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
            )->pages;
        } qr{\QERROR: Index path "/DOES_NOT_EXIST.html" does not exist. Do you need to create "/DOES_NOT_EXIST.markdown"?},
        'error message is correct';
    };

};

done_testing;
