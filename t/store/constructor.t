use Test::Lib;
use My::Test;
use Statocles::Store;
my $SHARE_DIR = path( __DIR__, '..', 'share' );
my $site = build_test_site( theme => $SHARE_DIR->child( 'theme' ) );

test_constructor(
    'Statocles::Store',
    required => {
        path => $SHARE_DIR->child( qw( store docs ) ),
    },
);

subtest 'warn if path does not exist' => sub {
    my $path = $SHARE_DIR->child( qw( DOES_NOT_EXIST ) );
    lives_ok {
        Statocles::Store->new(
            path => $path,
        )->read_documents;
    } 'store created with nonexistent path';

    cmp_deeply $site->log->history->[-1], [ ignore(), 'warn', qq{Store path "$path" does not exist} ]
        or diag explain $site->log->history->[-1];
};

done_testing;
