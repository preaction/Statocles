
use Statocles::Base 'Test';
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
                my $doc = $app->store->read_document( $doc_path->relative( $tmpdir->child('blog') ) );
                cmp_deeply $doc, {
                    title => 'This is a Title',
                    tags => undef,
                    last_modified => isa( 'Time::Piece' ),
                    content => <<'ENDMARKDOWN',
Markdown content goes here.
ENDMARKDOWN
                };
                my $dt_str = $doc->{last_modified}->strftime( '%Y-%m-%d %H:%M:%S' );
                eq_or_diff $doc_path->slurp, <<ENDCONTENT;
---
last_modified: $dt_str
tags: ~
title: This is a Title
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
                ok !$err, 'nothing on stdout';
                is $exit, 0;
                like $out, qr{New post at: \Q$doc_path},
                    'contains blog post document path';
            };

            subtest 'check the generated document' => sub {
                my $doc = $app->store->read_document( $doc_path->relative( $tmpdir->child( 'blog' ) ) );
                cmp_deeply $doc, {
                    title => 'This is a Title',
                    tags => undef,
                    last_modified => isa( 'Time::Piece' ),
                    content => <<'ENDMARKDOWN',
Markdown content goes here.
ENDMARKDOWN
                };
                my $dt_str = $doc->{last_modified}->strftime( '%Y-%m-%d %H:%M:%S' );
                eq_or_diff $doc_path->slurp, <<ENDCONTENT;
---
last_modified: $dt_str
tags: ~
title: This is a Title
---
Markdown content goes here.
ENDCONTENT
            };
        };

        subtest 'content from STDIN' => sub {
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
                ok !$err, 'nothing on stdout';
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
                my $doc = $app->store->read_document( $doc_path->relative( $tmpdir->child('blog') ) );
                cmp_deeply $doc, {
                    title => 'This is a Title for stdin',
                    tags => undef,
                    last_modified => isa( 'Time::Piece' ),
                    content => <<'ENDMARKDOWN',
This is content from STDIN
ENDMARKDOWN
                };
            };
        };

    };
};

done_testing;
