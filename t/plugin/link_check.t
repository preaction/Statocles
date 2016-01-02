
use Statocles::Base 'Test';
use Mojo::Log;
use Statocles::Plugin::LinkCheck;
my $SHARE_DIR = path( __DIR__, '..', 'share' );

subtest 'check links' => sub {
    my $log_str;
    open my $log_fh, '>', \$log_str;
    my $log = Mojo::Log->new( level => 'warn', handle => $log_fh );

    my ( $site, $build_dir, $deploy_dir ) = build_test_site_apps( $SHARE_DIR, log => $log );
    my $plugin = Statocles::Plugin::LinkCheck->new;
    $plugin->register( $site );

    $site->build;

    my $page = '/blog/2014/06/02/more_tags/index.html';

    cmp_deeply $site->log->history,
        bag(
            [ ignore(), 'warn', re(qr{\QURL broken on $page: '/does_not_exist.jpg' not found}) ],
            [ ignore(), 'warn', re(qr{\QURL broken on $page: '/does_not_exist' not found}) ],
            [ ignore(), 'warn', re(qr{\QURL broken on $page: '/images/with spaces.png' not found}) ],
            [ ignore(), 'warn', re(qr{\QURL broken on $page: '/blog/2014/06/02/more_tags/does_not_exist' not found}) ],
        ),
        'broken links found'
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
                '/does_not_exist',
            ]
        );
        $plugin->register( $site );

        $site->build;

        my $page = '/blog/2014/06/02/more_tags/index.html';

        cmp_deeply $site->log->history,
            bag(
                [ ignore(), 'warn', re(qr{\QURL broken on $page: '/images/with spaces.png' not found}) ],
                [ ignore(), 'warn', re(qr{\QURL broken on $page: '/blog/2014/06/02/more_tags/does_not_exist' not found}) ],
            ),
            'broken links found'
                or diag explain $site->log->history;
    };

    subtest 'regex pattern' => sub {
        my $log_str;
        open my $log_fh, '>', \$log_str;
        my $log = Mojo::Log->new( level => 'warn', handle => $log_fh );

        my ( $site, $build_dir, $deploy_dir ) = build_test_site_apps( $SHARE_DIR, log => $log );
        my $plugin = Statocles::Plugin::LinkCheck->new(
            ignore => [
                '.*/does_not_exist',
                '.*/with spaces[.]png',
            ]
        );
        $plugin->register( $site );

        $site->build;

        my $page = '/blog/2014/06/02/more_tags/index.html';

        cmp_deeply $site->log->history, [],
            'all broken links ignored'
                or diag explain $site->log->history;
    };

};


done_testing;
