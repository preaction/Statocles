
use Test::Lib;
use My::Test;
my $SHARE_DIR = path( __DIR__ )->parent->parent->child( 'share' );

{
    package MyApp;
    use Statocles::Base 'Class';
    with 'Statocles::App::Role::Store';
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

my $app = MyApp->new(
    url_root => '/my',
    site => $site,
    store => $SHARE_DIR->child( qw( app basic ) ),
    data => {
        info => "This is some info",
    },
);

test_pages(
    $site, $app,

    '/added.html' => sub {
        my ( $html, $dom ) = @_;
        # XXX: Find the layout and template
        my $node;

        if ( ok $node = $dom->at( 'p' ) ) {
            is $node->text, 'Hello';
        }
    },

    '/my/index.html' => sub {
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

    '/my/aaa.html' => sub {
        my ( $html, $dom ) = @_;
        like $dom->at( 'p' )->text, qr{^\QThis page's purpose is to come first in the list};
    },

    '/my/foo/index.html' => sub {
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

    '/my/foo/other.html' => sub {
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

    '/my/foo/utf8.html' => sub {
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

    '/my/static.txt' => sub {
        my ( $text ) = @_;
        eq_or_diff $text, $SHARE_DIR->child( qw( app basic static.txt ) )->slurp_utf8;
    },
);


done_testing;
