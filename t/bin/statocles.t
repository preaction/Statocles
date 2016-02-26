
# This test file duplicates some tests in t/command.t to ensure that
# the bin/statocles frontend's delegation to Statocles::Command
# works.
use Test::Lib;
use My::Test;
my $BIN = path( __DIR__, '..', '..', 'bin', 'statocles' );
use Capture::Tiny qw( capture );

subtest '-h|--help' => sub {
    subtest '-h' => sub {
        my ( $out, $err, $exit ) = capture { system $^X, $BIN, '-h' };
        ok !$err, 'nothing on stderr' or diag "STDERR: $err";
        like $out, qr{statocles -h},
            'reports pod from bin/statocles, not Statocles::Command';
        is $exit, 0;
    };
    subtest '--help' => sub {
        my ( $out, $err, $exit ) = capture { system $^X, $BIN, '--help' };
        ok !$err, 'nothing on stderr' or diag "STDERR: $err";
        like $out, qr{statocles -h},
            'reports pod from bin/statocles, not Statocles::Command';
        is $exit, 0;
    };
};

done_testing;
