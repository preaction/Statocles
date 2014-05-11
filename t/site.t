
use Statocles::Test;
use Statocles::Site;
use Statocles::Theme;
use Statocles::Store;
use Statocles::App::Blog;
my $SHARE_DIR = catdir( __DIR__, 'share' );

my $theme = Statocles::Theme->new(
    source_dir => catdir( $SHARE_DIR, 'theme' ),
);

my %blog_args = (
    source => Statocles::Store->new(
        path => catdir( $SHARE_DIR, 'blog' ),
    ),
    url_root => '/blog',
    theme => $theme,
);

subtest 'site writes application' => sub {
    my $tmpdir = File::Temp->newdir;
    my $blog = Statocles::App::Blog->new(
        %blog_args,
    );

    my $site = Statocles::Site->new(
        apps => { blog => $blog },
        destination => Statocles::Store->new(
            path => $tmpdir->dirname,
        ),
    );

    $site->deploy;

    for my $page ( $site->app( 'blog' )->pages ) {
        my $file = catfile( $tmpdir->dirname, $page->path );
        ok -f $file;
        eq_or_diff scalar read_file( $file ), $page->render;
    }
};

subtest 'site index' => sub {
    my $tmpdir = File::Temp->newdir;
    my $blog = Statocles::App::Blog->new(
        %blog_args,
    );

    my $site = Statocles::Site->new(
        index => 'blog',
        apps => { blog => $blog },
        destination => Statocles::Store->new(
            path => $tmpdir->dirname,
        ),
    );

    $site->deploy;

    eq_or_diff
        scalar read_file( catfile( $tmpdir->dirname, 'index.html' ) ),
        $blog->index->render;
};

done_testing;
