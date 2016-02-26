
use Test::Lib;
use My::Test;
use Statocles::App::Perldoc;

my $SHARE_DIR = path( __DIR__ )->parent->parent->child( 'share' );
my $site = build_test_site(
    theme => $SHARE_DIR->child( 'theme' ),
);

my @page_tests = (
    '/pod/index.html' => sub {
        my ( $html, $dom ) = @_;
        my $node;

        if ( ok $node = $dom->at( 'title' ), 'title tag exists' ) {
            like $node->text, qr{\QMy::Internal}, 'title contains module name';
        }

        if ( ok $node = $dom->at( 'h1#NAME' ) ) {
            is $node->text, 'NAME';
        }

        if ( ok $node = $dom->at( 'h1#NAME + p' ) ) {
            is $node->text, 'My::Internal - An internal module to link to';
        }

        if ( ok $node = $dom->at( 'h1#SYNOPSIS + pre code' ) ) {
            like $node->text, qr{my \$int = My::Internal->new};
        }

        # Use <p> to match in body, not crumbtrail
        ok $dom->at( 'p a[href="/pod/My/"]' ), 'internal link';
        ok $dom->at( 'a[href="/pod/My/Internal/source.html"]' ), 'source link exists';

        my @crumbtrail = $dom->find( '.crumbtrail li' )->each;
        is scalar @crumbtrail, 2;
        is $crumbtrail[0]->at( 'a' )->text, 'My';
        is $crumbtrail[0]->at( 'a' )->attr( 'href' ), '/pod/My/';
        is $crumbtrail[1]->at( 'a' )->text, 'Internal';
        is $crumbtrail[1]->at( 'a' )->attr( 'href' ), '/pod/';

        if ( ok $node = $dom->at( 'footer #app-info' ) ) {
            is $node->text, 'This is the app info', 'app-info is correct';
        }
    },

    '/pod/My/index.html' => sub {
        my ( $html, $dom ) = @_;
        my $node;

        if ( ok $node = $dom->at( 'title' ), 'title tag exists' ) {
            like $node->text, qr{\QMy}, 'title contains module name';
        }

        if ( ok $node = $dom->at( 'h1#NAME' ) ) {
            is $node->text, 'NAME';
        }

        if ( ok $node = $dom->at( 'h1#NAME + p' ) ) {
            is $node->text, 'My - A sample for my perldoc app';
        }

        if ( ok $node = $dom->at( 'h1#SYNOPSIS + pre code' ) ) {
            like $node->text, qr{my \$my = My->new};
        }

        # Use <p> to match in body, not crumbtrail
        ok $dom->at( 'p a[href="/pod/"]' ), 'internal link to index page';
        ok !$dom->at( 'p a[href="/pod/"]' )->attr( 'rel' ), 'internal link has no rel';
        ok $dom->at( 'p a[href="https://metacpan.org/pod/External"]' ), 'external link exists';
        is $dom->at( 'p a[href="https://metacpan.org/pod/External"]' )->attr( 'rel' ), 'external', 'external link has rel=external';
        ok $dom->at( 'a[href="/pod/My/source.html"]' ), 'source link exists';
        ok !$dom->at( 'a[href="/pod/My/source.html"]' )->attr( 'rel' ), 'source link has no rel';

        ok $dom->at( 'a[href="/pod/#SYNOPSIS"]' ), 'fragment link exists'
            or diag join "\n", $dom->find( 'a' )->map( attr => 'href' )->each;

        my @crumbtrail = $dom->find( '.crumbtrail li' )->each;
        is scalar @crumbtrail, 1;
        is $crumbtrail[0]->at( 'a' )->text, 'My';
        is $crumbtrail[0]->at( 'a' )->attr( 'href' ), '/pod/My/';

        if ( ok $node = $dom->at( 'footer #app-info' ) ) {
            is $node->text, 'This is the app info', 'app-info is correct';
        }
    },

    '/pod/command/index.html' => sub {
        my ( $html, $dom ) = @_;
        my $node;

        if ( ok $node = $dom->at( 'title' ), 'title tag exists' ) {
            like $node->text, qr{\Qcommand}, 'title contains module name';
        }

        if ( ok $node = $dom->at( 'h1#NAME' ) ) {
            is $node->text, 'NAME';
        }

        if ( ok $node = $dom->at( 'h1#NAME + p' ) ) {
            is $node->text, 'command.pl - A command-line program with POD';
        }

        if ( ok $node = $dom->at( 'h1#SYNOPSIS + pre code' ) ) {
            like $node->text, qr{command[.]pl -h};
        }

        # Use <p> to match in body, not crumbtrail
        ok $dom->at( 'p a[href="/pod/command/"]' ), 'internal link to same page';
        ok $dom->at( 'a[href="/pod/command/source.html"]' ), 'source link exists';

        my @crumbtrail = $dom->find( '.crumbtrail li' )->each;
        is scalar @crumbtrail, 1;
        is $crumbtrail[0]->at( 'a' )->text, 'command';
        is $crumbtrail[0]->at( 'a' )->attr( 'href' ), '/pod/command/';

        if ( ok $node = $dom->at( 'footer #app-info' ) ) {
            is $node->text, 'This is the app info', 'app-info is correct';
        }
    },

    '/pod/shellcmd/index.html' => sub {
        my ( $html, $dom ) = @_;
        my $node;

        if ( ok $node = $dom->at( 'title' ), 'title tag exists' ) {
            like $node->text, qr{\Qshellcmd}, 'title contains module name';
        }

        if ( ok $node = $dom->at( 'h1#NAME' ) ) {
            is $node->text, 'NAME';
        }

        if ( ok $node = $dom->at( 'h1#NAME + p' ) ) {
            is $node->text, 'shellcmd - A command without an extension';
        }

        if ( ok $node = $dom->at( 'h1#SYNOPSIS + pre code' ) ) {
            like $node->text, qr{shellcmd -h};
        }

        # Use <p> to match in body, not crumbtrail
        ok $dom->at( 'p a[href="/pod/shellcmd/"]' ), 'internal link to same page';
        ok $dom->at( 'a[href="/pod/shellcmd/source.html"]' ), 'source link exists';

        my @crumbtrail = $dom->find( '.crumbtrail li' )->each;
        is scalar @crumbtrail, 1;
        is $crumbtrail[0]->at( 'a' )->text, 'shellcmd';
        is $crumbtrail[0]->at( 'a' )->attr( 'href' ), '/pod/shellcmd/';

        if ( ok $node = $dom->at( 'footer #app-info' ) ) {
            is $node->text, 'This is the app info', 'app-info is correct';
        }
    },

);

subtest 'without Pod::Weaver' => sub {
    my $app = Statocles::App::Perldoc->new(
        url_root => '/pod',
        inc => [
            $SHARE_DIR->child( qw( app perldoc lib ) ),
            $SHARE_DIR->child( qw( app perldoc bin ) ),
        ],
        modules => [qw( My My:: command shellcmd )],
        index_module => 'My::Internal',
        site => $site,
        data => {
            info => 'This is the app info',
        },
    );

    test_pages(
        $site, $app, @page_tests,

        '/pod/My/source.html' => sub {
            my ( $html, $dom ) = @_;
            my $node;

            if ( ok $node = $dom->at( 'title' ), 'title tag exists' ) {
                like $node->text, qr{\QMy (source)}, 'title contains module name and source tag';
            }

            eq_or_diff $dom->at( 'pre' )->text,
                $SHARE_DIR->child( qw( app perldoc lib My.pm ) )->slurp_utf8;
        },

        '/pod/My/Internal/source.html' => sub {
            my ( $html, $dom ) = @_;
            my $node;

            if ( ok $node = $dom->at( 'title' ), 'title tag exists' ) {
                like $node->text, qr{\QMy::Internal (source)}, 'title contains module name and source tag';
            }

            eq_or_diff $dom->at( 'pre' )->text,
                $SHARE_DIR->child( qw( app perldoc lib My Internal.pm ) )->slurp_utf8;
        },

        '/pod/command/source.html' => sub {
            my ( $html, $dom ) = @_;
            my $node;

            if ( ok $node = $dom->at( 'title' ), 'title tag exists' ) {
                like $node->text, qr{\Qcommand (source)}, 'title contains module name and source tag';
            }

            eq_or_diff $dom->at( 'pre' )->text,
                $SHARE_DIR->child( qw( app perldoc bin command.pl ) )->slurp_utf8;
        },

        '/pod/shellcmd/source.html' => sub {
            my ( $html, $dom ) = @_;
            my $node;

            if ( ok $node = $dom->at( 'title' ), 'title tag exists' ) {
                like $node->text, qr{\Qshellcmd (source)}, 'title contains module name and source tag';
            }

            eq_or_diff $dom->at( 'pre' )->text,
                $SHARE_DIR->child( qw( app perldoc bin shellcmd ) )->slurp_utf8;
        },
    );
};

subtest 'with Pod::Weaver' => sub {

    if ( !eval { require Pod::Weaver; 1 } ) {
        subtest 'missing Pod::Weaver throws error' => sub {
            my $app = Statocles::App::Perldoc->new(
                url_root => '/pod',
                inc => [
                    $SHARE_DIR->child( qw( app perldoc lib-weaver ) ),
                    $SHARE_DIR->child( qw( app perldoc bin-weaver ) ),
                ],
                modules => [qw( My My:: command shellcmd )],
                index_module => 'My::Internal',
                site => $site,
                data => {
                    info => 'This is the app info',
                },
                weave => 1,
                weave_config => $SHARE_DIR->child( qw( app perldoc weaver.ini ) ),
            );
            dies_ok { $app->pages };
        };
        return;
    }

    my $app = Statocles::App::Perldoc->new(
        url_root => '/pod',
        inc => [
            $SHARE_DIR->child( qw( app perldoc lib-weaver ) ),
            $SHARE_DIR->child( qw( app perldoc bin-weaver ) ),
        ],
        modules => [qw( My My:: command shellcmd )],
        index_module => 'My::Internal',
        site => $site,
        data => {
            info => 'This is the app info',
        },
        weave => 1,
        weave_config => $SHARE_DIR->child( qw( app perldoc weaver.ini ) ),
    );

    test_pages(
        $site, $app, @page_tests,

        '/pod/My/source.html' => sub {
            my ( $html, $dom ) = @_;
            my $node;

            if ( ok $node = $dom->at( 'title' ), 'title tag exists' ) {
                like $node->text, qr{\QMy (source)}, 'title contains module name and source tag';
            }

            eq_or_diff $dom->at( 'pre' )->text,
                $SHARE_DIR->child( qw( app perldoc lib-weaver My.pm ) )->slurp_utf8;
        },

        '/pod/My/Internal/source.html' => sub {
            my ( $html, $dom ) = @_;
            my $node;

            if ( ok $node = $dom->at( 'title' ), 'title tag exists' ) {
                like $node->text, qr{\QMy::Internal (source)}, 'title contains module name and source tag';
            }

            eq_or_diff $dom->at( 'pre' )->text,
                $SHARE_DIR->child( qw( app perldoc lib-weaver My Internal.pm ) )->slurp_utf8;
        },

        '/pod/command/source.html' => sub {
            my ( $html, $dom ) = @_;
            my $node;

            if ( ok $node = $dom->at( 'title' ), 'title tag exists' ) {
                like $node->text, qr{\Qcommand (source)}, 'title contains module name and source tag';
            }

            eq_or_diff $dom->at( 'pre' )->text,
                $SHARE_DIR->child( qw( app perldoc bin-weaver command.pl ) )->slurp_utf8;
        },

        '/pod/shellcmd/source.html' => sub {
            my ( $html, $dom ) = @_;
            my $node;

            if ( ok $node = $dom->at( 'title' ), 'title tag exists' ) {
                like $node->text, qr{\Qshellcmd (source)}, 'title contains module name and source tag';
            }

            eq_or_diff $dom->at( 'pre' )->text,
                $SHARE_DIR->child( qw( app perldoc bin-weaver shellcmd ) )->slurp_utf8;
        },

    );
};

done_testing;
