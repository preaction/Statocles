
use Test::Lib;
use My::Test;
use Capture::Tiny qw( capture );
use Statocles::App::Blog;
my $SHARE_DIR = path( __DIR__ )->parent->parent->child( 'share' );

my $site = build_test_site(
    theme => $SHARE_DIR->child( 'theme' ),
);

# We need an app we can edit
my $tmpdir = tempdir;
$tmpdir->child( 'blog' )->mkpath;

my $app = Statocles::App::Blog->new(
    store => $tmpdir->child( 'blog' ),
    url_root => '/blog',
    site => $site,
);

subtest 'errors' => sub {
    subtest 'invalid command' => sub {
        my @args = qw( blog foo );
        my ( $out, $err, $exit ) = capture { $app->command( @args ) };
        ok !$out, 'blog error is on stderr' or diag $out;
        isnt $exit, 0;
        like $err, qr{\QERROR: Unknown command "foo"}, "contains error message";
        like $err, qr{\Qblog post [--date YYYY-MM-DD] <title> -- Create a new blog post},
            'contains blog usage information';
    };

    subtest 'missing command' => sub {
        my @args = qw( blog );
        my ( $out, $err, $exit ) = capture { $app->command( @args ) };
        ok !$out, 'blog error is on stderr' or diag $out;
        isnt $exit, 0;
        like $err, qr{\QERROR: Missing command}, "contains error message";
        like $err, qr{\Qblog post [--date YYYY-MM-DD] <title> -- Create a new blog post},
            'contains blog usage information';
    };
};

subtest 'help' => sub {
    my @args = qw( blog help );
    my ( $out, $err, $exit ) = capture { $app->command( @args ) };
    ok !$err, 'blog help is on stdout';
    is $exit, 0;
    like $out, qr{\Qblog post [--date YYYY-MM-DD] <title> -- Create a new blog post},
        'contains blog help information';
};

subtest 'post' => sub {
    subtest 'create new post' => sub {
        subtest 'without $EDITOR, title is required' => sub {
            local $ENV{EDITOR};
            my @args = qw( blog post );
            my ( $out, $err, $exit ) = capture { $app->command( @args ) };
            like $err, qr{Title is required when \$EDITOR is not set};
            like $err, qr{blog post <title>};
            isnt $exit, 0;
        };

        subtest 'default document' => sub {
            local $ENV{EDITOR}; # We can't very well open vim...
            my ( undef, undef, undef, $day, $mon, $year ) = localtime;
            my $doc_path = $tmpdir->child(
                'blog',
                sprintf( '%04i', $year + 1900 ),
                sprintf( '%02i', $mon + 1 ),
                sprintf( '%02i', $day ),
                'this-is-a-title',
                'index.markdown',
            );

            subtest 'run the command' => sub {
                my @args = qw( blog post This is a Title );
                my ( $out, $err, $exit ) = capture { $app->command( @args ) };
                ok !$err, 'nothing on stdout';
                is $exit, 0;
                like $out, qr{New post at: \Q$doc_path},
                    'contains blog post document path';
            };

            subtest 'check the generated document' => sub {
                my $path = $doc_path->relative( $tmpdir->child('blog') );
                my $doc = $app->store->read_document( $path );
                cmp_deeply $doc, Statocles::Document->new(
                    path => $path,
                    title => 'This is a Title',
                    tags => undef,
                    content => <<'ENDMARKDOWN',
Markdown content goes here.
ENDMARKDOWN
                    store => $app->store,
                );
                eq_or_diff $doc_path->slurp, <<ENDCONTENT;
---
tags: ~
title: This is a Title
---
Markdown content goes here.
ENDCONTENT
            };
        };

        subtest 'special characters in title' => sub {
            local $ENV{EDITOR}; # We can't very well open vim...
            my ( undef, undef, undef, $day, $mon, $year ) = localtime;
            my $doc_path = $tmpdir->child(
                'blog',
                sprintf( '%04i', $year + 1900 ),
                sprintf( '%02i', $mon + 1 ),
                sprintf( '%02i', $day ),
                'special-characters-a-retrospective-2-the-return',
                'index.markdown',
            );

            subtest 'run the command' => sub {
                my @args = qw{ blog post Special Characters: A Retrospective (2) - The Return};
                my ( $out, $err, $exit ) = capture { $app->command( @args ) };
                ok !$err, 'nothing on stdout';
                is $exit, 0;
                like $out, qr{New post at: \Q$doc_path},
                    'contains blog post document path';
            };

            subtest 'check the generated document' => sub {
                my $path = $doc_path->relative( $tmpdir->child('blog') );
                my $doc = $app->store->read_document( $path );
                cmp_deeply $doc, Statocles::Document->new(
                    path => $path,
                    title => 'Special Characters: A Retrospective (2) - The Return',
                    tags => undef,
                    content => <<'ENDMARKDOWN',
Markdown content goes here.
ENDMARKDOWN
                    store => $app->store,
                );
                eq_or_diff $doc_path->slurp, <<ENDCONTENT;
---
tags: ~
title: 'Special Characters: A Retrospective (2) - The Return'
---
Markdown content goes here.
ENDCONTENT
            };
        };

        subtest 'custom date' => sub {
            local $ENV{EDITOR}; # We can't very well open vim...

            my $doc_path = $tmpdir->child(
                'blog', '2014', '04', '01', 'this-is-a-title', 'index.markdown',
            );

            subtest 'run the command' => sub {
                my @args = qw( blog post --date 2014-4-1 This is a Title );
                my ( $out, $err, $exit ) = capture { $app->command( @args ) };
                ok !$err, 'nothing on stdout' or diag $err;
                is $exit, 0;
                like $out, qr{New post at: \Q$doc_path},
                    'contains blog post document path';
            };

            subtest 'check the generated document' => sub {
                my $path = $doc_path->relative( $tmpdir->child( 'blog' ) );
                my $doc = $app->store->read_document( $path );
                cmp_deeply $doc, Statocles::Document->new(
                    path => $path,
                    title => 'This is a Title',
                    tags => undef,
                    content => <<'ENDMARKDOWN',
Markdown content goes here.
ENDMARKDOWN
                    store => $app->store,
                );
                eq_or_diff $doc_path->slurp, <<ENDCONTENT;
---
tags: ~
title: This is a Title
---
Markdown content goes here.
ENDCONTENT
            };
        };

        subtest 'content from STDIN' => sub {
            subtest 'without frontmatter' => sub {
                local $ENV{EDITOR}; # We can't very well open vim...

                my ( undef, undef, undef, $day, $mon, $year ) = localtime;
                my $doc_path = $tmpdir->child(
                    'blog',
                    sprintf( '%04i', $year + 1900 ),
                    sprintf( '%02i', $mon + 1 ),
                    sprintf( '%02i', $day ),
                    'this-is-a-title-for-stdin',
                    'index.markdown',
                );

                subtest 'run the command' => sub {
                    diag -t *STDIN
                        ? "Before test: STDIN is interactive"
                        : "Before test: STDIN is not interactive";

                    open my $stdin, '<', \"This is content from STDIN\n";
                    local *STDIN = $stdin;

                    my @args = qw( blog post This is a Title for stdin );
                    my ( $out, $err, $exit ) = capture { $app->command( @args ) };
                    ok !$err, 'nothing on stdout' or diag $err;
                    is $exit, 0;
                    like $out, qr{New post at: \Q$doc_path},
                        'contains blog post document path';

                    if ( -e '/dev/tty' ) {
                        diag -t *STDIN
                            ? "After test: STDIN is interactive"
                            : "After Test: STDIN is not interactive";
                    }
                };

                subtest 'check the generated document' => sub {
                    my $path = $doc_path->relative( $tmpdir->child('blog') );
                    my $doc = $app->store->read_document( $path );
                    cmp_deeply $doc, Statocles::Document->new(
                        path => $path,
                        title => 'This is a Title for stdin',
                        tags => undef,
                        content => <<'ENDMARKDOWN',
This is content from STDIN
ENDMARKDOWN
                        store => $app->store,
                    );
                };
            };

            subtest 'author option' => sub {
                local $ENV{EDITOR}; # We can't very well open vim...

                my ( undef, undef, undef, $day, $mon, $year ) = localtime;
                my $doc_path = $tmpdir->child(
                    'blog',
                    sprintf( '%04i', $year + 1900 ),
                    sprintf( '%02i', $mon + 1 ),
                    sprintf( '%02i', $day ),
                    'this-is-a-title-for-stdin',
                    'index.markdown',
                );

                subtest 'run the command' => sub {
                    diag -t *STDIN
                        ? "Before test: STDIN is interactive"
                        : "Before test: STDIN is not interactive";

                    open my $stdin, '<', \"This is content from STDIN\n";
                    local *STDIN = $stdin;

                    my @args = qw( blog post --author iasimov This is a Title for stdin );
                    my ( $out, $err, $exit ) = capture { $app->command( @args ) };
                    ok !$err, 'nothing on stdout' or diag $err;
                    is $exit, 0;
                    like $out, qr{New post at: \Q$doc_path},
                        'contains blog post document path';

                    if ( -e '/dev/tty' ) {
                        diag -t *STDIN
                            ? "After test: STDIN is interactive"
                            : "After Test: STDIN is not interactive";
                    }
                };

                subtest 'check the generated document' => sub {
                    my $path = $doc_path->relative( $tmpdir->child('blog') );
                    my $doc = $app->store->read_document( $path );
                    cmp_deeply $doc, Statocles::Document->new(
                        path => $path,
                        title => 'This is a Title for stdin',
                        author => 'iasimov',
                        tags => undef,
                        content => <<'ENDMARKDOWN',
This is content from STDIN
ENDMARKDOWN
                        store => $app->store,
                    );
                };
            };

            subtest 'with frontmatter' => sub {
                local $ENV{EDITOR}; # We can't very well open vim...

                my ( undef, undef, undef, $day, $mon, $year ) = localtime;
                my $doc_path = $tmpdir->child(
                    'blog',
                    sprintf( '%04i', $year + 1900 ),
                    sprintf( '%02i', $mon + 1 ),
                    sprintf( '%02i', $day ),
                    'this-is-frontmatter',
                    'index.markdown',
                );

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

                    my @args = qw( blog post );
                    my ( $out, $err, $exit ) = capture { $app->command( @args ) };
                    ok !$err, 'nothing on stdout' or diag $err;
                    is $exit, 0;
                    like $out, qr{New post at: \Q$doc_path},
                        'contains blog post document path';

                    if ( -e '/dev/tty' ) {
                        diag -t *STDIN
                            ? "After test: STDIN is interactive"
                            : "After Test: STDIN is not interactive";
                    }
                };

                subtest 'check the generated document' => sub {
                    my $path = $doc_path->relative( $tmpdir->child('blog') );
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


        subtest 'title change creates different folder' => sub {
            local $ENV{EDITOR} = "$^X " . $SHARE_DIR->child( 'bin', 'editor.pl' );
            local $ENV{STATOCLES_TEST_EDITOR_CONTENT} = "".$SHARE_DIR->child(qw( app blog draft a-draft-post.markdown ));

            my ( undef, undef, undef, $day, $mon, $year ) = localtime;
            my $doc_path = $tmpdir->child(
                'blog',
                sprintf( '%04i', $year + 1900 ),
                sprintf( '%02i', $mon + 1 ),
                sprintf( '%02i', $day ),
                'a-draft',
                'index.markdown',
            );

            subtest 'run the command' => sub {
                my @args = qw( blog post );
                my ( $out, $err, $exit ) = capture { $app->command( @args ) };
                ok !$err, 'nothing on stdout' or diag $err;
                is $exit, 0;
                like $out, qr{New post at: \Q$doc_path},
                    'contains blog post document path';
            };

            subtest 'check the generated document' => sub {
                my $path = $doc_path->relative( $tmpdir->child('blog') );
                my $doc = $app->store->read_document( $path );
                cmp_deeply $doc, Statocles::Document->new(
                    path => $path,
                    title => 'A Draft',
                    author => 'preaction',
                    date => DateTimeObj->coerce( '2014-06-21 00:06:00' ),
                    content => <<'ENDMARKDOWN',
Draft body content
ENDMARKDOWN
                    store => $app->store,
                );

                ok !$doc_path->parent->parent->child( 'new-post' )->exists, 'new-post dir is cleaned up';
            };
        };

    };
};

done_testing;
