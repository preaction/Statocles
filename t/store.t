
use Statocles::Test;
use Cwd qw( getcwd );
my $SHARE_DIR = catdir( __DIR__, 'share' );

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
        path => catdir( $SHARE_DIR, 'blog' ),
    );
    cmp_deeply $store->documents, bag( @exp_docs );
};

subtest 'read with relative directory' => sub {
    my $cwd = getcwd();
    chdir $SHARE_DIR;
    my $store = Statocles::Store->new(
        path => 'blog',
    );
    cmp_deeply $store->documents, bag( @exp_docs );
    chdir $cwd;
};

subtest 'write pages' => sub {
    my $tmpdir = File::Temp->newdir;
    my $store = Statocles::Store->new(
        path => $tmpdir->dirname,
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
    my $path = catfile( $tmpdir->dirname, '2014', '04', '23', 'slug.html' );
    cmp_deeply scalar read_file( $path ), $page->render;
};

subtest 'path that has regex-special characters inside' => sub {
    my $tmpdir = File::Temp->newdir;
    my $baddir = catdir( $tmpdir, '[regex](name).dir' );
    mkdir $baddir;
    dircopy catdir( $SHARE_DIR, 'blog' ), $baddir;
    my $store = Statocles::Store->new(
        path => $baddir,
    );
    cmp_deeply $store->documents, bag( @exp_docs );
};

done_testing;
