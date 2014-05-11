
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
        build_store => Statocles::Store->new(
            path => catdir( $tmpdir->dirname, 'build' ),
        ),
        deploy_store => Statocles::Store->new(
            path => catdir( $tmpdir->dirname, 'deploy' ),
        ),
    );

    $site->build;

    for my $page ( $site->app( 'blog' )->pages ) {
        my $file = catfile( $tmpdir->dirname, 'build', $page->path );
        ok -f $file;
        eq_or_diff scalar read_file( $file ), $page->render;
        ok !-f catfile( $tmpdir->dirname, 'deploy', $page->path ), 'not deployed yet';
    }

    $site->deploy;

    for my $page ( $site->app( 'blog' )->pages ) {
        my $file = catfile( $tmpdir->dirname, 'deploy', $page->path );
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
        build_store => Statocles::Store->new(
            path => catdir( $tmpdir->dirname, 'build' ),
        ),
        deploy_store => Statocles::Store->new(
            path => catdir( $tmpdir->dirname, 'deploy' ),
        ),
    );

    $site->build;

    eq_or_diff
        scalar read_file( catfile( $tmpdir->dirname, 'build', 'index.html' ) ),
        $blog->index->render;
    ok !-f catfile( $tmpdir->dirname, 'deploy', 'index.html' ), 'not deployed yet';

    $site->deploy;

    eq_or_diff
        scalar read_file( catfile( $tmpdir->dirname, 'deploy', 'index.html' ) ),
        $blog->index->render;
};

done_testing;
