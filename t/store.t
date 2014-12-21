
use Statocles::Base 'Test';
my $SHARE_DIR = path( __DIR__, 'share' );
$Statocles::SITE = Statocles::Site->new( build_store => '.' );

use Statocles::Store;
use Statocles::Page::Document;
use File::Copy::Recursive qw( dircopy );
use Capture::Tiny qw( capture );

my $DT_FORMAT = '%Y-%m-%d %H:%M:%S';

my @exp_docs = (
    Statocles::Document->new(
        path => '/required.yml',
        title => 'Required Document',
        author => 'preaction',
        content => "No optional things in here, at all!\n",
    ),

    Statocles::Document->new(
        path => '/datetime.yml',
        title => 'Datetime Document',
        author => 'preaction',
        last_modified => Time::Piece->strptime( '2014-04-30 15:34:32', $DT_FORMAT ),
        content => "Parses date/time for last_modified\n",
    ),

    Statocles::Document->new(
        path => '/date.yml',
        title => 'Date Document',
        author => 'preaction',
        last_modified => Time::Piece->strptime( '2014-04-30', '%Y-%m-%d' ),
        content => "Parses date only for last_modified\n",
    ),

    Statocles::Document->new(
        path => '/links/crosspost_single.yml',
        title => 'Linked Document',
        author => 'preaction',
        content => "This document has a single crosspost link\n",
        links => {
            crosspost => [
                {
                    title => 'blogs.perl.org',
                    href => 'http://blogs.perl.org/preaction/404.html',
                },
            ],
        },
    ),

    Statocles::Document->new(
        path => '/tags/single.yml',
        title => 'Tagged (Single) Document',
        author => 'preaction',
        tags => [qw( single )],
        content => "This document has a single tag\n",
    ),

    Statocles::Document->new(
        path => '/tags/array.yml',
        title => 'Tagged (Array) Document',
        author => 'preaction',
        tags => [ 'multiple', 'tags', 'in an', 'array' ],
        content => "This document has multiple tags in an array\n",
    ),

    Statocles::Document->new(
        path => '/tags/comma.yml',
        title => 'Tagged (Comma) Document',
        author => 'preaction',
        tags => [ "multiple", "tags", "separated by", "commas" ],
        content => "This document has multiple tags separated by commas\n",
    ),

);

subtest 'constructor' => sub {
    test_constructor(
        'Statocles::Store',
        required => {
            path => $SHARE_DIR->child( qw( store docs ) ),
        },
    );

    subtest 'path must exist and be a directory' => sub {
        throws_ok {
            Statocles::Store->new(
                path => $SHARE_DIR->child( qw( DOES_NOT_EXIST ) ),
            );
        } qr{Store path '[^']+DOES_NOT_EXIST' does not exist};

        throws_ok {
            Statocles::Store->new(
                path => $SHARE_DIR->child( qw( store docs required.yml ) ),
            );
        } qr{Store path '[^']+required\.yml' is not a directory};

    };
};

subtest 'read documents' => sub {
    my $store = Statocles::Store->new(
        path => $SHARE_DIR->child( qw( store docs ) ),
    );
    cmp_deeply $store->documents, bag( @exp_docs ) or diag explain $store->documents;

    subtest 'clear documents' => sub {
        # Edit the document
        $store->documents->[0]->title( 'This is a new title' );
        # Clear all the documents
        $store->clear;
        # Re-read them from disk
        cmp_deeply $store->documents, bag( @exp_docs ) or diag explain $store->documents;
    };

    subtest 'read with relative directory' => sub {
        my $cwd = cwd;
        chdir $SHARE_DIR;
        my $store = Statocles::Store->new(
            path => 'store/docs',
        );
        cmp_deeply $store->documents, bag( @exp_docs );
        chdir $cwd;
    };

    subtest 'path that has regex-special characters inside' => sub {
        my $tmpdir = tempdir;
        my $baddir = $tmpdir->child( '[regex](name).dir' );
        dircopy $SHARE_DIR->child( qw( store docs ) )->stringify, "$baddir";
        my $store = Statocles::Store->new(
            path => $baddir,
        );
        cmp_deeply $store->documents, bag( @exp_docs );
    };

    subtest 'bad documents' => sub {
        subtest 'invalid yaml' => sub {
            my $store = Statocles::Store->new(
                path => $SHARE_DIR->child( qw( store error bad-yaml ) ),
            );
            throws_ok { $store->documents } qr{Error parsing YAML in};
        };

        subtest 'invalid date/time' => sub {
            my $store = Statocles::Store->new(
                path => $SHARE_DIR->child( qw( store error bad-dates ) ),
            );
            throws_ok { $store->documents }
                qr{Could not parse last_modified '11/12/2014'[.] Does not match '\Q$DT_FORMAT\E' or '%Y-%m-%d'};
        };
    };

    subtest 'write document' => sub {
        no warnings 'once';
        local $YAML::Indent = 4; # Ensure our test output matches our indentation level
        my $tmpdir = tempdir;
        my $store = Statocles::Store->new(
            path => $tmpdir,
        );
        my $tp = Time::Piece->strptime( '2014-06-05 00:00:00', $DT_FORMAT );
        my $dt = $tp->strftime( '%Y-%m-%d %H:%M:%S' );
        my $doc = {
            foo => 'bar',
            content => "# \x{2603} This is some content\n\nAnd a paragraph\n",
            tags => [ 'one', 'two and three', 'four' ],
            last_modified => $tp,
        };

        subtest 'disallow absolute paths' => sub {
            my $path = rootdir->child( 'example.yml' );
            throws_ok { $store->write_document( $path => $doc ) }
                qr{Cannot write document '$path': Path must not be absolute};
        };

        subtest 'simple path' => sub {
            my @warnings;
            local $SIG{__WARN__} = sub { push @warnings, $_[0] };

            my $full_path = $store->write_document( 'example.yml' => $doc  );
            is $full_path, $store->path->child( 'example.yml' );
            cmp_deeply $store->read_document( 'example.yml' ), $doc
                or diag explain $store->read_document( 'example.yml' );
            eq_or_diff path( $full_path )->slurp_utf8,
                $SHARE_DIR->child( qw( store write doc.yml ) )->slurp_utf8;

            ok !@warnings, 'no warnings from write'
                or diag "Got warnings: \n\t" . join "\n\t", @warnings;
        };

        subtest 'make the directories if necessary' => sub {
            my @warnings;
            local $SIG{__WARN__} = sub { push @warnings, $_[0] };

            my $path = path(qw( blog 2014 05 28 example.yml ));
            my $full_path = $store->write_document( $path => $doc );
            is $full_path, $tmpdir->child( $path );
            cmp_deeply $store->read_document( $path ), $doc;
            eq_or_diff path( $full_path )->slurp_utf8,
                $SHARE_DIR->child( qw( store write doc.yml ) )->slurp_utf8;

            ok !@warnings, 'no warnings from write'
                or diag "Got warnings: \n\t" . join "\n\t", @warnings;
        };

    };
};

subtest 'files' => sub {

    subtest 'read files' => sub {
        my $store = Statocles::Store->new(
            path => $SHARE_DIR->child( qw( store files ) ),
        );
        my $content = $store->read_file( path( 'text.txt' ) );
        eq_or_diff $SHARE_DIR->child( qw( store files text.txt ) )->slurp_utf8, $content;
    };

    subtest 'has file' => sub {
        my $store = Statocles::Store->new(
            path => $SHARE_DIR->child( qw( store files ) ),
        );
        ok $store->has_file( path( 'text.txt' ) );
        ok !$store->has_file( path( 'missing.exe' ) );
    };

    subtest 'find files' => sub {
        my $store = Statocles::Store->new(
            path => $SHARE_DIR->child( qw( store files ) ),
        );
        my @expect_paths = (
            path( qw( text.txt ) ),
            path( qw( folder doc.yml ) ),
        );

        my $iter = $store->find_files;
        my @got_paths;
        while ( my $path = $iter->() ) {
            push @got_paths, $path;
        }

        cmp_deeply \@got_paths, bag( @expect_paths )
            or diag explain \@got_paths;
    };

    subtest 'write files' => sub {
        my @warnings;
        local $SIG{__WARN__} = sub { push @warnings, $_[0] };

        my $tmpdir = tempdir;
        my $store = Statocles::Store->new(
            path => $tmpdir,
        );

        my $content = "\x{2603} This is some plain text";
        $store->write_file( path( qw( store files text.txt ) ), $content );
        my $path = $tmpdir->child( qw( store files text.txt ) );
        eq_or_diff $path->slurp_utf8, $content;

        ok !@warnings, 'no warnings from write'
            or diag "Got warnings: \n\t" . join "\n\t", @warnings;
    };

};

subtest 'verbose' => sub {

    local $ENV{MOJO_LOG_LEVEL} = 'debug';

    subtest 'write' => sub {
        my $tmpdir = tempdir;
        my $store = Statocles::Store->new(
            path => $tmpdir,
        );

        subtest 'write_file' => sub {
            my ( $out, $err, $exit ) = capture {
                $store->write_file( 'path.html' => 'HTML' );
            };
            like $err, qr{\QWrite file: path.html};
        };

        subtest 'write_document' => sub {
            my ( $out, $err, $exit ) = capture {
                $store->write_document( 'path.yml' => { foo => 'BAR' } );
            };
            like $err, qr{\QWrite document: path.yml};
        };
    };

    subtest 'read' => sub {

        subtest 'read file' => sub {
            my $store = Statocles::Store->new(
                path => $SHARE_DIR->child( 'theme' ),
            );
            my $path = path( qw( blog post.html.ep ) );
            my ( $out, $err, $exit ) = capture {
                $store->read_file( $path );
            };
            like $err, qr{\QRead file: $path};
        };

        subtest 'read document' => sub {
            my $store = Statocles::Store->new(
                path => $SHARE_DIR->child( qw( store docs ) ),
            );
            my $path = path( qw( required.yml ) );
            my ( $out, $err, $exit ) = capture {
                $store->read_document( $path );
            };
            like $err, qr{\QRead document: $path};
        };

    };

};

done_testing;
