
use Test::Lib;
use My::Test;
use Statocles::App::Basic;

my $SHARE_DIR = path( __DIR__ )->parent->parent->child( 'share' );
my $site = build_test_site(
    theme => $SHARE_DIR->child( 'theme' ),
);

my %pages = (
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
            is $node->text, 'This is some info', 'app-info is correct';
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
            is $node->text, 'This is some info', 'app-info is correct';
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
            is $node->text, 'This is some info', 'app-info is correct';
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
            is $node->text, 'This is some info', 'app-info is correct';
        }
    },

    '/static.txt' => sub {
        my ( $text ) = @_;
        eq_or_diff $text, $SHARE_DIR->child( qw( app basic static.txt ) )->slurp_utf8;
    },
);

my $app = Statocles::App::Basic->new(
    url_root => '/',
    site => $site,
    store => $SHARE_DIR->child( qw( app basic ) ),
    data => {
        info => "This is some info",
    },
);

test_pages( $site, $app, %pages );

subtest 'non-root app' => sub {
    my $app = Statocles::App::Basic->new(
        url_root => '/nonroot',
        site => $site,
        store => $SHARE_DIR->child( qw( app basic ) ),
        data => {
            info => "This is some info",
        },
    );

    test_pages(
        $site, $app, { noindex => 1 },

        ( map {; "/nonroot$_" => $pages{ $_ } } keys %pages ),
    );
};

done_testing;
