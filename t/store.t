
use Test::Lib;
use My::Test;
use Statocles::Store;
use Statocles::Util qw( dircopy );
my $SHARE_DIR = path( __DIR__, 'share' );
my $site = build_test_site( theme => $SHARE_DIR->child( 'theme' ) );
my $DT_FORMAT = '%Y-%m-%d %H:%M:%S';

test_constructor(
    'Statocles::Store',
    required => {
        path => $SHARE_DIR->child( qw( store docs ) ),
    },
);

my %tests = (
    'required.markdown' => {
        title => 'Required Document',
        content => "No optional things in here, at all!\n",
    },
    'person.markdown' => {
        title => 'Person Document',
        author => Statocles::Person->new( name => 'preaction' ),
        content => "Made by a real person\n",
    },
    'json.markdown' => {
        title => 'JSON Document',
        content => "No optional things in here, at all!\n",
    },
    'json-oneline.markdown' => {
        title => 'JSON Document',
        content => "No optional things in here, at all!\n",
    },
    'ext/short.md' => {
        title => 'Short Extension',
        content => "This is a short extension\n",
    },
    'no-frontmatter.markdown' => {
        content => "\n# This Document has no frontmatter!\n\nDocuments are not required to have frontmatter!\n",
    },
    'path.markdown' => {
        title => 'Document with path inside',
        content => "The path is in the file, and it must be ignored.\n",
    },
    'datetime.markdown' => {
        title => 'Datetime Document',
        date => DateTimeObj->coerce( '2014-04-30 15:34:32' ),
        content => "Parses date/time for date\n",
    },
    'date.markdown' => {
        title => 'Date Document',
        date => DateTimeObj->coerce( '2014-04-30' ),
        content => "Parses date only for date\n",
    },
    'links/alternate_single.markdown' => {
        title => 'Linked Document',
        content => "This document has a single alternate link\n",
        _links => {
            alternate => [
                {
                    title => 'blogs.perl.org',
                    href => 'http://blogs.perl.org/preaction/404.html',
                },
            ],
        },
    },
    'tags/single.markdown' => {
        title => 'Tagged (Single) Document',
        tags => [qw( single )],
        content => "This document has a single tag\n",
    },
    'tags/array.markdown' => {
        title => 'Tagged (Array) Document',
        tags => [ 'multiple', 'tags', 'in an', 'array' ],
        content => "This document has multiple tags in an array\n",
    },
    'tags/comma.markdown' => {
        title => 'Tagged (Comma) Document',
        tags => [ "multiple", "tags", "separated by", "commas" ],
        content => "This document has multiple tags separated by commas\n",
    },
    'template/basic.markdown' => {
        title => 'Template document',
        content => "This document has a template\n",
        template => [qw( document basic.html.ep )],
        layout => [qw( site basic.html.ep )],
    },
    'template/leading-slash.markdown' => {
        title => 'Template (Slash) document',
        content => "This document has a template with a leading slash\n",
        template => [qw( document slash.html.ep )],
        layout => [qw( site slash.html.ep )],
    },
    'image.png' => { },
    'text.txt' => { },
    'utf8-yml.md' => {
        title => "Zero \x{00BB} One Hundred",
        content => "\nThis is a test post for UTF-8 with YAML front matter.\n",
    },
    'utf8-json.md' => {
        title => "Zero \x{00BB} One Hundred",
        content => "\nThis is a test post for UTF-8 titles with a JSON front matter.\n",
    },
);

sub test_store {
    my ( $store, %tests ) = @_;
    my $iter = $store->iterator;
    while ( my $obj = $iter->() ) {
        my $test = delete $tests{ $obj->path } or fail "Missing test for path " . $obj->path;
        cmp_deeply $obj, noclass( superhashof( $test ) ), $obj->path . ' is correctly parsed'
            or diag explain $obj;
    }
    if ( keys %tests > 0 ) {
        fail "Missing document for path(s): " . join '; ', keys %tests;
    }
}

my $ignored_store = Statocles::Store->new(
    path => $SHARE_DIR->child( qw( store docs ignore ) ),
);

subtest 'read iterator' => sub {
    my $store = Statocles::Store->new(
        path => $SHARE_DIR->child( qw( store docs ) ),
    );
    test_store( $store, %tests );
};

subtest 'read with relative directory' => sub {
    my $cwd = cwd;
    chdir $SHARE_DIR;
    my $store = Statocles::Store->new(
        path => 'store/docs',
    );
    test_store( $store, %tests );
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
    test_store( $store, %tests );
};

subtest 'bad documents' => sub {
    subtest 'no ending YAML frontmatter mark' => sub {
        my $store = Statocles::Store->new(
            path => $SHARE_DIR->child( qw( store error missing-end-mark ) ),
        );
        my $iter = $store->iterator;
        throws_ok { $iter->() } qr{\QError creating document in "missing.markdown": Could not find end of YAML front matter (---)};
    };

    subtest 'invalid yaml' => sub {
        my $store = Statocles::Store->new(
            path => $SHARE_DIR->child( qw( store error bad-yaml ) ),
        );
        my $iter = $store->iterator;
        throws_ok { $iter->() } qr{\QError creating document in "bad.markdown": Error parsing YAML};
    };

    subtest 'no ending JSON frontmatter mark' => sub {
        my $store = Statocles::Store->new(
            path => $SHARE_DIR->child( qw( store error missing-end-json ) ),
        );
        my $iter = $store->iterator;
        throws_ok { $iter->() } qr{\QError creating document in "missing.markdown": Could not find end of JSON front matter (\E\}\Q)};
    };

    subtest 'invalid JSON' => sub {
        my $store = Statocles::Store->new(
            path => $SHARE_DIR->child( qw( store error bad-json ) ),
        );
        my $iter = $store->iterator;
        throws_ok { $iter->() } qr{\QError creating document in "bad.markdown": Error parsing JSON};
    };

    subtest 'invalid date/time' => sub {
        my $store = Statocles::Store->new(
            path => $SHARE_DIR->child( qw( store error bad-dates ) ),
        );
        my $iter = $store->iterator;
        throws_ok { $iter->() }
            qr{\QCould not parse date "11/12/2014" in "bad-date.markdown": Does not match "YYYY-MM-DD" or "YYYY-MM-DD HH:MM:SS"};
    };

    subtest 'invalid links structure' => sub {
        my $store = Statocles::Store->new(
            path => $SHARE_DIR->child( qw( store error bad-links ) ),
        );
        my $iter = $store->iterator;
        throws_ok { $iter->() }
            qr{\QError creating document in "links.markdown": Value "bad link" is not valid for attribute "_links" (expected "LinkHash")};
    };
};

subtest 'removing a store reveals formerly-ignored files' => sub {
    $ignored_store = undef;
    my $store = Statocles::Store->new(
        path => $SHARE_DIR->child( qw( store docs ) ),
    );
    test_store( $store, %tests,
        'ignore/ignored.markdown' => {
            title => 'This document is ignored',
            content => "This document is ignored because it's being used by another Store\n",
        },
        'ignore/ignored.txt' => { },
    );
};

subtest 'has_file / is_document' => sub {
    my $store = Statocles::Store->new(
        path => $SHARE_DIR->child( qw( store ) ),
    );
    ok $store->is_document( Path::Tiny->new(qw( docs ext short.md )) );
    ok $store->is_document( join "/", qw( docs ext short.md ) );
    ok $store->has_file( path( qw( docs image.png ) ) );
    ok !$store->is_document( Path::Tiny->new( qw( docs image.png ) ) );
    ok !$store->is_document( join "/", qw( docs image.png ) );
};

subtest 'write files' => sub {
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    my $tmpdir = tempdir;
    my $store = Statocles::Store->new(
        path => $tmpdir,
    );

    subtest 'string' => sub {
        my $content = "\x{2603} This is some plain text";
        # write_file with string is written using UTF-8
        $store->write_file( path( qw( store docs text-1.txt ) ), $content );
        my $path = $tmpdir->child( qw( store docs text-1.txt ) );
        eq_or_diff $path->slurp_utf8, $content;
        ok !@warnings, 'no warnings from write'
            or diag "Got warnings: \n\t" . join "\n\t", @warnings;
    };

    subtest 'filehandle' => sub {
        subtest 'plain text files' => sub {
            my $fh = $SHARE_DIR->child( qw( store docs text.txt ) )->openr_raw;
            $store->write_file( path( qw( store docs text-2.txt ) ), $fh );
            my $path = $tmpdir->child( qw( store docs text-2.txt ) );
            eq_or_diff $path->slurp_raw, $SHARE_DIR->child( qw( store docs text.txt ) )->slurp_raw;
            ok !@warnings, 'no warnings from write'
                or diag "Got warnings: \n\t" . join "\n\t", @warnings;
        };

        subtest 'images' => sub {
            my $fh = $SHARE_DIR->child( qw( store docs image.png ) )->openr_raw;
            $store->write_file( path( qw( store docs image-1.png ) ), $fh );
            my $path = $tmpdir->child( qw( store docs image-1.png ) );
            ok $path->slurp_raw eq $SHARE_DIR->child( qw( store docs image.png ) )->slurp_raw,
                'image content is correct';
            ok !@warnings, 'no warnings from write'
                or diag "Got warnings: \n\t" . join "\n\t", @warnings;
        };
    };

    subtest 'Path::Tiny object' => sub {
        subtest 'plain text files' => sub {
            my $source_path = $SHARE_DIR->child( qw( store docs text.txt ) );
            $store->write_file( path( qw( store docs text-3.txt ) ), $source_path );
            my $dest_path = $tmpdir->child( qw( store docs text-3.txt ) );
            eq_or_diff $dest_path->slurp_raw, $source_path->slurp_raw;
            ok !@warnings, 'no warnings from write'
                or diag "Got warnings: \n\t" . join "\n\t", @warnings;
        };

        subtest 'images' => sub {
            my $source_path = $SHARE_DIR->child( qw( store docs image.png ) );
            $store->write_file( path( qw( store docs image-2.png ) ), $source_path );
            my $dest_path = $tmpdir->child( qw( store docs image-2.png ) );
            ok $dest_path->slurp_raw eq $source_path->slurp_raw,
                'image content is correct';
            ok !@warnings, 'no warnings from write'
                or diag "Got warnings: \n\t" . join "\n\t", @warnings;
        };
    };

    subtest 'document' => sub {
        no warnings 'once';
        local $YAML::Indent = 4; # Ensure our test output matches our indentation level
        my $tp = DateTimeObj->coerce( '2014-06-05 00:00:00' );
        my $dt = $tp->strftime( '%Y-%m-%d %H:%M:%S' );
        my $doc = {
            content => "# \x{2603} This is some content\n\nAnd a paragraph\n",
            tags => [ 'one', 'two and three', 'four' ],
            date => $tp,
        };

        subtest 'simple path' => sub {
            $store->write_file( 'example.markdown' => Statocles::Document->new( $doc )  );
            my $full_path = $store->path->child( 'example.markdown' );
            eq_or_diff path( $full_path )->slurp_utf8,
                $SHARE_DIR->child( qw( store write doc.markdown ) )->slurp_utf8;
            ok !@warnings, 'no warnings from write'
                or diag "Got warnings: \n\t" . join "\n\t", @warnings;
        };

        subtest 'make the directories if necessary' => sub {
            my $path = path(qw( blog 2014 05 28 example.markdown ));
            $store->write_file( $path => Statocles::Document->new( $doc ) );
            my $full_path = $tmpdir->child( $path );
            eq_or_diff path( $full_path )->slurp_utf8,
                $SHARE_DIR->child( qw( store write doc.markdown ) )->slurp_utf8;
            ok !@warnings, 'no warnings from write'
                or diag "Got warnings: \n\t" . join "\n\t", @warnings;
        };

    };
};

subtest 'remove' => sub {

    subtest 'file' => sub {
        my $tmpdir = tempdir;
        my $file_path = $tmpdir->child( 'foo', 'bar', 'baz.txt' );
        $file_path->parent->mkpath;
        $file_path->spew( 'Hello');

        my $store = Statocles::Store->new(
            path => $tmpdir,
        );
        $store->remove( path( qw( foo bar baz.txt ) ) );

        ok !$file_path->exists, 'file has been removed';
        ok $file_path->parent->exists, 'parent dir is not removed';
    };

    subtest 'directory' => sub {
        my $tmpdir = tempdir;
        my $file_path = $tmpdir->child( 'foo', 'bar', 'baz.txt' );
        $file_path->parent->mkpath;
        $file_path->spew( 'Hello');

        my $store = Statocles::Store->new(
            path => $tmpdir,
        );
        $store->remove( path( qw( foo bar ) ) );

        ok !$file_path->exists, 'file has been removed';
        ok !$file_path->parent->exists, 'parent dir is removed';
        ok $file_path->parent->parent->exists, 'grandparent dir is not removed';
    };
};

done_testing;
