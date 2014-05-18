
use Statocles::Test;
use Statocles::Site;
use Statocles::Theme;
use Statocles::Store;
use Statocles::App::Blog;
my $SHARE_DIR = catdir( __DIR__, 'share' );

subtest 'site writes application' => sub {
    my $tmpdir = File::Temp->newdir;
    my $site = site( $tmpdir );

    subtest 'build' => sub {
        $site->build;

        for my $page ( $site->app( 'blog' )->pages ) {
            subtest 'page content' => test_content( $tmpdir, $site, $page, build => $page->path );
            ok !-f catfile( $tmpdir->dirname, 'deploy', $page->path ), 'not deployed yet';
        }
    };

    subtest 'deploy' => sub {
        $site->deploy;

        for my $page ( $site->app( 'blog' )->pages ) {
            subtest 'page content' => test_content( $tmpdir, $site, $page, deploy => $page->path );
        }
    };
};

subtest 'site index' => sub {
    my $tmpdir = File::Temp->newdir;
    my $site = site( $tmpdir,
        index => 'blog',
    );
    my $blog = $site->app( 'blog' );

    subtest 'build' => sub {
        $site->build;
        subtest 'site index content' => test_content( $tmpdir, $site, $blog->index, build => 'index.html' );
        ok !-f catfile( $tmpdir->dirname, 'deploy', 'index.html' ), 'not deployed yet';
        ok !-f catfile( $tmpdir->dirname, 'build', 'blog', 'index.html' ),
            'site index renames app page';
    };

    subtest 'deploy' => sub {
        $site->deploy;
        subtest 'site index content' => test_content( $tmpdir, $site, $blog->index, deploy => 'index.html' );
        ok !-f catfile( $tmpdir->dirname, 'deploy', 'blog', 'index.html' ),
            'site index renames app page';
    };
};

done_testing;

sub site {
    my ( $tmpdir, %site_args ) = @_;

    my $theme = Statocles::Theme->new(
        source_dir => catdir( $SHARE_DIR, 'theme' ),
    );

    my $blog = Statocles::App::Blog->new(
        source => Statocles::Store->new(
            path => catdir( $SHARE_DIR, 'blog' ),
        ),
        url_root => '/blog',
        theme => $theme,
    );

    my $site = Statocles::Site->new(
        title => 'Test Site',
        apps => { blog => $blog },
        build_store => Statocles::Store->new(
            path => catdir( $tmpdir->dirname, 'build' ),
        ),
        deploy_store => Statocles::Store->new(
            path => catdir( $tmpdir->dirname, 'deploy' ),
        ),
        %site_args,
    );

    return $site;
}

sub test_content {
    my ( $tmpdir, $site, $page, $dir, $file ) = @_;
    return sub {
        my $path = catfile( $tmpdir->dirname, $dir, $file );
        my $html = read_file( $path );
        eq_or_diff $html, $page->render( site => $site );

        like $html, qr{@{[$site->title]}}, 'page contains site title';
    };
}
