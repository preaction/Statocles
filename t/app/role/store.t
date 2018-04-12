
use Test::Lib;
use My::Test;
use TestStore;
my $SHARE_DIR = path( __DIR__ )->parent->parent->child( 'share' );

{
    package MyApp;
    use Statocles::Base 'Class';
    with 'Statocles::Role::App::Store';
    around pages => sub {
        my ( $orig, $self, %options ) = @_;
        my @pages = $self->$orig( %options );

        push @pages, Statocles::Page::Plain->new(
            path => '/added.html',
            content => '<p>Hello</p>',
        );

        return @pages;
    };
}

my $site = build_test_site(
    theme => $SHARE_DIR->child( 'theme' ),
);

my $store = TestStore->new(
    path => $SHARE_DIR,
    objects => [
        Statocles::Document->new(
            path => 'index.markdown',
        ),
        Statocles::Document->new(
            path => 'foo/index.markdown',
        ),
        Statocles::File->new(
            path => 'static.txt',
        ),
    ],
);

my $app = MyApp->new(
    url_root => '/my',
    site => $site,
    store => $store,
    data => {
        info => "This is some info",
    },
);

my %tests = (
    '/added.html', sub {
        my ( $page ) = @_;
        isa_ok $page, 'Statocles::Page::Plain';
    },

    '/my/index.html', sub {
        my ( $page ) = @_;
        isa_ok $page, 'Statocles::Page::Document';
        is $page->document->path, 'index.markdown',
            'document path correct';
        is $page->layout->path.'', 'layout/default.html.ep', 'layout is correct';
        is $page->app, $app, 'app is correct';
    },
    '/my/foo/index.html' => sub {
        my ( $page ) = @_;
        isa_ok $page, 'Statocles::Page::Document';
        is $page->document->path, 'foo/index.markdown',
            'document path correct';
        is $page->layout->path.'', 'layout/default.html.ep', 'layout is correct';
        is $page->app, $app, 'app is correct';
    },
    '/my/static.txt' => sub {
        my ( $page ) = @_;
        isa_ok $page, 'Statocles::Page::File';
        is $page->app, $app, 'app is correct';
    },
);

test_page_objects( [ $app->pages ], %tests );

done_testing;
