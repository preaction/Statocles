
use Statocles::Base 'Test';
use Statocles::App::Basic;

my $SHARE_DIR = path( __DIR__ )->parent->parent->child( 'share' );
my $site = build_test_site(
    theme => $SHARE_DIR->child( 'theme' ),
);

my $app = Statocles::App::Basic->new(
    url_root => '/',
    site => $site,
    store => $SHARE_DIR->child( qw( app basic ) ),
    data => {
        info => "This is some info",
    },
);

test_pages(
    $site, $app,
    '/index.html' => sub {
        my ( $html, $dom ) = @_;
        # XXX: Find the layout and template
        my $node;

        if ( ok $node = $dom->at( 'h1' ) ) {
            is $node->text, 'Index Page';
        }

        if ( ok $node = $dom->at( 'body ul li:first-child a' ) ) {
            is $node->text, 'Foo Index';
            is $node->attr( 'href' ), '/foo/index.html';
        }

        if ( ok $node = $dom->at( 'footer #app-info' ) ) {
            is $node->text, $app->data->{info}, 'app-info is correct';
        }

    },

    '/aaa.html' => sub {
        my ( $html, $dom ) = @_;
        like $dom->at( 'p' )->text, qr{^\QThis page's purpose is to come first in the list};
    },

    '/foo/index.html' => sub {
        my ( $html, $dom ) = @_;
        # XXX: Find the layout and template
        my $node;

        if ( ok $node = $dom->at( 'h1' ) ) {
            is $node->text, 'Foo Index';
        }

        if ( ok $node = $dom->at( 'body ul li:first-child a' ) ) {
            is $node->text, 'Index';
            is $node->attr( 'href' ), '/index.html';
        }

        if ( ok $node = $dom->at( 'footer #app-info' ) ) {
            is $node->text, $app->data->{info}, 'app-info is correct';
        }
    },

    '/foo/other.html' => sub {
        my ( $html, $dom ) = @_;
        # XXX: Find the layout and template
        my $node;

        if ( ok $node = $dom->at( 'h1' ) ) {
            is $node->text, 'Foo Other';
        }

        if ( ok $node = $dom->at( 'body ul li:first-child a' ) ) {
            is $node->text, 'Index';
            is $node->attr( 'href' ), '/index.html';
        }

        if ( ok $node = $dom->at( 'footer #app-info' ) ) {
            is $node->text, $app->data->{info}, 'app-info is correct';
        }
    },

    '/foo/utf8.html' => sub {
        my ( $html, $dom ) = @_;
        # XXX: Find the layout and template
        my $node;

        if ( ok $node = $dom->at( 'h1' ) ) {
            is $node->text, "\x{2665} Snowman!";
        }

        if ( ok $node = $dom->at( 'h1 + p' ) ) {
            is $node->text, "\x{2603}"
        }

        if ( ok $node = $dom->at( 'footer #app-info' ) ) {
            is $node->text, $app->data->{info}, 'app-info is correct';
        }
    },
);

done_testing;
