
use Test::Lib;
use My::Test;
use Mojo::Log;
use Statocles::Plugin::LinkCheck;
use Statocles::Image;
use Statocles::Site;
use TestStore;
my $SHARE_DIR = path( __DIR__, '..', 'share' );

subtest 'check links' => sub {
    my $log_str;
    open my $log_fh, '>', \$log_str;
    my $log = Mojo::Log->new( level => 'warn', handle => $log_fh, max_history_size => 500 );

    my $site = Statocles::Site->new(
        store => TestStore->new(
            path => '.',
            objects => [
                Statocles::Document->new(
                    path => '/index.markdown',
                    content => '<a href="/missing.html"><img src="/foo.jpg"></a>',
                ),
                Statocles::Document->new(
                    path => '/foo.markdown',
                    content => '<a href="/">Index</a>',
                ),
            ],
        ),
        deploy => '.',
    );

    my $plugin = Statocles::Plugin::LinkCheck->new;
    $plugin->register( $site );

    $site->pages;

    cmp_deeply $site->log->history,
        [
            [
              ignore(),
              'warn',
              "URL broken on /index.html: \'/foo.jpg\' not found",
            ],
            [
              ignore(),
              'warn',
              "URL broken on /index.html: \'/missing.html\' not found",
            ],
        ],
        'broken links found and sorted by page -> missing url'
            or diag explain $site->log->history;

};

subtest 'ignore patterns' => sub {

    subtest 'prefix matching' => sub {
        my $log_str;
        open my $log_fh, '>', \$log_str;
        my $log = Mojo::Log->new( level => 'warn', handle => $log_fh );

        my ( $site, $build_dir, $deploy_dir ) = build_test_site_apps( $SHARE_DIR, log => $log );
        my $plugin = Statocles::Plugin::LinkCheck->new(
            ignore => [
                '/missing.html',
                '.*[.]jpg',
            ]
        );
        $plugin->register( $site );

        $site->pages;

        cmp_deeply $site->log->history,
            [],
            'all broken links ignored'
                or diag explain $site->log->history;
    };
};


done_testing;
