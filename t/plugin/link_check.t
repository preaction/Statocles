
use Test::Lib;
use My::Test;
use Mojo::Log;
use Statocles::Plugin::LinkCheck;
use Statocles::Image;
my $SHARE_DIR = path( __DIR__, '..', 'share' );

subtest 'check links' => sub {
    my $log_str;
    open my $log_fh, '>', \$log_str;
    my $log = Mojo::Log->new( level => 'warn', handle => $log_fh, max_history_size => 500 );

    my ( $site, $build_dir, $deploy_dir ) = build_test_site_apps( $SHARE_DIR, log => $log );
    $site->links( stylesheet => '/missing/stylesheet.css' );
    $site->links( script => '/missing/script.js' );
    $site->images->{ icon } = Statocles::Image->new( src => '/missing/favicon.png' );

    my $plugin = Statocles::Plugin::LinkCheck->new;
    $plugin->register( $site );

    $site->build;

    cmp_deeply $site->log->history,
        [
            [ ignore(), warn => re(qr{\QURL broken on /aaa.html: '/missing/favicon.png' not found} ) ],
            [ ignore(), warn => re(qr{\QURL broken on /aaa.html: '/missing/script.js' not found} ) ],
            [ ignore(), warn => re(qr{\QURL broken on /aaa.html: '/missing/stylesheet.css' not found} ) ],
            [ ignore(), warn => re(qr{\QURL broken on /blog/2014/04/23/slug/index.html: '/missing/favicon.png' not found} ) ],
            [ ignore(), warn => re(qr{\QURL broken on /blog/2014/04/23/slug/index.html: '/missing/script.js' not found} ) ],
            [ ignore(), warn => re(qr{\QURL broken on /blog/2014/04/23/slug/index.html: '/missing/stylesheet.css' not found} ) ],
            [ ignore(), warn => re(qr{\QURL broken on /blog/2014/04/30/plug/index.html: '/missing/favicon.png' not found} ) ],
            [ ignore(), warn => re(qr{\QURL broken on /blog/2014/04/30/plug/index.html: '/missing/script.js' not found} ) ],
            [ ignore(), warn => re(qr{\QURL broken on /blog/2014/04/30/plug/index.html: '/missing/stylesheet.css' not found} ) ],
            [ ignore(), warn => re(qr{\QURL broken on /blog/2014/04/30/plug/recipe.html: '/missing/favicon.png' not found} ) ],
            [ ignore(), warn => re(qr{\QURL broken on /blog/2014/04/30/plug/recipe.html: '/missing/script.js' not found} ) ],
            [ ignore(), warn => re(qr{\QURL broken on /blog/2014/04/30/plug/recipe.html: '/missing/stylesheet.css' not found} ) ],
            [ ignore(), warn => re(qr{\QURL broken on /blog/2014/05/22/(regex)[name].file.html: '/missing/favicon.png' not found} ) ],
            [ ignore(), warn => re(qr{\QURL broken on /blog/2014/05/22/(regex)[name].file.html: '/missing/script.js' not found} ) ],
            [ ignore(), warn => re(qr{\QURL broken on /blog/2014/05/22/(regex)[name].file.html: '/missing/stylesheet.css' not found} ) ],
            [ ignore(), warn => re(qr{\QURL broken on /blog/2014/06/02/more_tags/docs.html: '/missing/favicon.png' not found} ) ],
            [ ignore(), warn => re(qr{\QURL broken on /blog/2014/06/02/more_tags/docs.html: '/missing/script.js' not found} ) ],
            [ ignore(), warn => re(qr{\QURL broken on /blog/2014/06/02/more_tags/docs.html: '/missing/stylesheet.css' not found} ) ],
            [ ignore(), warn => re(qr{\QURL broken on /blog/2014/06/02/more_tags/index.html: '/blog/2014/06/02/more_tags/does_not_exist' not found}) ],
            [ ignore(), warn => re(qr{\QURL broken on /blog/2014/06/02/more_tags/index.html: '/does_not_exist' not found}) ],
            [ ignore(), warn => re(qr{\QURL broken on /blog/2014/06/02/more_tags/index.html: '/does_not_exist.jpg' not found}) ],
            [ ignore(), warn => re(qr{\QURL broken on /blog/2014/06/02/more_tags/index.html: '/images/with spaces.png' not found}) ],
            [ ignore(), warn => re(qr{\QURL broken on /blog/2014/06/02/more_tags/index.html: '/missing/favicon.png' not found} ) ],
            [ ignore(), warn => re(qr{\QURL broken on /blog/2014/06/02/more_tags/index.html: '/missing/script.js' not found} ) ],
            [ ignore(), warn => re(qr{\QURL broken on /blog/2014/06/02/more_tags/index.html: '/missing/stylesheet.css' not found} ) ],
            [ ignore(), warn => re(qr{\QURL broken on /foo/index.html: '/missing/favicon.png' not found} ) ],
            [ ignore(), warn => re(qr{\QURL broken on /foo/index.html: '/missing/script.js' not found} ) ],
            [ ignore(), warn => re(qr{\QURL broken on /foo/index.html: '/missing/stylesheet.css' not found} ) ],
            [ ignore(), warn => re(qr{\QURL broken on /foo/other.html: '/missing/favicon.png' not found} ) ],
            [ ignore(), warn => re(qr{\QURL broken on /foo/other.html: '/missing/script.js' not found} ) ],
            [ ignore(), warn => re(qr{\QURL broken on /foo/other.html: '/missing/stylesheet.css' not found} ) ],
            [ ignore(), warn => re(qr{\QURL broken on /foo/utf8.html: '/missing/favicon.png' not found} ) ],
            [ ignore(), warn => re(qr{\QURL broken on /foo/utf8.html: '/missing/script.js' not found} ) ],
            [ ignore(), warn => re(qr{\QURL broken on /foo/utf8.html: '/missing/stylesheet.css' not found} ) ],
            [ ignore(), warn => re(qr{\QURL broken on /index.html: '/missing/favicon.png' not found} ) ],
            [ ignore(), warn => re(qr{\QURL broken on /index.html: '/missing/script.js' not found} ) ],
            [ ignore(), warn => re(qr{\QURL broken on /index.html: '/missing/stylesheet.css' not found} ) ],
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
                '/does_not_exist',
            ]
        );
        $plugin->register( $site );

        $site->build;

        my $page = '/blog/2014/06/02/more_tags/index.html';

        cmp_deeply $site->log->history,
            bag(
                [ ignore(), 'warn', re(qr{\QURL broken on $page: '/blog/2014/06/02/more_tags/does_not_exist' not found}) ],
                [ ignore(), 'warn', re(qr{\QURL broken on $page: '/images/with spaces.png' not found}) ],
            ),
            'broken links found and sorted by page -> missing url'
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
