
use Statocles::Test;
use Statocles::Site;
use Statocles::App::Perldoc;
use Mojo::DOM;

my $SHARE_DIR = path( __DIR__ )->parent->child( 'share' );
my $site = Statocles::Site->new(
    title => 'Test site',
    build_store => '.',
    deploy_store => '.',
);

subtest 'constructor' => sub {
    my %required = (
        url_root => '/pod',
        theme => $SHARE_DIR->child( 'theme' ),
        modules => [qw( My )],
        index_module => 'My',
    );

    isa_ok +Statocles::App::Perldoc->new( %required ), 'Statocles::App';

    subtest 'constructor errors' => sub {

        subtest 'required attributes' => sub {
            for my $key ( keys %required ) {
                dies_ok {
                    Statocles::App::Perldoc->new(
                        map {; $_ => $required{ $_ } } grep { $_ ne $key } keys %required,
                    );
                } $key . ' is required';
            }
        };

    };

    subtest 'attribute defaults' => sub {
        my %defaults = (
            inc => [ map { Path::Tiny->new( $_ ) } @INC ],
        );

        my $app = Statocles::App::Perldoc->new( %required );
        for my $key ( keys %defaults ) {
            cmp_deeply $app->$key, $defaults{ $key };
        }
    };

    subtest 'attribute types/coercions' => sub {
        subtest 'inc' => sub {

            subtest 'all strings' => sub {
                my $app;
                lives_ok {
                    $app = Statocles::App::Perldoc->new(
                        %required,
                        inc => [ 'test', 'two' ],
                    )
                };

                cmp_deeply $app->inc, array_each( isa( 'Path::Tiny' ) );
                is $app->inc->[0]->stringify, "test";
                is $app->inc->[1]->stringify, "two";
            };

            subtest 'some strings / some paths' => sub {
                my $app;
                lives_ok {
                    $app = Statocles::App::Perldoc->new(
                        %required,
                        inc => [ 'test', Path::Tiny->new( 'two' ) ],
                    )
                };

                cmp_deeply $app->inc, array_each( isa( 'Path::Tiny' ) );
                is $app->inc->[0]->stringify, "test";
                is $app->inc->[1]->stringify, "two";
            };
        };
    };
};

subtest 'perldoc pages' => sub {

    my $app = Statocles::App::Perldoc->new(
        url_root => '/pod',
        inc => [ $SHARE_DIR->child( 'lib' ) ],
        modules => [qw( My My:: )],
        index_module => 'My',
        theme => $SHARE_DIR->child( 'theme' ),
    );

    my %page_tests = (
        '/pod/index.html' => sub {
            my ( $dom ) = @_;
            return sub {
                # XXX: Find the layout and template
                my $node;
                if ( ok $node = $dom->at( 'h1#NAME' ) ) {
                    is $node->text, 'NAME';
                }
                if ( ok $node = $dom->at( 'h1#NAME + p' ) ) {
                    is $node->text, 'My - A sample for my perldoc app';
                }
                if ( ok $node = $dom->at( 'h1#SYNOPSIS + pre code' ) ) {
                    like $node->text, qr{my \$my = My->new};
                }
                ok $dom->at( 'a[href="/pod/My/Internal.html"]' ), 'internal link exists';
                ok $dom->at( 'a[href="https://metacpan.org/pod/External"]' ), 'external link exists';
            };
        },

        '/pod/My/Internal.html' => sub {
            my ( $dom ) = @_;
            return sub {
                # XXX: Find the layout and template
                my $node;
                if ( ok $node = $dom->at( 'h1#NAME' ) ) {
                    is $node->text, 'NAME';
                }
                if ( ok $node = $dom->at( 'h1#NAME + p' ) ) {
                    is $node->text, 'My::Internal - An internal module to link to';
                }
                if ( ok $node = $dom->at( 'h1#SYNOPSIS + pre code' ) ) {
                    is $node->text, qr{my \$int = My::Internal->new};
                }
                ok $dom->at( 'a[href="/pod/index.html"]' ), 'internal link to index page';
            };
        },

        '/pod/My.txt' => sub {
            my ( $text ) = @_;
            return sub {
                eq_or_diff $text, $SHARE_DIR->child( 'lib', 'My.pm' )->slurp;
            };
        },

        '/pod/My/Internal.txt' => sub {
            my ( $text ) = @_;
            return sub {
                eq_or_diff $text, $SHARE_DIR->child( 'lib', 'My', 'Internal.pm' )->slurp;
            };
        },
    );

    my @pages = $app->pages;
    is scalar @pages, 2, 'correct number of pages';
    for my $page ( @pages ) {
        isa_ok $page, 'Statocles::Page::Raw';
        like $page->path, qr{^/pod};

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

done_testing;
