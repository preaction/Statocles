
use Test::Lib;
use My::Test;
use Capture::Tiny qw( capture );
use Statocles::Command;
my $SHARE_DIR = path( __DIR__, '..', 'share' );

sub test_site {
    my ( $root, @args ) = @_;
    my $debug = grep { /^-vv$/ } @args;
    return sub {
        my ( $out, $err, $exit ) = capture { Statocles::Command->main( @args ) };
        is $exit, 0, 'exit code';
        ok !$err, "no errors/warnings on stderr (debug: $debug)" or diag $err;
        ok $root->child( 'index.html' )->exists, 'index file exists';
        ok $root->child( 'sitemap.xml' )->exists, 'sitemap.xml exists';
        ok $root->child( 'blog', '2014', '04', '23', 'slug', 'index.html' )->exists;
        ok $root->child( 'blog', '2014', '04', '30', 'plug', 'index.html' )->exists;
        if ( $debug ) {
            subtest 'debug output is verbose' => sub {
                like $out, qr{Write file: /index[.]html};
                like $out, qr{Write file: sitemap[.]xml};
            };
        }
        else {
            ok !$out, 'no output without verbose' or diag $out;
        }
    };
}

subtest 'build site' => sub {
    my ( $tmp, $config_fn, $config ) = build_temp_site( $SHARE_DIR );

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
    subtest 'verbose' => test_site(
        $tmp->child( 'build_site' ),
        @args,
        '-vv',
    );
};

subtest 'deploy site' => sub {
    my ( $tmp, $config_fn, $config ) = build_temp_site( $SHARE_DIR );

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
    subtest 'verbose' => test_site(
        $tmp->child( 'deploy_site' ),
        @args,
        '-vv',
    );

    subtest '--clean' => sub {
        $tmp->child( 'deploy_site', 'needs-cleaning.txt' )->spew_utf8( 'Ha Ha!' );
        subtest 'deploy with --clean' => test_site(
            $tmp->child( 'deploy_site' ),
            @args, '--clean',
        );
        ok !$tmp->child( 'deploy_site', 'needs-cleaning.txt' )->exists, 'file was cleaned';
    };
};

subtest 'special options' => sub {

    subtest 'App::Blog' => sub {

        subtest '--date' => sub {
            my $tmp = tempdir;
            $tmp->child( 'deploy' )->mkpath;
            my $conf = {
                site => {
                    class => 'Statocles::Site',
                    args => {
                        base_url => 'http://example.com',
                        deploy => $tmp->child( 'deploy' )->stringify,
                        build_store => $tmp->child( 'build' )->stringify,
                        theme => $SHARE_DIR->child( 'theme' )->stringify,
                        apps => {
                            test => {
                                '$class' => 'Statocles::App::Blog',
                                '$args' => {
                                    url_root => '/',
                                    store => $SHARE_DIR->child( 'app', 'blog' )->stringify,
                                },
                            },
                        },
                    },
                },
            };
            YAML::DumpFile( $tmp->child( 'site.yml' ), $conf );

            subtest 'build' => sub {
                my @args = (
                    '--config' => $tmp->child( 'site.yml' )->stringify,
                    'build',
                    '--date', '9999-12-31',
                );

                my ( $out, $err, $exit ) = capture { Statocles::Command->main( @args ) };
                is $exit, 0, 'exit code';
                ok !$err, "no errors/warnings on stderr" or diag $err;

                my $post = $tmp->child( 'build', '9999', '12', '31', 'forever-is-a-long-time', 'index.html' );
                ok $post->is_file, 'very far future post exists';
            };

            subtest 'deploy' => sub {
                my @args = (
                    '--config' => $tmp->child( 'site.yml' )->stringify,
                    'deploy',
                    '--date', '9999-12-31',
                );

                my ( $out, $err, $exit ) = capture { Statocles::Command->main( @args ) };
                is $exit, 0, 'exit code';
                ok !$err, "no errors/warnings on stderr" or diag $err;

                my $post = $tmp->child( 'deploy', '9999', '12', '31', 'forever-is-a-long-time', 'index.html' );
                ok $post->is_file, 'very far future post exists';
            };

        };
    };

    subtest 'Deploy::Git' => sub {
        require Statocles::Deploy::Git;
        my $git_version = Statocles::Deploy::Git->_git_version;
        if ( !$git_version ) {
            plan skip_all => 'Git not installed';
            return;
        }
        diag "Git version: $git_version";
        if ( $git_version <= 1.007002 ) {
            plan skip_all => 'Git 1.7.2 or higher required';
            return;
        }
        require Git::Repository;

        subtest '--message' => sub {
            my $tmp = tempdir;
            $tmp->child( 'deploy' )->mkpath;
            my $conf = {
                site => {
                    class => 'Statocles::Site',
                    args => {
                        base_url => 'http://example.com',
                        deploy => {
                            '$class' => 'Statocles::Deploy::Git',
                            '$args' => {
                                path => $tmp->child( 'deploy' )->stringify,
                            },
                        },
                        theme => $SHARE_DIR->child( 'theme' )->stringify,
                        apps => {
                            test => {
                                '$class' => 'TestApp',
                                '$args' => {
                                    url_root => '/',
                                    pages => [
                                        {
                                            path => '/index.html',
                                            title => 'Test Page',
                                            content => 'Test Content',
                                        },
                                    ],
                                },
                            },
                        },
                    },
                },
            };
            YAML::DumpFile( $tmp->child( 'site.yml' ), $conf );

            Git::Repository->run( init => "$tmp" );
            my $git = Git::Repository->new( work_tree => "$tmp" );
            $git->run( config => 'user.name' => 'Statocles Test User' );
            $git->run( config => 'user.email' => 'statocles@example.com' );
            $git->run( add => $tmp->child( 'site.yml' ) );
            $git->run( commit => -m => 'Add site config' );

            my @args = (
                '--config' => $tmp->child( 'site.yml' )->stringify,
                'deploy',
                '--message',
                'My custom commit message',
            );

            my ( $out, $err, $exit ) = capture { Statocles::Command->main( @args ) };
            is $exit, 0, 'exit code';
            ok !$err, "no errors/warnings on stderr" or diag $err;

            my $log = $git->run( 'log' );
            like $log, qr{My custom commit message}, 'commit message exists';
        };

        subtest '-m' => sub {
            my $tmp = tempdir;
            $tmp->child( 'deploy' )->mkpath;
            my $conf = {
                site => {
                    class => 'Statocles::Site',
                    args => {
                        base_url => 'http://example.com',
                        deploy => {
                            '$class' => 'Statocles::Deploy::Git',
                            '$args' => {
                                path => $tmp->child( 'deploy' )->stringify,
                            },
                        },
                        theme => $SHARE_DIR->child( 'theme' )->stringify,
                        apps => {
                            test => {
                                '$class' => 'TestApp',
                                '$args' => {
                                    url_root => '/',
                                    pages => [
                                        {
                                            path => '/index.html',
                                            title => 'Test Page',
                                            content => 'Test Content',
                                        },
                                    ],
                                },
                            },
                        },
                    },
                },
            };
            YAML::DumpFile( $tmp->child( 'site.yml' ), $conf );

            Git::Repository->run( init => "$tmp" );
            my $git = Git::Repository->new( work_tree => "$tmp" );
            $git->run( config => 'user.name' => 'Statocles Test User' );
            $git->run( config => 'user.email' => 'statocles@example.com' );
            $git->run( add => $tmp->child( 'site.yml' ) );
            $git->run( commit => -m => 'Add site config' );

            my @args = (
                '--config' => $tmp->child( 'site.yml' )->stringify,
                'deploy',
                '-m',
                'My custom commit message',
            );

            my ( $out, $err, $exit ) = capture { Statocles::Command->main( @args ) };
            is $exit, 0, 'exit code';
            ok !$err, "no errors/warnings on stderr" or diag $err;

            my $log = $git->run( 'log' );
            like $log, qr{My custom commit message}, 'commit message exists';
        };

    };
};


done_testing;
