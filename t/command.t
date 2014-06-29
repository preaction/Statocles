
use Statocles::Test;
my $SHARE_DIR = path( __DIR__, 'share' );
use FindBin;
use Capture::Tiny qw( capture );
use Statocles::Command;
use Statocles::Site;
use Mojo::IOLoop;
use YAML;

# Build a config file so we can test config loading and still use
# temporary directories
my $tmp = tempdir;
my $config = {
    theme => {
        class => 'Statocles::Theme',
        args => {
            path => $SHARE_DIR->child( 'theme' ),
        },
    },
    build => {
        class => 'Statocles::Store',
        args => {
            path => $tmp->child( 'build_site' ),
        },
    },
    deploy => {
        class => 'Statocles::Store',
        args => {
            path => $tmp->child( 'deploy_site' ),
        },
    },
    blog => {
        'class' => 'Statocles::App::Blog',
        'args' => {
            store => {
                '$class' => 'Statocles::Store',
                '$args' => {
                    path => $SHARE_DIR->child( 'blog' ),
                },
            },
            url_root => '/blog',
            theme => { '$ref' => 'theme' },
        },
    },
    site => {
        class => 'Statocles::Site',
        args => {
            base_url => 'http://example.com',
            title => 'Site Title',
            index => 'blog',
            build_store => { '$ref' => 'build' },
            deploy_store => { '$ref' => 'deploy' },
            apps => {
                blog => { '$ref' => 'blog' },
            },
        },
    },
    build_foo => {
        class => 'Statocles::Store',
        args => {
            path => $tmp->child( 'build_foo' ),
        },
    },
    deploy_foo => {
        class => 'Statocles::Store',
        args => {
            path => $tmp->child( 'deploy_foo' ),
        },
    },
    site_foo => {
        class => 'Statocles::Site',
        args => {
            base_url => 'http://example.net',
            title => 'Site Foo',
            index => 'blog',
            build_store => { '$ref' => 'build_foo' },
            deploy_store => { '$ref' => 'deploy_foo' },
            apps => {
                blog => { '$ref' => 'blog' },
            },
        },
    },
};
my $config_fn = $tmp->child( 'site.yml' );
YAML::DumpFile( $config_fn, $config );

subtest 'get help' => sub {
    $0 = path( $FindBin::Bin )->parent->child( 'bin', 'statocles' )->stringify;
    my ( $out, $err, $exit ) = capture { Statocles::Command->main( '-h' ) };
    ok !$err, 'help output is on stdout';
    like $out, qr{statocles -h},
        'reports pod from bin/statocles, not Statocles::Command';
    is $exit, 0;
};

subtest 'get version' => sub {
    local $Statocles::Command::VERSION = '1.00';
    my ( $output, $stderr, $exit ) = capture { Statocles::Command->main( '--version' ) };
    is $exit, 0;
    ok !$stderr, 'stderr is empty' or diag "STDERR: $stderr";
    is $output, "Statocles version 1.00 (Perl $^V)\n";
};


sub test_site {
    my ( $root, @args ) = @_;
    return sub {
        my ( $out, $err, $exit ) = capture { Statocles::Command->main( @args ) };
        is $exit, 0, 'exit code';
        ok !$err, 'no errors/warnings' or diag $err;
        ok $root->child( 'index.html' )->exists, 'index file exists';
        ok $root->child( 'sitemap.xml' )->exists, 'sitemap.xml exists';
        ok $root->child( 'blog', '2014', '04', '23', 'slug.html' )->exists;
        ok $root->child( 'blog', '2014', '04', '30', 'plug.html' )->exists;
    };
}

subtest 'build site' => sub {
    my @args = (
        '--config' => "$config_fn",
        'build',
    );
    subtest 'default site' => test_site(
        $tmp->child( 'build_site' ),
        @args,
    );
    subtest 'custom site' => test_site(
        $tmp->child( 'build_foo' ),
        '--site' => 'site_foo',
        @args,
    );
};

subtest 'deploy site' => sub {
    my @args = (
        '--config' => "$config_fn",
        'deploy',
    );
    subtest 'default site' => test_site(
        $tmp->child( 'deploy_site' ),
        @args,
    );
    subtest 'custom site' => test_site(
        $tmp->child( 'deploy_foo' ),
        '--site' => 'site_foo',
        @args,
    );
};

subtest 'get the app list' => sub {
    my @args = (
        '--config' => "$config_fn",
        'apps',
    );
    my ( $out, $err, $exit ) = capture { Statocles::Command->main( @args ) };
    ok !$err, 'app list is on stdout';
    is $exit, 0;
    is $out, "blog (/blog -- Statocles::App::Blog)\n",
        'contains app name, url root, and app class';
};

subtest 'delegate to app command' => sub {
    my @args = (
        '--config' => "$config_fn",
        'blog' => 'help',
    );
    my ( $out, $err, $exit ) = capture { Statocles::Command->main( @args ) };
    ok !$err, 'blog help is on stdout';
    is $exit, 0;
    like $out, qr{\Qblog post [--date YYYY-MM-DD] <title> -- Create a new blog post},
        'contains blog help information';
};

subtest 'run the http daemon' => sub {
    # We need to stop the daemon after it starts
    my $timeout = Mojo::IOLoop->singleton->timer( 0, sub { kill 'TERM', $$ } );
    my @args = (
        '--config' => "$config_fn",
        'daemon',
    );
    my ( $out, $err, $exit ) = capture { Statocles::Command->main( @args ) };
    undef $timeout;
    ok !$err, 'port info is on stdout';
    is $exit, 0;
    like $out, qr{\QListening on http://*:3000\E\n},
        'contains http port information';
};

done_testing;
