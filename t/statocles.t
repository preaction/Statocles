# This test file duplicates some tests in t/command.t to ensure that
# the bin/statocles frontend's delegation to Statocles.pm
# works.
use Test::Lib;
use My::Test;
use Capture::Tiny qw( capture );
use Encode qw( encode decode );
use POSIX qw( setlocale LC_ALL LC_CTYPE );
use Mojo::Path;
use IPC::Open3;
use Symbol 'gensym';

my $BIN = path( __DIR__, '..', 'bin', 'statocles' );
my $SHARE_DIR = path( __DIR__, 'share' );
my $SITE = build_test_site;
my $FORCE_LOCALE = "en_US.UTF-8";

subtest '-h|--help' => sub {
    subtest '-h' => sub {
        my ( $out, $err, $exit ) = capture { system $^X, $BIN, '-h' };
        ok !$err, 'nothing on stderr' or diag "STDERR: $err";
        like $out, qr{statocles -h},
            'reports pod from bin/statocles, not Statocles';
        is $exit, 0;
    };
    subtest '--help' => sub {
        my ( $out, $err, $exit ) = capture { system $^X, $BIN, '--help' };
        ok !$err, 'nothing on stderr' or diag "STDERR: $err";
        like $out, qr{statocles -h},
            'reports pod from bin/statocles, not Statocles';
        is $exit, 0;
    };
};

subtest 'handle locales on ARGV and STDIN' => sub {
    my ( $tmpdir, $config_fn, $config ) = build_temp_site( $SHARE_DIR );

    local $ENV{EDITOR}; # We can't very well open vim...
    my $locale = setlocale( LC_ALL );
    diag "Current locale: $locale";
    setlocale( LC_ALL, $FORCE_LOCALE );
    local $ENV{LANG} = $FORCE_LOCALE;
    local $ENV{LC_ALL} = $FORCE_LOCALE;
    local $ENV{LC_CTYPE} = $FORCE_LOCALE;

    my $title_chars = "Test æøå";
    my $title_encoded = encode( $FORCE_LOCALE => $title_chars );
    my $content_chars = "\xa9\n";
    my $content_encoded = encode( $FORCE_LOCALE => $content_chars );
    my ( undef, undef, undef, $day, $mon, $year ) = localtime;
    my @partsfile = (
        'blog',
        sprintf( '%04i', $year + 1900 ),
        sprintf( '%02i', $mon + 1 ),
        sprintf( '%02i', $day ),
        'test-a-a-ay', # what make_slug turns that title to
        'index.markdown',
    );
    my $doc_path = $tmpdir->child( @partsfile );

    subtest 'run the command' => sub {
        my @args = ( '--config', $config_fn, qw( blog post ), $title_encoded );
        my $cwd = cwd;
        chdir $tmpdir;
        open3 my $child_in, my $child_out, (my $child_err = gensym), $^X, $BIN, @args;
        print {$child_in} $content_encoded;
        close $child_in;
        my ( $out, $err ) = do { local $/; (<$child_out>, <$child_err>) };
        chdir $cwd;
        is $err, undef, 'nothing on stderr';
        is $?, 0;
        my $decoded_out = decode( $FORCE_LOCALE => $out );
        like $decoded_out, qr{New post at: \Q$doc_path},
            'contains blog post document path';
    };

    subtest 'check the generated document' => sub {
        my $store = Statocles::Store->new( path => $tmpdir->child( 'blog' ) );
        my $doc = Statocles::Document->parse_content(
            path => path( @partsfile ).'',
            store => $store,
            content => $doc_path->slurp_utf8,
        );
        is $doc->title, $title_chars;
        is_deeply $doc->tags, [] or diag explain $doc->tags;
        is $doc->content, $content_chars;
        eq_or_diff $doc_path->slurp_utf8, <<ENDCONTENT;
---
status: published
title: $title_chars
---
\xa9
ENDCONTENT
    };
};

done_testing;
