
use Statocles::Base 'Test';
use Statocles::Site;
use Statocles::App::Plain;
use Mojo::DOM;

my $SHARE_DIR = path( __DIR__ )->parent->child( 'share' );
my $site = Statocles::Site->new(
    title => 'Test site',
    build_store => '.',
    deploy_store => '.',
);

subtest 'constructor' => sub {

    test_constructor(
        "Statocles::App::Plain",
        required => {
            url_root => '/',
            theme => $SHARE_DIR->child( 'theme' ),
            store => $SHARE_DIR->child( qw( app plain ) ),
        },
    );

};

subtest 'pages' => sub {

    my $app = Statocles::App::Plain->new(
        url_root => '/',
        theme => $SHARE_DIR->child( 'theme' ),
        store => $SHARE_DIR->child( qw( app plain ) ),
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

        },
    );
};

done_testing;
