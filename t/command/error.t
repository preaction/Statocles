
use Test::Lib;
use My::Test;
use Capture::Tiny qw( capture );
use FindBin ();
use Statocles::Command;
my $SHARE_DIR = path( __DIR__, '..', 'share' );

my ( $tmp, $config_fn, $config ) = build_temp_site( $SHARE_DIR );

local $0 = path( $FindBin::Bin, '..', '..', 'bin', 'statocles' )->stringify;

subtest 'no command specified' => sub {
    my $cwd = cwd;
    chdir $tmp;

    my ( $out, $err, $exit ) = capture { Statocles::Command->main };
    ok !$out, 'nothing on stdout' or diag "STDOUT: $out";
    like $err, qr{ERROR: Missing command};
    like $err, qr{statocles -h},
        'reports pod from bin/statocles, not Statocles::Command';
    isnt $exit, 0;

    chdir $cwd;
};

subtest 'unknown command specified' => sub {
    my $cwd = cwd;
    chdir $tmp;

    my ( $out, $err, $exit ) = capture { Statocles::Command->main( 'daemin' ) };
    ok !$out, 'nothing on stdout' or diag "STDOUT: $out";
    like $err, qr{ERROR: Unknown command or app 'daemin'};
    like $err, qr{statocles -h},
        'reports pod from bin/statocles, not Statocles::Command';
    isnt $exit, 0;

    chdir $cwd;
};


subtest 'config file missing' => sub {
    subtest 'no site.yml found' => sub {
        my $tempdir = tempdir;
        my $cwd = cwd;
        chdir $tempdir;

        my ( $out, $err, $exit ) = capture { Statocles::Command->main( 'build' ) };
        ok !$out, 'nothing on stdout' or diag "STDOUT: $out";
        like $err, qr{\QERROR: Could not find config file "site.yml"}
            or diag $err;
        isnt $exit, 0;

        chdir $cwd;
    };

    subtest 'custom config file missing' => sub {
        my $cwd = cwd;
        chdir $tmp;

        my ( $out, $err, $exit ) = capture {
            Statocles::Command->main( '--config', 'DOES_NOT_EXIST.yml', 'build' )
        };
        ok !$out, 'nothing on stdout' or diag "STDOUT: $out";
        like $err, qr{\QERROR: Could not find config file "DOES_NOT_EXIST.yml"}
            or diag $err;
        isnt $exit, 0;

        chdir $cwd;
    };

};

subtest 'site object missing' => sub {
    subtest 'no site found' => sub {
        my $tempdir = tempdir;
        YAML::DumpFile( $tempdir->child( 'config.yml' ), { test => { } } );
        my $cwd = cwd;
        chdir $tempdir;

        my ( $out, $err, $exit ) = capture {
            Statocles::Command->main( '--config', 'config.yml', 'build' )
        };
        ok !$out, 'nothing on stdout' or diag "STDOUT: $out";
        like $err, qr{\QERROR: Could not find site named "site" in config file "config.yml"}
            or diag $err;
        isnt $exit, 0;

        chdir $cwd;
    };

    subtest 'custom site missing' => sub {
        my $cwd = cwd;
        chdir $tmp;

        my ( $out, $err, $exit ) = capture {
            Statocles::Command->main( '--site', 'DOES_NOT_EXIST', 'build' )
        };
        ok !$out, 'nothing on stdout' or diag "STDOUT: $out";
        like $err, qr{\QERROR: Could not find site named "DOES_NOT_EXIST" in config file "site.yml"}
            or diag $err;
        isnt $exit, 0;

        chdir $cwd;
    };

};

subtest 'site config broken' => sub {
    subtest 'reference missing' => sub {
        my $config = $SHARE_DIR->child( config => 'bad_ref.yml' );

        my ( $out, $err, $exit ) = capture {
            Statocles::Command->main( '--config', "$config", 'build' )
        };
        ok !$out, 'nothing on stdout' or diag "STDOUT: $out";
        like $err, qr{\QERROR: Could not create site object "site" in config file "$config": \E.*missing_object}
            or diag $err;
        isnt $exit, 0;
    };

    subtest 'bad character in YAML' => sub {
        if ( !eval { require YAML::XS; 1 } && eval { require YAML::Syck; 1 } ) {
            pass 'SKIP: YAML::Syck will cause this test to fail';
            return;
        }

        my $config = $SHARE_DIR->child( config => 'bad_char.yml' );

        my ( $out, $err, $exit ) = capture {
            Statocles::Command->main( '--config', "$config", 'build' )
        };
        ok !$out, 'nothing on stdout' or diag "STDOUT: $out";
        like $err, qr{ERROR: Could not load config file "$config"[.] Check that you are not using tabs for indentation[.] For more information, run with the "--verbose" option or check Statocles::Help::Error.}
            or diag $err;
        isnt $exit, 0;

        subtest '--verbose shows raw error message' => sub {
            my ( $out, $err, $exit ) = capture {
                Statocles::Command->main( '-v', '--config', "$config", 'build' )
            };
            ok !$out, 'nothing on stdout' or diag "STDOUT: $out";
            like $err, qr{ERROR: Could not load config file "$config"[.] Check that you are not using tabs for indentation[.] For more information, check Statocles::Help::Error[.].+Raw error: Could not load container file}s
                or diag $err;
            isnt $exit, 0;
        };
    };

    subtest 'bad indenting in YAML' => sub {
        my $config = $SHARE_DIR->child( config => 'bad_indent.yml' );

        my ( $out, $err, $exit ) = capture {
            Statocles::Command->main( '--config', "$config", 'build' )
        };
        ok !$out, 'nothing on stdout' or diag "STDOUT: $out";
        like $err, qr{ERROR: Could not load config file "$config"[.] Check your indentation[.] For more information, run with the "--verbose" option or check Statocles::Help::Error[.]}
            or diag $err;
        isnt $exit, 0;

        subtest '--verbose shows raw error message' => sub {
            my ( $out, $err, $exit ) = capture {
                Statocles::Command->main( '-v', '--config', "$config", 'build' )
            };
            ok !$out, 'nothing on stdout' or diag "STDOUT: $out";
        like $err, qr{ERROR: Could not load config file "$config"[.] Check your indentation[.] For more information, check Statocles::Help::Error[.].+Raw error: Could not load container file}s
                or diag $err;
            isnt $exit, 0;
        };
    };

    subtest 'missing required arguments' => sub {
        my $config = $SHARE_DIR->child( config => 'missing_arg.yml' );

        my ( $out, $err, $exit ) = capture {
            Statocles::Command->main( '--config', "$config", 'build' )
        };
        ok !$out, 'nothing on stdout' or diag "STDOUT: $out";
        like $err, qr{ERROR: Could not create site object "site" in config file "$config": Missing required arguments:}
            or diag $err;
        isnt $exit, 0;
    };
};

done_testing;
