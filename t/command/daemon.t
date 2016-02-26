
use Test::Lib;
use My::Test;
use Capture::Tiny qw( capture );
use Mojo::IOLoop;
use Statocles::Command;
my $SHARE_DIR = path( __DIR__, '..', 'share' );

my ( $tmp, $config_fn, $config ) = build_temp_site( $SHARE_DIR );

subtest 'listen on a random port' => sub {
    # We need to stop the daemon after it starts
    my ( $port, $app );
    my $timeout = Mojo::IOLoop->singleton->timer( 0, sub {
        my $daemon = $Statocles::Command::daemon;
        my $id = $daemon->acceptors->[0];
        $port = $daemon->ioloop->acceptor( $id )->handle->sockport;
        $app = $daemon->app;
        $daemon->stop;
        Mojo::IOLoop->stop;
    } );

    # We want it to pick a random port
    local $ENV{MOJO_LISTEN} = 'http://127.0.0.1';
    local $ENV{MOJO_LOG_LEVEL} = 'info'; # But sometimes this isn't set?

    my @args = (
        '--config' => "$config_fn",
        'daemon',
        '-v', # watch lines are now behind -v
    );

    my ( $out, $err, $exit ) = capture { Statocles::Command->main( @args ) };
    undef $timeout;

    my $store_path = $app->site->app( 'blog' )->store->path;
    my $theme_path = $app->site->theme->store->path;

    if ( eval { require Mac::FSEvents; 1; } ) {
        like $out, qr{Watching for changes in '$store_path'}, 'watch is reported';
        like $out, qr{Watching for changes in '$theme_path'}, 'watch is reported';
    }
    ok !$err, 'nothing on stderr' or diag "STDERR: $err";

    is $exit, 0;
    like $out, qr{\QListening on http://127.0.0.1:$port\E\n},
        'contains http port information';

    isa_ok $app, 'Statocles::Command::_MOJOAPP';

    ok $tmp->child( 'build_site', 'index.html' )->exists, 'site was built';
    ok !$tmp->child( 'deploy_site', 'index.html' )->exists, 'site was not deployed';

    subtest 'do not watch the built-in themes' => sub {
        if ( eval { require Mac::FSEvents; 1; } ) {

            my ( $port, $app );
            my $timeout = Mojo::IOLoop->singleton->timer( 0, sub {
                my $daemon = $Statocles::Command::daemon;
                my $id = $daemon->acceptors->[0];
                $port = $daemon->ioloop->acceptor( $id )->handle->sockport;
                $app = $daemon->app;
                $daemon->stop;
                Mojo::IOLoop->stop;
            } );

            my @args = (
                '--config' => "$config_fn",
                '--site' => 'site_foo',
                'daemon',
                '-v',
            );

            my ( $out, $err, $exit ) = capture { Statocles::Command->main( @args ) };
            undef $timeout;

            my $store_path = $app->site->app( 'blog' )->store->path;
            my $theme_path = $app->site->theme->store->path;
            like $out, qr{Watching for changes in '$store_path'}, 'watch is reported';
            unlike $out, qr{Watching for changes in '$theme_path'}, 'watch is not reported';
        }
        else {
            pass "No test - Mac::FSEvents not installed";
        }
    };
};

subtest 'listen on a specific port' => sub {
    # We need to stop the daemon after it starts
    my ( $port, $app );
    my $timeout = Mojo::IOLoop->singleton->timer( 0, sub {
        my $daemon = $Statocles::Command::daemon;
        my $id = $daemon->acceptors->[0];
        $port = $daemon->ioloop->acceptor( $id )->handle->sockport;
        $app = $daemon->app;
        $daemon->stop;
        Mojo::IOLoop->stop;
    } );

    local $ENV{MOJO_LOG_LEVEL} = 'info'; # But sometimes this isn't set?

    my @args = (
        '--config' => "$config_fn",
        'daemon',
        '-p', 12126,
        '-v', # watch lines are now behind -v
    );

    my ( $out, $err, $exit ) = capture { Statocles::Command->main( @args ) };
    undef $timeout;

    is $port, 12126, 'correct port';
    ok !$err, 'nothing on stderr' or diag "STDERR: $err";

    is $exit, 0;
    like $out, qr{\QListening on http://0.0.0.0:$port\E\n},
        'contains http port information';
};

subtest '--date' => sub {
    my ( $tmp, $config_fn, $config ) = build_temp_site( $SHARE_DIR );

    # We need to stop the daemon after it starts
    my $timeout = Mojo::IOLoop->timer( 0, sub {
        my $daemon = $Statocles::Command::daemon;
        $daemon->stop;
        Mojo::IOLoop->stop;
    } );

    # We want it to pick a random port
    local $ENV{MOJO_LISTEN} = 'http://127.0.0.1';

    my @args = (
        '--config' => "$config_fn",
        'daemon',
        '--date', '9999-12-31',
    );

    my ( $out, $err, $exit ) = capture { Statocles::Command->main( @args ) };
    undef $timeout;

    ok !$err, 'nothing on stderr' or diag "STDERR: $err";
    is $exit, 0;

    my $post = $tmp->child( 'build_site', 'blog', '9999', '12', '31', 'forever-is-a-long-time', 'index.html' );
    ok $post->exists, 'future post was built';
    ok !$tmp->child( 'deploy_site', 'index.html' )->exists, 'site was not deployed';
};

done_testing;
