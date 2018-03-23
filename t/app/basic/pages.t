
use Test::Lib;
use My::Test;
use Statocles::App::Basic;

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

$app = Statocles::App::Basic->new(
    url_root => '/',
    site => $site,
    store => $SHARE_DIR->child( qw( app basic ) ),
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
        store => $SHARE_DIR->child( qw( app basic ) ),
        data => {
            info => "This is some info",
        },
    );
    my @pages = $app->pages;
    test_page_objects( \@pages, map { '/nonroot' . $_ => $tests{ $_ } } keys %tests );
};

done_testing;
