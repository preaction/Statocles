
use Statocles::Test;
my $SHARE_DIR = catdir( __DIR__, 'share' );
use FindBin;
use Capture::Tiny qw( capture );
use Statocles::Command;
use Statocles::Site;
use YAML;

# Build a config file so we can test config loading and still use
# temporary directories
my $tmp = File::Temp->newdir;
my $config = {
    theme => {
        class => 'Statocles::Theme',
        args => {
            source_dir => catdir( $SHARE_DIR, 'theme' ),
        },
    },
    build => {
        class => 'Statocles::Store',
        args => {
            path => catdir( $tmp->dirname, 'build_site' ),
        },
    },
    deploy => {
        class => 'Statocles::Store',
        args => {
            path => catdir( $tmp->dirname, 'deploy_site' ),
        },
    },
    blog => {
        'class' => 'Statocles::App::Blog',
        'args' => {
            source => {
                '$class' => 'Statocles::Store',
                '$args' => {
                    path => catdir( $SHARE_DIR, 'blog' ),
                },
            },
            url_root => '/blog',
            theme => { '$ref' => 'theme' },
        },
    },
    site => {
        class => 'Statocles::Site',
        args => {
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
            path => catdir( $tmp->dirname, 'build_foo' ),
        },
    },
    deploy_foo => {
        class => 'Statocles::Store',
        args => {
            path => catdir( $tmp->dirname, 'deploy_foo' ),
        },
    },
    site_foo => {
        class => 'Statocles::Site',
        args => {
            index => 'blog',
            build_store => { '$ref' => 'build_foo' },
            deploy_store => { '$ref' => 'deploy_foo' },
            apps => {
                blog => { '$ref' => 'blog' },
            },
        },
    },
};
my $config_fn = catfile( $tmp->dirname, 'site.yml' );
YAML::DumpFile( $config_fn, $config );

subtest 'get help' => sub {
    $0 = "$FindBin::Bin/../bin/statocles";
    my ( $out, $err, $exit ) = capture { Statocles::Command->main( '-h' ) };
    ok !$err, 'help output is on stdout';
    like $out, qr{statocles -h},
        'reports pod from bin/statocles, not Statocles::Command';
};

sub test_site {
    my ( $root, @args ) = @_;
    return sub {
        my ( $out, $err, $exit ) = capture { Statocles::Command->main( @args ) };
        is $exit, 0, 'exit code';
        ok !$err, 'no errors/warnings' or diag $err;
        ok -d $root, 'root dir exists';
        ok -f catfile( $root, 'index.html' ), 'index file exists';
        ok -f catfile( $root, 'blog', 'index.html' );
        ok -f catfile( $root, 'blog', '2014', '04', '23', 'slug.html' );
        ok -f catfile( $root, 'blog', '2014', '04', '30', 'plug.html' );
    };
}

subtest 'build site' => sub {
    my @args = (
        '--config' => $config_fn,
        'build',
    );
    subtest 'default site' => test_site(
        $config->{build}{args}{path},
        @args,
    );
    subtest 'custom site' => test_site(
        $config->{build_foo}{args}{path},
        '--site' => 'site_foo',
        @args,
    );
};

subtest 'deploy site' => sub {
    my @args = (
        '--config' => $config_fn,
        'deploy',
    );
    subtest 'default site' => test_site(
        $config->{deploy}{args}{path},
        @args,
    );
    subtest 'custom site' => test_site(
        $config->{deploy_foo}{args}{path},
        '--site' => 'site_foo',
        @args,
    );
};

done_testing;
