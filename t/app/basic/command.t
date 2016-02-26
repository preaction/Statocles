
use Test::Lib;
use My::Test;
use Capture::Tiny qw( capture );
use Statocles::App::Basic;
my $SHARE_DIR = path( __DIR__ )->parent->parent->child( 'share' );

my $site = build_test_site(
    theme => $SHARE_DIR->child( 'theme' ),
);

# We need an app we can edit
my $tmpdir = tempdir;
$tmpdir->child( 'basic' )->mkpath;

my $app = Statocles::App::Basic->new(
    store => $tmpdir->child( 'basic' ),
    url_root => '/basic',
    site => $site,
);

subtest 'errors' => sub {
    subtest 'invalid command' => sub {
        my @args = qw( page foo );
        my ( $out, $err, $exit ) = capture { $app->command( @args ) };
        ok !$out, 'app error is on stderr' or diag $out;
        isnt $exit, 0;
        like $err, qr{\QERROR: Unknown command "foo"}, "contains error message";
        like $err, qr{\Qpage edit <path> -- Edit a page, creating it if necessary},
            'contains app usage information';
    };

    subtest 'missing command' => sub {
        my @args = qw( page );
        my ( $out, $err, $exit ) = capture { $app->command( @args ) };
        ok !$out, 'app error is on stderr' or diag $out;
        isnt $exit, 0;
        like $err, qr{\QERROR: Missing command}, "contains error message";
        like $err, qr{\Qpage edit <path> -- Edit a page, creating it if necessary},
            'contains app usage information';
    };
};

subtest 'help' => sub {
    my @args = qw( page help );
    my ( $out, $err, $exit ) = capture { $app->command( @args ) };
    ok !$err, 'app help is on stdout';
    is $exit, 0;
    like $out, qr{\Qpage edit <path> -- Edit a page, creating it if necessary},
        'contains app usage information';
};

subtest 'edit' => sub {

    subtest 'create new page' => sub {

        subtest 'full path' => sub {
            local $ENV{EDITOR} = "$^X " . $SHARE_DIR->child( 'bin', 'editor.pl' );
            local $ENV{STATOCLES_TEST_EDITOR_CONTENT} = "".$SHARE_DIR->child(qw( app basic index.markdown ));

            my $doc_path = $tmpdir->child( "basic", "resume.markdown" );

            subtest 'run the command' => sub {
                my @args = qw( page edit /resume.markdown );
                my ( $out, $err, $exit ) = capture { $app->command( @args ) };
                ok !$err, 'nothing on stderr' or diag $err;
                is $exit, 0;
                ok !$out, 'EDITOR silences STDOUT' or diag $out;
            };

            subtest 'check the generated document' => sub {
                eq_or_diff $doc_path->slurp, $SHARE_DIR->child(qw( app basic index.markdown ))->slurp;
            };
        };

        subtest 'path without extension' => sub {
            local $ENV{EDITOR}; # Test without EDITOR
            my $doc_path = $tmpdir->child( "basic", "resume", "index.markdown" );

            subtest 'run the command' => sub {
                my @args = qw( page edit /resume );
                my ( $out, $err, $exit ) = capture { $app->command( @args ) };
                ok !$err, 'nothing on stdout';
                is $exit, 0;
                like $out, qr{New page at: \Q$doc_path},
                    'no EDITOR has path on STDOUT';
            };

            subtest 'check the generated document' => sub {
                my $path = $doc_path->relative( $tmpdir->child('basic') );
                my $doc = $app->store->read_document( $path );
                cmp_deeply $doc, Statocles::Document->new(
                    path => $path,
                    title => '',
                    content => <<'ENDMARKDOWN',
Markdown content goes here.
ENDMARKDOWN
                    store => $app->store,
                );
                eq_or_diff $doc_path->slurp, <<ENDCONTENT;
---
title: ''
---
Markdown content goes here.
ENDCONTENT
            };
        };

        subtest 'content from STDIN' => sub {
            subtest 'without frontmatter' => sub {
                local $ENV{EDITOR}; # We can't very well open vim...
                my $doc_path = $tmpdir->child( "basic", "home.markdown" );

                subtest 'run the command' => sub {
                    diag -t *STDIN
                        ? "Before test: STDIN is interactive"
                        : "Before test: STDIN is not interactive";

                    open my $stdin, '<', \"This is content from STDIN\n";
                    local *STDIN = $stdin;

                    my @args = qw( page edit home.markdown );
                    my ( $out, $err, $exit ) = capture { $app->command( @args ) };
                    ok !$err, 'nothing on stdout' or diag $err;
                    is $exit, 0;
                    like $out, qr{New page at: \Q$doc_path},
                        'contains new document path';

                    if ( -e '/dev/tty' ) {
                        diag -t *STDIN
                            ? "After test: STDIN is interactive"
                            : "After Test: STDIN is not interactive";
                    }
                };

                subtest 'check the generated document' => sub {
                    my $path = $doc_path->relative( $tmpdir->child('basic') );
                    my $doc = $app->store->read_document( $path );
                    cmp_deeply $doc, Statocles::Document->new(
                        path => $path,
                        title => '',
                        content => <<'ENDMARKDOWN',
This is content from STDIN
ENDMARKDOWN
                        store => $app->store,
                    );
                };
            };

            subtest 'with frontmatter' => sub {
                local $ENV{EDITOR}; # We can't very well open vim...
                my $doc_path = $tmpdir->child( "basic", "frontmatter", "index.markdown" );

                subtest 'run the command' => sub {
                    diag -t *STDIN
                        ? "Before test: STDIN is interactive"
                        : "Before test: STDIN is not interactive";

                    open my $stdin, '<', \<<ENDSTDIN;
---
title: This is Frontmatter
tags: one, two
---
This is content from STDIN
ENDSTDIN
                    local *STDIN = $stdin;

                    my @args = qw( page edit frontmatter );
                    my ( $out, $err, $exit ) = capture { $app->command( @args ) };
                    ok !$err, 'nothing on stdout' or diag $err;
                    is $exit, 0;
                    like $out, qr{New page at: \Q$doc_path},
                        'contains new document path';

                    if ( -e '/dev/tty' ) {
                        diag -t *STDIN
                            ? "After test: STDIN is interactive"
                            : "After Test: STDIN is not interactive";
                    }
                };

                subtest 'check the generated document' => sub {
                    my $path = $doc_path->relative( $tmpdir->child('basic') );
                    my $doc = $app->store->read_document( $path );
                    cmp_deeply $doc, Statocles::Document->new(
                        path => $path,
                        title => 'This is Frontmatter',
                        tags => [qw( one two )],
                        content => <<'ENDMARKDOWN',
This is content from STDIN
ENDMARKDOWN
                        store => $app->store,
                    );
                };
            };

        };

    };
};

done_testing;
