
use Test::Lib;
use My::Test;
use Statocles::Site;
my $SHARE_DIR = path( __DIR__ )->parent->child( 'share' );

use Statocles::Page::Plain;
my $site = Statocles::Site->new( deploy => tempdir );

subtest 'constructor' => sub {
    test_constructor(
        'Statocles::Page::Plain',
        required => {
            path => '/index.html',
            content => 'some test content',
        },
        default => {
            search_change_frequency => 'weekly',
            search_priority => 0.5,
            date => sub {
                isa_ok $_, 'DateTime::Moonpig';
            },
        },
    );
};

subtest 'render' => sub {
    $site->log->level( 'debug' );

    my $page = Statocles::Page::Plain->new(
        path => '/path/to/page.html',
        content => 'some test content',
        layout => "LAYOUT\n<%= \$content %>",
        template => "TEMPLATE\n<%= \$content %>",
    );

    eq_or_diff $page->render, "LAYOUT\nTEMPLATE\nsome test content\n\n";
    cmp_deeply $site->log->history->[-1],
        [ ignore(), 'debug', 'Render page: /path/to/page.html' ],
        'debug log shows render page message';

    subtest 'cached page shows up in log' => sub {
        $page->render;
        cmp_deeply $site->log->history->[-1],
            [ ignore(), 'debug', 'Render page (cached): /path/to/page.html' ],
            'debug log shows cached render page message';
    };
};

done_testing;
