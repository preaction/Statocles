
use Statocles::Base 'Test';
use Capture::Tiny qw( capture );
use Mojo::IOLoop;
use Statocles::Command;
my $SHARE_DIR = path( __DIR__, '..', 'share' );

my ( $tmp, $config_fn, $config ) = build_temp_site( $SHARE_DIR );

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

done_testing;
