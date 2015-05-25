
use Statocles::Base 'Test';
use Statocles::App::Perldoc;

my $SHARE_DIR = path( __DIR__ )->parent->parent->child( 'share' );
my $site = build_test_site(
    theme => $SHARE_DIR->child( 'theme' ),
);

my @page_tests = (
    '/pod/index.html' => sub {
        my ( $html, $dom ) = @_;
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
        ok $dom->at( 'a[href="/pod/My.src.html"]' ), 'source link exists';

        if ( ok $node = $dom->at( 'footer #app-info' ) ) {
            is $node->text, 'This is the app info', 'app-info is correct';
        }
    },

    '/pod/My/Internal.html' => sub {
        my ( $html, $dom ) = @_;
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
        ok $dom->at( 'a[href="/pod/My/Internal.src.html"]' ), 'source link exists';

        if ( ok $node = $dom->at( 'footer #app-info' ) ) {
            is $node->text, 'This is the app info', 'app-info is correct';
        }
    },

    '/pod/command.html' => sub {
        my ( $html, $dom ) = @_;
        # XXX: Find the layout and template
        my $node;

        if ( ok $node = $dom->at( 'h1#NAME' ) ) {
            is $node->text, 'NAME';
        }

        if ( ok $node = $dom->at( 'h1#NAME + p' ) ) {
            is $node->text, 'command.pl - A command-line program with POD';
        }

        if ( ok $node = $dom->at( 'h1#SYNOPSIS + pre code' ) ) {
            like $node->text, qr{command[.]pl -h};
        }

        ok $dom->at( 'a[href="/pod/command.html"]' ), 'internal link to same page';
        ok $dom->at( 'a[href="/pod/command.src.html"]' ), 'source link exists';

        if ( ok $node = $dom->at( 'footer #app-info' ) ) {
            is $node->text, 'This is the app info', 'app-info is correct';
        }
    },

    '/pod/shellcmd.html' => sub {
        my ( $html, $dom ) = @_;
        # XXX: Find the layout and template
        my $node;

        if ( ok $node = $dom->at( 'h1#NAME' ) ) {
            is $node->text, 'NAME';
        }

        if ( ok $node = $dom->at( 'h1#NAME + p' ) ) {
            is $node->text, 'shellcmd - A command without an extension';
        }

        if ( ok $node = $dom->at( 'h1#SYNOPSIS + pre code' ) ) {
            like $node->text, qr{shellcmd -h};
        }

        ok $dom->at( 'a[href="/pod/shellcmd.html"]' ), 'internal link to same page';
        ok $dom->at( 'a[href="/pod/shellcmd.src.html"]' ), 'source link exists';

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
        index_module => 'My',
        site => $site,
        data => {
            info => 'This is the app info',
        },
    );

    test_pages(
        $site, $app, @page_tests,

        '/pod/My.src.html' => sub {
            my ( $html, $dom ) = @_;
            eq_or_diff $dom->at( 'pre' )->text,
                $SHARE_DIR->child( qw( app perldoc lib My.pm ) )->slurp_utf8;
        },

        '/pod/My/Internal.src.html' => sub {
            my ( $html, $dom ) = @_;
            eq_or_diff $dom->at( 'pre' )->text,
                $SHARE_DIR->child( qw( app perldoc lib My Internal.pm ) )->slurp_utf8;
        },

        '/pod/command.src.html' => sub {
            my ( $html, $dom ) = @_;
            eq_or_diff $dom->at( 'pre' )->text,
                $SHARE_DIR->child( qw( app perldoc bin command.pl ) )->slurp_utf8;
        },

        '/pod/shellcmd.src.html' => sub {
            my ( $html, $dom ) = @_;
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
                index_module => 'My',
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
        index_module => 'My',
        site => $site,
        data => {
            info => 'This is the app info',
        },
        weave => 1,
        weave_config => $SHARE_DIR->child( qw( app perldoc weaver.ini ) ),
    );

    test_pages(
        $site, $app, @page_tests,

        '/pod/My.src.html' => sub {
            my ( $html, $dom ) = @_;
            eq_or_diff $dom->at( 'pre' )->text,
                $SHARE_DIR->child( qw( app perldoc lib-weaver My.pm ) )->slurp_utf8;
        },

        '/pod/My/Internal.src.html' => sub {
            my ( $html, $dom ) = @_;
            eq_or_diff $dom->at( 'pre' )->text,
                $SHARE_DIR->child( qw( app perldoc lib-weaver My Internal.pm ) )->slurp_utf8;
        },

        '/pod/command.src.html' => sub {
            my ( $html, $dom ) = @_;
            eq_or_diff $dom->at( 'pre' )->text,
                $SHARE_DIR->child( qw( app perldoc bin-weaver command.pl ) )->slurp_utf8;
        },

        '/pod/shellcmd.src.html' => sub {
            my ( $html, $dom ) = @_;
            eq_or_diff $dom->at( 'pre' )->text,
                $SHARE_DIR->child( qw( app perldoc bin-weaver shellcmd ) )->slurp_utf8;
        },

    );
};

done_testing;
