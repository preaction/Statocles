
use Test::Lib;
use My::Test;
use Capture::Tiny qw( capture );
use Mojo::IOLoop;
use Statocles;
use TestStore;
use TestApp;
use TestDeploy;
use Statocles::Site;
use Statocles::Command::daemon;
my $SHARE_DIR = path( __DIR__, '..', 'share' );

my $site = Statocles::Site->new(
    store => TestStore->new(
        path => tempdir,
        objects => [
            Statocles::Document->new(
                path => '/index.html',
                content => 'Index',
            ),
            Statocles::File->new(
                path => '/image.png',
            ),
        ],
    ),
    apps => {
        base => TestApp->new(
            url_root => '/',
            pages => [ ],
        ),
    },
    deploy => TestDeploy->new,
);
$site->store->path->child( 'image.png' )->touchpath;

subtest 'listen on a random port' => sub {
    # We need to stop the daemon after it starts
    my ( $port, $app );
    my $timeout = Mojo::IOLoop->singleton->timer( 0, sub {
        my $daemon = $Statocles::Command::daemon::daemon;
        my $id = $daemon->acceptors->[0];
        $port = $daemon->ioloop->acceptor( $id )->handle->sockport;
        $app = $daemon->app;
        $daemon->stop;
        Mojo::IOLoop->stop;
    } );

    # We want it to pick a random port
    local $ENV{MOJO_LISTEN} = 'http://127.0.0.1';
    local $ENV{MOJO_LOG_LEVEL} = 'info'; # But sometimes this isn't set?

    my $tmp = $site->store->path;
    my $cmd = Statocles::Command::daemon->new( site => $site );
    my ( $out, $err, $exit ) = capture { $cmd->run };
    undef $timeout;
    $site->clear_pages;

    is $exit, 0;
    like $out, qr{\QListening on http://127.0.0.1:$port\E\n},
        'contains http port information';

    isa_ok $app, 'Statocles::Command::daemon::_MOJOAPP';

    ok $tmp->child( '.statocles', 'build', 'index.html' )->exists, 'site was built';
};

subtest 'listen on a specific port' => sub {
    # We need to stop the daemon after it starts
    my ( $port, $app );
    my $timeout = Mojo::IOLoop->singleton->timer( 0, sub {
        my $daemon = $Statocles::Command::daemon::daemon;
        my $id = $daemon->acceptors->[0];
        $port = $daemon->ioloop->acceptor( $id )->handle->sockport;
        $app = $daemon->app;
        $daemon->stop;
        Mojo::IOLoop->stop;
    } );

    local $ENV{MOJO_LOG_LEVEL} = 'info'; # But sometimes this isn't set?

    my @args = (
        '-p', 12126,
        '-v', # watch lines are now behind -v
    );

    my $tmp = $site->store->path;
    my $cmd = Statocles::Command::daemon->new( site => $site );
    my ( $out, $err, $exit ) = capture { $cmd->run( @args ) };
    undef $timeout;
    $site->clear_pages;

    is $port, 12126, 'correct port';

    is $exit, 0;
    like $out, qr{\QListening on http://0.0.0.0:$port\E\n},
        'contains http port information';
};

subtest '--date' => sub {
    # We need to stop the daemon after it starts
    my $timeout = Mojo::IOLoop->timer( 0, sub {
        my $daemon = $Statocles::Command::daemon::daemon;
        $daemon->stop;
        Mojo::IOLoop->stop;
    } );

    # We want it to pick a random port
    local $ENV{MOJO_LISTEN} = 'http://127.0.0.1';

    my @args = (
        '--date', '9999-12-31',
    );

    my $tmp = $site->store->path;
    my $cmd = Statocles::Command::daemon->new( site => $site );
    my ( $out, $err, $exit ) = capture { $cmd->run( @args ) };
    undef $timeout;
    $site->clear_pages;

    is_deeply { @{ $site->app( 'base' )->last_pages_args } },
        { date => '9999-12-31' },
        'app pages() method args is correct';
};

done_testing;
