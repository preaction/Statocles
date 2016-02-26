
use Test::Lib;
use My::Test;
BEGIN {
    eval { require HTML::Lint::Pluggable; HTML::Lint::Pluggable->VERSION( 0.06 ); 1 } or plan skip_all => 'HTML::Lint::Pluggable v0.06 or higher needed';
};

use Mojo::Log;
use Statocles::Plugin::HTMLLint;
my $SHARE_DIR = path( __DIR__, '..', 'share' );

subtest 'check html' => sub {
    my $log_str;
    open my $log_fh, '>', \$log_str;
    my $log = Mojo::Log->new( level => 'warn', handle => $log_fh, max_history_size => 500 );

    my ( $site, $build_dir, $deploy_dir ) = build_test_site_apps( $SHARE_DIR, log => $log );
    my $plugin = Statocles::Plugin::HTMLLint->new;
    $plugin->register( $site );
    $site->build;

    cmp_deeply $site->log->history,
        bag(
            [
              ignore(),
              'warn',
              'Lint failures on /blog/2014/06/02/more_tags/index.html:',
            ],
            [
              ignore(),
              'warn',
              '- (43:4) <img src="/does_not_exist.jpg"> tag has no HEIGHT and WIDTH attributes',
            ],
            [
              ignore(),
              'warn',
              '- (54:4) <img src="image.markdown.jpg"> tag has no HEIGHT and WIDTH attributes',
            ],
            [
              ignore(),
              'warn',
              'Lint failures on /blog/2014/04/30/plug/index.html:',
            ],
            [
              ignore(),
              'warn',
              '- (34:4) <img src="image.jpg"> tag has no HEIGHT and WIDTH attributes',
            ]
        ),
        'lint problems found'
            or diag explain $site->log->history;

};


done_testing;
