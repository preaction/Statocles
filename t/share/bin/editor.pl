#!perl

# An "editor" to use to test the EDITOR environment variable
#
# If a "STATOCLES_TEST_EDITOR_CONTENT" envvar exists, the editor will replace
# the requested file with the file specified.
#
# If a "STATOCLES_TEST_EDITOR_OUTPUT" envvar exists, the editor will write a file
# with the filename on the first line, and its contents below

use strict;
use warnings;

my $ENV_OUT = "STATOCLES_TEST_EDITOR_OUTPUT";
my $ENV_IN = "STATOCLES_TEST_EDITOR_CONTENT";

my ( $file, $extra ) = @ARGV;

if ( $file eq '--exit' ) {
    exit $extra;
}
if ( $file eq '--signal' ) {
    kill $extra, $$;
}

if ( $ENV{$ENV_OUT} ) {
    open my $out_fh, '>', $ENV{$ENV_OUT} or die "Could not open $ENV{$ENV_OUT} for writing: $!";
    binmode $out_fh;
    print { $out_fh } $file, "\n";
    open my $in_fh, '<', $file or die "Could not open $file for reading: $!";
    print { $out_fh } do { local $/ = undef; <$in_fh> };
}

if ( $ENV{$ENV_IN} ) {
    open my $in_fh, '<', $ENV{$ENV_IN} or die "Could not open $ENV{$ENV_IN} for reading: $!";
    binmode $in_fh;
    open my $out_fh, '>', $file or die "Could not open $file for writing: $!";
    binmode $out_fh;
    print { $out_fh } do { local $/ = undef; <$in_fh> };
}
