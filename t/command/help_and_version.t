
use Test::Lib;
use My::Test;
use Capture::Tiny qw( capture );
use FindBin ();
use Statocles::Command;
my $SHARE_DIR = path( __DIR__, '..', 'share' );

subtest 'get help' => sub {
    local $0 = path( $FindBin::Bin, '..', '..', 'bin', 'statocles' )->stringify;
    subtest '-h' => sub {
        my ( $out, $err, $exit ) = capture { Statocles::Command->main( '-h' ) };
        ok !$err, 'nothing on stderr' or diag "STDERR: $err";
        like $out, qr{statocles -h},
            'reports pod from bin/statocles, not Statocles::Command';
        is $exit, 0;
    };
    subtest '--help' => sub {
        my ( $out, $err, $exit ) = capture { Statocles::Command->main( '--help' ) };
        ok !$err, 'nothing on stderr' or diag "STDERR: $err";
        like $out, qr{statocles -h},
            'reports pod from bin/statocles, not Statocles::Command';
        is $exit, 0;
    };
};

subtest 'get version' => sub {
    local $Statocles::Command::VERSION = '1.00';
    my ( $output, $stderr, $exit ) = capture { Statocles::Command->main( '--version' ) };
    is $exit, 0;
    ok !$stderr, 'stderr is empty' or diag "STDERR: $stderr";
    is $output, "Statocles version 1.00 (Perl $^V)\n";

    subtest '-v (verbose) and no args shows version' => sub {
        my ( $output, $stderr, $exit ) = capture { Statocles::Command->main( '-v' ) };
        is $exit, 0;
        ok !$stderr, 'stderr is empty' or diag "STDERR: $stderr";
        is $output, "Statocles version 1.00 (Perl $^V)\n";
    };
};

done_testing;
