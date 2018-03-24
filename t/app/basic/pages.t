
use Test::Lib;
use My::Test;
use Statocles::App::Basic;
use TestStore;

my $SHARE_DIR = path( __DIR__ )->parent->parent->child( 'share' );
my $site = build_test_site(
    theme => $SHARE_DIR->child( 'theme' ),
);

my $app;

my %tests = (
    '/index.html', sub {
        my ( $page ) = @_;
        isa_ok $page, 'Statocles::Page::Document';
        is $page->document->path, 'index.markdown',
            'document path correct';
        is $page->layout->path.'', 'layout/default.html.ep', 'layout is correct';
        is $page->app, $app, 'app is correct';
    },
    '/aaa.html' => sub {
        my ( $page ) = @_;
        isa_ok $page, 'Statocles::Page::Document';
        is $page->document->path, 'aaa.markdown',
            'document path correct';
        is $page->layout->path.'', 'layout/default.html.ep', 'layout is correct';
        is $page->app, $app, 'app is correct';
    },
    '/foo/index.html' => sub {
        my ( $page ) = @_;
        isa_ok $page, 'Statocles::Page::Document';
        is $page->document->path, 'foo/index.markdown',
            'document path correct';
        is $page->layout->path.'', 'layout/default.html.ep', 'layout is correct';
        is $page->app, $app, 'app is correct';
    },
    '/foo/other.html' => sub {
        my ( $page ) = @_;
        isa_ok $page, 'Statocles::Page::Document';
        is $page->document->path, 'foo/other.markdown',
            'document path correct';
        is $page->layout->path.'', 'layout/default.html.ep', 'layout is correct';
        is $page->app, $app, 'app is correct';
    },
    '/static.txt' => sub {
        my ( $page ) = @_;
        isa_ok $page, 'Statocles::Page::File';
        is $page->app, $app, 'app is correct';
    },
);

my $store = TestStore->new(
    path => $SHARE_DIR,
    objects => [
        Statocles::Document->new(
            path => 'index.markdown',
        ),
        Statocles::Document->new(
            path => 'aaa.markdown',
        ),
        Statocles::Document->new(
            path => 'foo/index.markdown',
        ),
        Statocles::Document->new(
            path => 'foo/other.markdown',
        ),
        Statocles::File->new(
            path => 'static.txt',
        ),
    ],
);

$app = Statocles::App::Basic->new(
    url_root => '/',
    site => $site,
    store => $store,
    data => {
        info => "This is some info",
    },
);
my @pages = $app->pages;
test_page_objects( \@pages, %tests );

subtest 'non-root app' => sub {
    $app = Statocles::App::Basic->new(
        url_root => '/nonroot',
        site => $site,
        store => $store,
        data => {
            info => "This is some info",
        },
    );
    my @pages = $app->pages;
    test_page_objects( \@pages, map { '/nonroot' . $_ => $tests{ $_ } } keys %tests );
};

done_testing;
