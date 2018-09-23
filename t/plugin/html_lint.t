
use Test::Lib;
use My::Test;
BEGIN {
    eval { require HTML::Lint::Pluggable; HTML::Lint::Pluggable->VERSION( 0.06 ); 1 } or plan skip_all => 'HTML::Lint::Pluggable v0.06 or higher needed';
};

use Mojo::Log;
use Statocles::Plugin::HTMLLint;
use Statocles::Site;
use TestStore;
my $SHARE_DIR = path( __DIR__, '..', 'share' );

subtest 'check html' => sub {
    my $log_str;
    open my $log_fh, '>', \$log_str;
    my $log = Mojo::Log->new( level => 'warn', handle => $log_fh, max_history_size => 500 );

    my $site = Statocles::Site->new(
        store => TestStore->new(
            path => '.',
            objects => [
                Statocles::Document->new(
                    path => '/index.markdown',
                    content => '<img src="foo.jpg">',
                ),
            ],
        ),
        deploy => '.',
    );

    my $plugin = Statocles::Plugin::HTMLLint->new;
    $plugin->register( $site );
    $site->pages;

    cmp_deeply $site->log->history,
        bag(
            [
              ignore(),
              'warn',
              '-/index.html (28:28) <img src="foo.jpg"> tag has no HEIGHT and WIDTH attributes',
            ],
            [
              ignore(),
              'warn',
              '-/index.html (28:28) <img src="foo.jpg"> does not have ALT text defined',
            ],,
        ),
        'lint problems found'
            or diag explain $site->log->history;

};


done_testing;
