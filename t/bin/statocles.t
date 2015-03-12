
# This test file duplicates some tests in t/command.t to ensure that
# the bin/statocles frontend's delegation to Statocles::Command
# works.

use Statocles::Base 'Test';
use Capture::Tiny qw( capture );
use Encode qw( encode decode );
use POSIX qw( setlocale LC_ALL LC_CTYPE );
my $BIN = path( __DIR__, '..', '..', 'bin', 'statocles' );
my $SHARE_DIR = path( __DIR__, '..', 'share' );
my $SITE = build_test_site;

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

subtest 'handle locales on ARGV and STDIN' => sub {
    my ( $tmpdir, $config_fn, $config ) = build_temp_site( $SHARE_DIR );

    local $ENV{EDITOR}; # We can't very well open vim...
    my $locale = setlocale( LC_ALL );
    diag "Current locale: $locale";
    setlocale( LC_ALL, "en_US.ISO8859-1" );
    local $ENV{LANG} = "en_US.ISO8859-1";
    local $ENV{LC_ALL} = "en_US.ISO8859-1";
    local $ENV{LC_CTYPE} = "en_US.ISO8859-1";

    my $title = "\xa9 snowman";
    my ( undef, undef, undef, $day, $mon, $year ) = localtime;
    my $doc_path = $tmpdir->child(
        'blog',
        sprintf( '%04i', $year + 1900 ),
        sprintf( '%02i', $mon + 1 ),
        sprintf( '%02i', $day ),
        $title,
        'index.markdown',
    );

    subtest 'run the command' => sub {
        my $content = encode( "en_US.ISO8859-1" => "\xa9\n" );
        open my $stdin, '<', \$content;
        local *STDIN = $stdin;

        my @args = ( '--config', $config_fn, qw( blog post ), encode( "en_US.ISO8859-1" => $title ) );
        my $cwd = cwd;
        chdir $tmpdir;
        my ( $out, $err, $exit ) = capture { system $^X, $BIN, @args };
        chdir $cwd;
        ok !$err, 'nothing on stderr' or diag $err;
        is $exit, 0;
        my $decoded_out = decode( 'en_US.ISO8859-1' => $out );
        like $decoded_out, qr{New post at: \Q$doc_path},
            'contains blog post document path';
    };

    subtest 'check the generated document' => sub {
        my $store = Statocles::Store::File->new( path => $tmpdir->child( 'blog' ) );
        my $doc = $store->read_document( $doc_path->relative( $tmpdir->child( 'blog' ) ) );
        cmp_deeply $doc, {
            title => $title,
            tags => undef,
            content => <<ENDMARKDOWN,
\xa9
ENDMARKDOWN
        };
        eq_or_diff $doc_path->slurp_utf8, <<ENDCONTENT;
---
tags: ~
title: \xa9 snowman
---
\xa9
ENDCONTENT
    };
};

done_testing;
