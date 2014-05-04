
use Statocles::Test;
my $SHARE_DIR = catdir( __DIR__, 'share' );

use Statocles::Store;
use Statocles::Page;

subtest 'read documents' => sub {
    my $store = Statocles::Store->new(
        path => catdir( $SHARE_DIR, 'blog' ),
    );
    cmp_deeply $store->documents, [
        Statocles::Document->new(
            path => '/2014/04/23/slug.yml',
            title => 'First Post',
            author => 'preaction',
            content => "Body content\n",
        ),
    ];
};

subtest 'write pages' => sub {
    my $tmpdir = File::Temp->newdir;
    my $store = Statocles::Store->new(
        path => $tmpdir->dirname,
    );
    my $page = Statocles::Page->new(
        path => '/2014/04/23/slug.html',
        document => Statocles::Document->new(
            title => 'First Post',
            author => 'preaction',
            content => 'Body content',
        ),
    );
    $store->write_page( $page );
    my $path = catfile( $tmpdir->dirname, '2014', '04', '23', 'slug.html' );
    cmp_deeply scalar read_file( $path ), $page->render;
};

done_testing;
