
use Statocles::Base 'Test';
use Statocles::Plugin::LinkCheck;
my $SHARE_DIR = path( __DIR__, '..', 'share' );

subtest 'check links' => sub {
    my ( $site, $build_dir, $deploy_dir ) = build_test_site_apps( $SHARE_DIR );
    my $plugin = Statocles::Plugin::LinkCheck->new;
    $site->on( 'build', sub { $plugin->check_pages( @_ ) } );

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
        my ( $site, $build_dir, $deploy_dir ) = build_test_site_apps( $SHARE_DIR );
        my $plugin = Statocles::Plugin::LinkCheck->new(
            ignore => [
                '/does_not_exist',
            ]
        );
        $site->on( 'build', sub { $plugin->check_pages( @_ ) } );

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
        my ( $site, $build_dir, $deploy_dir ) = build_test_site_apps( $SHARE_DIR );
        my $plugin = Statocles::Plugin::LinkCheck->new(
            ignore => [
                '.*/does_not_exist',
                '.*/with spaces[.]png',
            ]
        );
        $site->on( 'build', sub { $plugin->check_pages( @_ ) } );

        $site->build;

        my $page = '/blog/2014/06/02/more_tags/index.html';

        cmp_deeply $site->log->history, [],
            'all broken links ignored'
                or diag explain $site->log->history;
    };

};


done_testing;
