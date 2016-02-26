
use Test::Lib;
use My::Test;
use Statocles::Store;
use Statocles::Util qw( dircopy );
use Capture::Tiny qw( capture );
use TestDocument;
my $SHARE_DIR = path( __DIR__, '..', 'share' );
build_test_site( theme => $SHARE_DIR->child( 'theme' ) );

my $DT_FORMAT = '%Y-%m-%d %H:%M:%S';

sub expect_docs {
    my ( $store ) = @_;

    return (
        Statocles::Document->new(
            path => '/required.markdown',
            title => 'Required Document',
            author => 'preaction',
            content => "No optional things in here, at all!\n",
            store => $store,
        ),

        Statocles::Document->new(
            path => '/ext/short.md',
            title => 'Short Extension',
            content => "This is a short extension\n",
            store => $store,
        ),

        Statocles::Document->new(
            path => '/no-frontmatter.markdown',
            content => "\n# This Document has no frontmatter!\n\nDocuments are not required to have frontmatter!\n",
            store => $store,
        ),

        Statocles::Document->new(
            path => '/path.markdown',
            title => 'Document with path inside',
            author => 'preaction',
            content => "The path is in the file, and it must be ignored.\n",
            store => $store,
        ),

        Statocles::Document->new(
            path => '/datetime.markdown',
            title => 'Datetime Document',
            author => 'preaction',
            date => DateTimeObj->coerce( '2014-04-30 15:34:32' ),
            content => "Parses date/time for date\n",
            store => $store,
        ),

        Statocles::Document->new(
            path => '/date.markdown',
            title => 'Date Document',
            author => 'preaction',
            date => DateTimeObj->coerce( '2014-04-30' ),
            content => "Parses date only for date\n",
            store => $store,
        ),

        Statocles::Document->new(
            path => '/links/alternate_single.markdown',
            title => 'Linked Document',
            author => 'preaction',
            content => "This document has a single alternate link\n",
            links => {
                alternate => [
                    {
                        title => 'blogs.perl.org',
                        href => 'http://blogs.perl.org/preaction/404.html',
                    },
                ],
            },
            store => $store,
        ),

        Statocles::Document->new(
            path => '/tags/single.markdown',
            title => 'Tagged (Single) Document',
            author => 'preaction',
            tags => [qw( single )],
            content => "This document has a single tag\n",
            store => $store,
        ),

        Statocles::Document->new(
            path => '/tags/array.markdown',
            title => 'Tagged (Array) Document',
            author => 'preaction',
            tags => [ 'multiple', 'tags', 'in an', 'array' ],
            content => "This document has multiple tags in an array\n",
            store => $store,
        ),

        Statocles::Document->new(
            path => '/tags/comma.markdown',
            title => 'Tagged (Comma) Document',
            author => 'preaction',
            tags => [ "multiple", "tags", "separated by", "commas" ],
            content => "This document has multiple tags separated by commas\n",
            store => $store,
        ),


        Statocles::Document->new(
            path => '/template/basic.markdown',
            title => 'Template document',
            content => "This document has a template\n",
            template => [qw( document basic.html.ep )],
            layout => [qw( site basic.html.ep )],
            store => $store,
        ),

        Statocles::Document->new(
            path => '/template/leading-slash.markdown',
            title => 'Template (Slash) document',
            content => "This document has a template with a leading slash\n",
            template => [qw( document slash.html.ep )],
            layout => [qw( site slash.html.ep )],
            store => $store,
        ),

        TestDocument->new(
            path => '/class/test_document.markdown',
            title => 'Test Class',
            content => "This is a custom class\n",
            store => $store,
        ),
    );
}

my $ignored_store = Statocles::Store->new(
    path => $SHARE_DIR->child( qw( store docs ignore ) ),
);

subtest 'read documents' => sub {
    my $store = Statocles::Store->new(
        path => $SHARE_DIR->child( qw( store docs ) ),
    );
    cmp_deeply $store->documents, bag( expect_docs( $store ) ) or diag explain $store->documents;

    subtest 'clear documents' => sub {
        # Edit the document
        $store->documents->[0]->title( 'This is a new title' );
        # Clear all the documents
        $store->clear;
        # Re-read them from disk
        cmp_deeply $store->documents, bag( expect_docs( $store ) ) or diag explain $store->documents;
    };
};

subtest 'parse frontmatter from content' => sub {
    my $store = Statocles::Store->new(
        path => tempdir,
    );
    my $path = $SHARE_DIR->child( qw( store docs required.markdown ) );
    cmp_deeply
        { $store->parse_frontmatter( $path, $path->slurp_utf8 ) },
        {
            title => 'Required Document',
            author => 'preaction',
            content => "No optional things in here, at all!\n",
        };

    subtest 'does not warn without content' => sub {
        my @warnings;
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        cmp_deeply
            { $store->parse_frontmatter( 'UNDEF' ) },
            { },
            'empty hashref';
        ok !@warnings, 'no warnings' or diag explain \@warnings;
    };

    subtest 'does not warn without more than one line' => sub {
        my @warnings;
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        cmp_deeply
            { $store->parse_frontmatter( 'one line', 'only one line' ) },
            { content => "only one line\n" },
            'empty hashref';
        ok !@warnings, 'no warnings' or diag explain \@warnings;
    };

    subtest 'does not warn with only a newline' => sub {
        my @warnings;
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        cmp_deeply
            { $store->parse_frontmatter( 'newline', "\n" ) },
            { content => '' },
            'empty hashref';
        ok !@warnings, 'no warnings' or diag explain \@warnings;
    };
};

subtest 'read with relative directory' => sub {
    my $cwd = cwd;
    chdir $SHARE_DIR;
    my $store = Statocles::Store->new(
        path => 'store/docs',
    );
    cmp_deeply $store->documents, bag( expect_docs( $store ) );
    chdir $cwd;
};

subtest 'path that has regex-special characters inside' => sub {
    my $tmpdir = tempdir;
    my $baddir = $tmpdir->child( '[regex](name).dir' );
    dircopy $SHARE_DIR->child( qw( store docs ) ), $baddir;
    my $ignored_store = Statocles::Store->new(
        path => $baddir->child( qw( ignore ) ),
    );
    my $store = Statocles::Store->new(
        path => $baddir,
    );
    cmp_deeply $store->documents, bag( expect_docs( $store ) )
        or diag join "\n", map { $_->path->stringify } @{ $store->documents };
};

subtest 'bad documents' => sub {
    subtest 'no ending frontmatter mark' => sub {
        my $store = Statocles::Store->new(
            path => $SHARE_DIR->child( qw( store error missing-end-mark ) ),
        );
        my $from = $store->path->child( 'missing.markdown' )->relative( cwd )->stringify;
        throws_ok { $store->documents } qr{\QCould not find end of front matter (---) in "$from"};
    };

    subtest 'invalid yaml' => sub {
        my $store = Statocles::Store->new(
            path => $SHARE_DIR->child( qw( store error bad-yaml ) ),
        );
        my $from = $store->path->child( 'bad.markdown' )->relative( cwd )->stringify;
        throws_ok { $store->documents } qr{\QError parsing YAML in "$from"};
    };

    subtest 'invalid date/time' => sub {
        my $store = Statocles::Store->new(
            path => $SHARE_DIR->child( qw( store error bad-dates ) ),
        );
        my $from = $store->path->child( 'bad-date.markdown' )->relative( cwd )->stringify;
        throws_ok { $store->documents }
            qr{\QCould not parse date "11/12/2014" in "$from": Does not match "YYYY-MM-DD" or "YYYY-MM-DD HH:MM:SS"};
    };

    subtest 'invalid links structure' => sub {
        my $store = Statocles::Store->new(
            path => $SHARE_DIR->child( qw( store error bad-links ) ),
        );
        my $from = $store->path->child( 'links.markdown' )->relative( cwd )->stringify;
        throws_ok { $store->documents }
            qr{\QError creating document in "$from": Value "bad link" is not valid for attribute "links" (expected "LinkHash")};
    };
};

subtest 'write document' => sub {
    no warnings 'once';
    local $YAML::Indent = 4; # Ensure our test output matches our indentation level
    my $tmpdir = tempdir;
    my $store = Statocles::Store->new(
        path => $tmpdir,
    );
    my $tp = DateTimeObj->coerce( '2014-06-05 00:00:00' );
    my $dt = $tp->strftime( '%Y-%m-%d %H:%M:%S' );
    my $doc = {
        foo => 'bar',
        content => "# \x{2603} This is some content\n\nAnd a paragraph\n",
        tags => [ 'one', 'two and three', 'four' ],
        date => $tp,
    };

    subtest 'disallow absolute paths' => sub {
        my $path = rootdir->child( 'example.markdown' );
        throws_ok { $store->write_document( $path => $doc ) }
            qr{Cannot write document '$path': Path must not be absolute};
    };

    subtest 'simple path' => sub {
        my @warnings;
        local $SIG{__WARN__} = sub { push @warnings, $_[0] };

        $store->write_document( 'example.markdown' => $doc  );
        cmp_deeply $store->read_document( 'example.markdown' ),
            Statocles::Document->new( path => 'example.markdown', store => $store, %$doc )
                or diag explain $store->read_document( 'example.markdown' );
        my $full_path = $store->path->child( 'example.markdown' );
        eq_or_diff path( $full_path )->slurp_utf8,
            $SHARE_DIR->child( qw( store write doc.markdown ) )->slurp_utf8;

        ok !@warnings, 'no warnings from write'
            or diag "Got warnings: \n\t" . join "\n\t", @warnings;
    };

    subtest 'make the directories if necessary' => sub {
        my @warnings;
        local $SIG{__WARN__} = sub { push @warnings, $_[0] };

        my $path = path(qw( blog 2014 05 28 example.markdown ));
        $store->write_document( $path => $doc );
        cmp_deeply $store->read_document( $path ), Statocles::Document->new( path => $path, store => $store, %$doc );
        my $full_path = $tmpdir->child( $path );
        eq_or_diff path( $full_path )->slurp_utf8,
            $SHARE_DIR->child( qw( store write doc.markdown ) )->slurp_utf8;

        ok !@warnings, 'no warnings from write'
            or diag "Got warnings: \n\t" . join "\n\t", @warnings;
    };

    subtest 'allow Document objects' => sub {
        my @warnings;
        local $SIG{__WARN__} = sub { push @warnings, $_[0] };

        my $doc_obj = Statocles::Document->new(
            path => 'example.markdown',
            store => $store,
            %$doc,
        );

        $store->write_document( 'doc_obj.markdown' => $doc_obj );
        my $full_path = $store->path->child( 'doc_obj.markdown' );
        cmp_deeply $store->read_document( 'doc_obj.markdown' ),
            Statocles::Document->new( path => 'doc_obj.markdown', store => $store, %$doc )
                or diag explain $store->read_document( 'doc_obj.markdown' );
        eq_or_diff path( $full_path )->slurp_utf8,
            $SHARE_DIR->child( qw( store write doc_obj.markdown ) )->slurp_utf8;

        ok !@warnings, 'no warnings from write'
            or diag "Got warnings: \n\t" . join "\n\t", @warnings;
    };

};

subtest 'removing a store reveals formerly-ignored files' => sub {
    $ignored_store = undef;
    my $store = Statocles::Store->new(
        path => $SHARE_DIR->child( qw( store docs ) ),
    );
    my $ignored_doc = Statocles::Document->new(
        path => '/ignore/ignored.markdown',
        title => 'This document is ignored',
        content => "This document is ignored because it's being used by another Store\n",
        store => $store,
    );
    cmp_deeply $store->documents, bag( expect_docs( $store ), $ignored_doc )
        or diag explain $store->documents;
};

subtest 'verbose' => sub {

    local $ENV{MOJO_LOG_LEVEL} = 'debug';

    subtest 'write' => sub {
        my $tmpdir = tempdir;
        my $store = Statocles::Store->new(
            path => $tmpdir,
        );

        my ( $out, $err, $exit ) = capture {
            $store->write_document( 'path.markdown' => { foo => 'BAR' } );
        };
        like $err, qr{\QWrite document: path.markdown};
    };

    subtest 'read' => sub {

        my $store = Statocles::Store->new(
            path => $SHARE_DIR->child( qw( store docs ) ),
        );
        my $path = path( qw( required.markdown ) );
        my ( $out, $err, $exit ) = capture {
            $store->read_document( $path );
        };
        like $err, qr{\QRead document: $path};

    };

};

subtest 'check if a path is a document' => sub {
    my $store = Statocles::Store->new(
        path => $SHARE_DIR->child( qw( store ) ),
    );
    ok $store->is_document( Path::Tiny->new(qw( docs ext short.md )) );
    ok $store->is_document( join "/", qw( docs ext short.md ) );
    ok !$store->is_document( Path::Tiny->new( qw( files image.png ) ) );
    ok !$store->is_document( join "/", qw( files image.png ) );
};

done_testing;
