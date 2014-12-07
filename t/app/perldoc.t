
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
            weave => 0,
            weave_config => Path::Tiny->new( './weaver.ini' ),
        );

        my $app = Statocles::App::Perldoc->new( %required );
        for my $key ( keys %defaults ) {
            cmp_deeply $app->$key, $defaults{ $key }, "$key default value";
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

        subtest 'weave_config' => sub {
            subtest 'string' => sub {
                my $app;
                lives_ok {
                    $app = Statocles::App::Perldoc->new(
                        %required,
                        weave_config => 'foo',
                    );
                };

                isa_ok $app->weave_config, 'Path::Tiny';
                is $app->weave_config->stringify, 'foo';
            };
        };

    };
};

subtest 'perldoc pages' => sub {

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
                    like $node->text, qr{my \$int = My::Internal->new};
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

    my $test_pages = sub {
        my ( $app ) = @_;

        my @pages = $app->pages;
        is scalar @pages, 2, 'correct number of pages';
        for my $page ( @pages ) {
            isa_ok $page, 'Statocles::Page::Plain';
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

    subtest 'without Pod::Weaver' => sub {
        my $app = Statocles::App::Perldoc->new(
            url_root => '/pod',
            inc => [ $SHARE_DIR->child( 'lib' ) ],
            modules => [qw( My My:: )],
            index_module => 'My',
            theme => $SHARE_DIR->child( 'theme' ),
        );

        $test_pages->( $app );
    };

    subtest 'with Pod::Weaver' => sub {

        # Set a flag so that we don't get a lot of unkillable "subroutine redefined"
        # warnings. By localizing %INC below, we potentially hide a bunch of modules
        # that we load when the previous %INC gets restored. Then, when we load those
        # modules, we get a bunch of "subroutine redefined" warnings.
        my $skip_success = 0;
        if ( !eval { require Pod::Weaver; 1 } ) {
            pass "No successful tests without Pod::Weaver";
            $skip_success = 1;
        }

        subtest 'missing Pod::Weaver throws error' => sub {
            # Die when we try to load Pod::Weaver
            local @INC = ( sub {
                my ( undef, $file ) = @_;
                if ( $file =~ /Weaver[.]pm$/ ) {
                    die "Can't find Pod/Weaver.pm";
                }
            }, @INC );
            local %INC = %INC;
            delete $INC{ "Pod/Weaver.pm" };

            my $app = Statocles::App::Perldoc->new(
                url_root => '/pod',
                inc => [ $SHARE_DIR->child( 'lib-weaver' ) ],
                modules => [qw( My My:: )],
                index_module => 'My',
                theme => $SHARE_DIR->child( 'theme' ),
                weave => 1,
                weave_config => $SHARE_DIR->child( 'weaver.ini' ),
            );
            dies_ok { $app->pages };
        };

        return if $skip_success;

        my $app = Statocles::App::Perldoc->new(
            url_root => '/pod',
            inc => [ $SHARE_DIR->child( 'lib-weaver' ) ],
            modules => [qw( My My:: )],
            index_module => 'My',
            theme => $SHARE_DIR->child( 'theme' ),
            weave => 1,
            weave_config => $SHARE_DIR->child( 'weaver.ini' ),
        );

        $test_pages->( $app );
    };
};

done_testing;
