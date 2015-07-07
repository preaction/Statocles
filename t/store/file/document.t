
use Statocles::Base 'Test';
use Statocles::Store::File;
use Statocles::Util qw( dircopy );
use Capture::Tiny qw( capture );
my $SHARE_DIR = path( __DIR__, '..', '..', 'share' );
build_test_site( theme => $SHARE_DIR->child( 'theme' ) );

my $DT_FORMAT = '%Y-%m-%d %H:%M:%S';

my %required_attrs = (
    title => 'Required Document',
    author => 'preaction',
    content => "No optional things in here, at all!\n",
);

my @exp_docs = (
    Statocles::Document->new(
        path => '/required.markdown',
        %required_attrs,
    ),

    Statocles::Document->new(
        path => '/ext/short.md',
        title => 'Short Extension',
        content => "This is a short extension\n",
    ),

    Statocles::Document->new(
        path => '/no-frontmatter.markdown',
        content => "\n# This Document has no frontmatter!\n\nDocuments are not required to have frontmatter!\n",
    ),

    Statocles::Document->new(
        path => '/path.markdown',
        title => 'Document with path inside',
        author => 'preaction',
        content => "The path is in the file, and it must be ignored.\n",
    ),

    Statocles::Document->new(
        path => '/datetime.markdown',
        title => 'Datetime Document',
        author => 'preaction',
        date => Time::Piece->strptime( '2014-04-30 15:34:32', $DT_FORMAT ),
        content => "Parses date/time for date\n",
    ),

    Statocles::Document->new(
        path => '/date.markdown',
        title => 'Date Document',
        author => 'preaction',
        date => Time::Piece->strptime( '2014-04-30', '%Y-%m-%d' ),
        content => "Parses date only for date\n",
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
    ),

    Statocles::Document->new(
        path => '/tags/single.markdown',
        title => 'Tagged (Single) Document',
        author => 'preaction',
        tags => [qw( single )],
        content => "This document has a single tag\n",
    ),

    Statocles::Document->new(
        path => '/tags/array.markdown',
        title => 'Tagged (Array) Document',
        author => 'preaction',
        tags => [ 'multiple', 'tags', 'in an', 'array' ],
        content => "This document has multiple tags in an array\n",
    ),

    Statocles::Document->new(
        path => '/tags/comma.markdown',
        title => 'Tagged (Comma) Document',
        author => 'preaction',
        tags => [ "multiple", "tags", "separated by", "commas" ],
        content => "This document has multiple tags separated by commas\n",
    ),


    Statocles::Document->new(
        path => '/template/basic.markdown',
        title => 'Template document',
        content => "This document has a template\n",
        template => [qw( document basic.html.ep )],
        layout => [qw( site basic.html.ep )],
    ),

    Statocles::Document->new(
        path => '/template/leading-slash.markdown',
        title => 'Template (Slash) document',
        content => "This document has a template with a leading slash\n",
        template => [qw( document slash.html.ep )],
        layout => [qw( site slash.html.ep )],
    ),


);

my @ignored_docs = (
    Statocles::Document->new(
        path => '/ignore/ignored.markdown',
        title => 'This document is ignored',
        content => "This document is ignored because it's being used by another Store\n",
    ),
);

my $ignored_store = Statocles::Store::File->new(
    path => $SHARE_DIR->child( qw( store docs ignore ) ),
);

subtest 'read documents' => sub {
    my $store = Statocles::Store::File->new(
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
};

subtest 'parse frontmatter from content' => sub {
    my $store = Statocles::Store::File->new(
        path => tempdir,
    );
    my $path = $SHARE_DIR->child( qw( store docs required.markdown ) );
    cmp_deeply { $store->parse_frontmatter( $path, $path->slurp_utf8 ) }, \%required_attrs;
};

subtest 'read with relative directory' => sub {
    my $cwd = cwd;
    chdir $SHARE_DIR;
    my $store = Statocles::Store::File->new(
        path => 'store/docs',
    );
    cmp_deeply $store->documents, bag( @exp_docs );
    chdir $cwd;
};

subtest 'path that has regex-special characters inside' => sub {
    my $tmpdir = tempdir;
    my $baddir = $tmpdir->child( '[regex](name).dir' );
    dircopy $SHARE_DIR->child( qw( store docs ) ), $baddir;
    my $ignored_store = Statocles::Store::File->new(
        path => $baddir->child( qw( ignore ) ),
    );
    my $store = Statocles::Store::File->new(
        path => $baddir,
    );
    cmp_deeply $store->documents, bag( @exp_docs )
        or diag join "\n", map { $_->path->stringify } @{ $store->documents };
};

subtest 'bad documents' => sub {
    subtest 'no ending frontmatter mark' => sub {
        my $store = Statocles::Store::File->new(
            path => $SHARE_DIR->child( qw( store error missing-end-mark ) ),
        );
        throws_ok { $store->documents } qr{\QCould not find end of front matter (---) in};
    };

    subtest 'invalid yaml' => sub {
        my $store = Statocles::Store::File->new(
            path => $SHARE_DIR->child( qw( store error bad-yaml ) ),
        );
        throws_ok { $store->documents } qr{Error parsing YAML in};
    };

    subtest 'invalid date/time' => sub {
        my $store = Statocles::Store::File->new(
            path => $SHARE_DIR->child( qw( store error bad-dates ) ),
        );
        throws_ok { $store->documents }
            qr{Could not parse date '11/12/2014'[.] Does not match '\Q$DT_FORMAT\E' or '%Y-%m-%d'};
    };

};

subtest 'write document' => sub {
    no warnings 'once';
    local $YAML::Indent = 4; # Ensure our test output matches our indentation level
    my $tmpdir = tempdir;
    my $store = Statocles::Store::File->new(
        path => $tmpdir,
    );
    my $tp = Time::Piece->strptime( '2014-06-05 00:00:00', $DT_FORMAT );
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

        my $full_path = $store->write_document( 'example.markdown' => $doc  );
        is $full_path, $store->path->child( 'example.markdown' );
        cmp_deeply $store->read_document( 'example.markdown' ),
            Statocles::Document->new( path => 'example.markdown', %$doc )
                or diag explain $store->read_document( 'example.markdown' );
        eq_or_diff path( $full_path )->slurp_utf8,
            $SHARE_DIR->child( qw( store write doc.markdown ) )->slurp_utf8;

        ok !@warnings, 'no warnings from write'
            or diag "Got warnings: \n\t" . join "\n\t", @warnings;
    };

    subtest 'make the directories if necessary' => sub {
        my @warnings;
        local $SIG{__WARN__} = sub { push @warnings, $_[0] };

        my $path = path(qw( blog 2014 05 28 example.markdown ));
        my $full_path = $store->write_document( $path => $doc );
        is $full_path, $tmpdir->child( $path );
        cmp_deeply $store->read_document( $path ), Statocles::Document->new( path => $path, %$doc );
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
            %$doc,
        );

        my $full_path = $store->write_document( 'doc_obj.markdown' => $doc_obj );
        is $full_path, $store->path->child( 'doc_obj.markdown' );
        cmp_deeply $store->read_document( 'doc_obj.markdown' ),
            Statocles::Document->new( path => 'doc_obj.markdown', %$doc )
                or diag explain $store->read_document( 'doc_obj.markdown' );
        eq_or_diff path( $full_path )->slurp_utf8,
            $SHARE_DIR->child( qw( store write doc_obj.markdown ) )->slurp_utf8;

        ok !@warnings, 'no warnings from write'
            or diag "Got warnings: \n\t" . join "\n\t", @warnings;
    };

};

subtest 'removing a store reveals formerly-ignored files' => sub {
    $ignored_store = undef;
    my $store = Statocles::Store::File->new(
        path => $SHARE_DIR->child( qw( store docs ) ),
    );
    cmp_deeply $store->documents, bag( @exp_docs, @ignored_docs )
        or diag explain $store->documents;
};

subtest 'verbose' => sub {

    local $ENV{MOJO_LOG_LEVEL} = 'debug';

    subtest 'write' => sub {
        my $tmpdir = tempdir;
        my $store = Statocles::Store::File->new(
            path => $tmpdir,
        );

        my ( $out, $err, $exit ) = capture {
            $store->write_document( 'path.markdown' => { foo => 'BAR' } );
        };
        like $err, qr{\QWrite document: path.markdown};
    };

    subtest 'read' => sub {

        my $store = Statocles::Store::File->new(
            path => $SHARE_DIR->child( qw( store docs ) ),
        );
        my $path = path( qw( required.markdown ) );
        my ( $out, $err, $exit ) = capture {
            $store->read_document( $path );
        };
        like $err, qr{\QRead document: $path};

    };

};

done_testing;
