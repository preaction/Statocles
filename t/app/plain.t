
use Statocles::Test;
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
    my %required = (
        url_root => '/',
        theme => $SHARE_DIR->child( 'theme' ),
        store => $SHARE_DIR->child( 'plain' ),
    );

    isa_ok +Statocles::App::Plain->new( %required ), 'Statocles::App';

    subtest 'constructor errors' => sub {

        subtest 'required attributes' => sub {
            for my $key ( keys %required ) {
                dies_ok {
                    Statocles::App::Plain->new(
                        map {; $_ => $required{ $_ } } grep { $_ ne $key } keys %required,
                    );
                } $key . ' is required';
            }
        };

    };
};

subtest 'perldoc pages' => sub {

    my %page_tests = (
        '/index.html' => sub {
            my ( $dom ) = @_;
            return sub {
                # XXX: Find the layout and template
                my $node;

                if ( ok $node = $dom->at( 'h1' ) ) {
                    is $node->text, 'Index Page';
                }

                if ( ok $node = $dom->at( 'body ul li:first-child a' ) ) {
                    is $node->text, 'Foo Index';
                    is $node->attr( 'href' ), '/foo/index.html';
                }
            };
        },

        '/foo/index.html' => sub {
            my ( $dom ) = @_;
            return sub {
                # XXX: Find the layout and template
                my $node;

                if ( ok $node = $dom->at( 'h1' ) ) {
                    is $node->text, 'Foo Index';
                }

                if ( ok $node = $dom->at( 'body ul li:first-child a' ) ) {
                    is $node->text, 'Index';
                    is $node->attr( 'href' ), '/index.html';
                }

            };
        },

        '/foo/other.html' => sub {
            my ( $dom ) = @_;
            return sub {
                # XXX: Find the layout and template
                my $node;

                if ( ok $node = $dom->at( 'h1' ) ) {
                    is $node->text, 'Foo Other';
                }

                if ( ok $node = $dom->at( 'body ul li:first-child a' ) ) {
                    is $node->text, 'Index';
                    is $node->attr( 'href' ), '/index.html';
                }

            };
        },
    );

    my $test_pages = sub {
        my ( $app ) = @_;

        my @pages = $app->pages;
        is scalar @pages, scalar keys %page_tests, 'correct number of pages';
        for my $page ( @pages ) {
            isa_ok $page, 'Statocles::Page::Document';

            if ( !$page_tests{ $page->path } ) {
                fail "No tests found for page: " . $page->path;
                next;
            }

            my $output = $page->render( site => $site );
            if ( $page->path =~ /[.]html$/ ) {
                my $dom = Mojo::DOM->new( $output );
                fail "Could not parse dom" unless $dom;
                subtest 'html content: ' . $page->path, $page_tests{ $page->path }->( $dom );
            }
            elsif ( $page->path =~ /[.]txt$/ ) {
                subtest 'text content: ' . $page->path, $page_tests{ $page->path }->( $output );
            }
            else {
                fail "Unknown page: " . $page->path;
            }

        }
    };

    subtest 'plain app pages' => sub {
        my $app = Statocles::App::Plain->new(
            url_root => '/',
            theme => $SHARE_DIR->child( 'theme' ),
            store => $SHARE_DIR->child( 'plain' ),
        );

        $test_pages->( $app );
    };

};

done_testing;
