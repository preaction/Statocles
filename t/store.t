
use Statocles::Test;
my $SHARE_DIR = path( __DIR__, 'share' );

use Statocles::Store;
use Statocles::Page::Document;
use File::Copy::Recursive qw( dircopy );

my @exp_docs = (
    Statocles::Document->new(
        path => '/2014/04/23/slug.yml',
        title => 'First Post',
        author => 'preaction',
        content => "Body content\n",
    ),
    Statocles::Document->new(
        path => '/2014/04/30/plug.yml',
        title => 'Second Post',
        author => 'preaction',
        content => "Better body content\n",
    ),
    Statocles::Document->new(
        path => '/2014/05/22/(regex)[name].file.yml',
        title => 'Regex violating Post',
        author => 'preaction',
        content => "Body content\n",
    ),
);

subtest 'read documents' => sub {
    my $store = Statocles::Store->new(
        path => $SHARE_DIR->child( 'blog' ),
    );
    cmp_deeply $store->documents, bag( @exp_docs ) or diag explain $store->documents;
};

subtest 'read with relative directory' => sub {
    my $cwd = cwd;
    chdir $SHARE_DIR;
    my $store = Statocles::Store->new(
        path => 'blog',
    );
    cmp_deeply $store->documents, bag( @exp_docs );
    chdir $cwd;
};

subtest 'write document' => sub {
    my $tmpdir = tempdir;
    my $store = Statocles::Store->new(
        path => $tmpdir,
    );
    my $doc = {
        foo => 'bar',
        content => "# This is some content\n\nAnd a paragraph\n",
    };
    subtest 'disallow absolute paths' => sub {
        my $path = rootdir->child( 'example.yml' );
        throws_ok { $store->write_document( $path => $doc ) }
            qr{Cannot write document '$path': Path must not be absolute};
    };
    subtest 'simple path' => sub {
        my $full_path = $store->write_document( 'example.yml' => $doc  );
        is $full_path, $store->path->child( 'example.yml' );
        cmp_deeply $store->read_document( $full_path ), $doc;
        eq_or_diff path( $full_path )->slurp, <<ENDFILE
---
foo: bar
---
# This is some content

And a paragraph
ENDFILE
    };
    subtest 'make the directories if necessary' => sub {
        my $path = path(qw( blog 2014 05 28 example.yml ));
        my $full_path = $store->write_document( $path => $doc );
        is $full_path, $tmpdir->child( $path );
        cmp_deeply $store->read_document( $full_path ), $doc;
        eq_or_diff path( $full_path )->slurp, <<ENDFILE
---
foo: bar
---
# This is some content

And a paragraph
ENDFILE
    };
};

subtest 'write pages' => sub {
    my $tmpdir = tempdir;
    my $store = Statocles::Store->new(
        path => $tmpdir,
    );
    my $page = Statocles::Page::Document->new(
        path => '/2014/04/23/slug.html',
        document => Statocles::Document->new(
            title => 'First Post',
            author => 'preaction',
            content => 'Body content',
        ),
    );
    $store->write_page( $page->path, $page->render );
    my $path = $tmpdir->child( '2014', '04', '23', 'slug.html' );
    cmp_deeply $path->slurp, $page->render;
};

subtest 'path that has regex-special characters inside' => sub {
    my $tmpdir = tempdir;
    my $baddir = $tmpdir->child( '[regex](name).dir' );
    dircopy $SHARE_DIR->child( 'blog' )->stringify, "$baddir";
    my $store = Statocles::Store->new(
        path => $baddir,
    );
    cmp_deeply $store->documents, bag( @exp_docs );
};

done_testing;
