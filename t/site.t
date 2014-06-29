
use Statocles::Test;
use Statocles::Site;
use Statocles::Theme;
use Statocles::Store;
use Statocles::App::Blog;
my $SHARE_DIR = path( __DIR__, 'share' );

subtest 'site writes application' => sub {
    my $tmpdir = tempdir;
    my $site = site( $tmpdir );

    subtest 'build' => sub {
        $site->build;

        for my $page ( $site->app( 'blog' )->pages ) {
            subtest 'page content' => test_content( $tmpdir, $site, $page, build => $page->path );
            ok !$tmpdir->child( 'deploy', $page->path )->exists, 'not deployed yet';
        }
    };

    subtest 'deploy' => sub {
        $site->deploy;

        for my $page ( $site->app( 'blog' )->pages ) {
            subtest 'page content' => test_content( $tmpdir, $site, $page, deploy => $page->path );
        }
    };
};

subtest 'site index and navigation' => sub {
    my $tmpdir = tempdir;
    my $site = site( $tmpdir,
        index => 'blog',
        nav => {
            main => [
                {
                    title => 'Blog',
                    href => '/index.html',
                },
                {
                    title => 'About',
                    href => '/about.html',
                },
            ],
        },
    );
    my $blog = $site->app( 'blog' );
    my $page = ( $blog->index )[0];

    subtest 'build' => sub {
        $site->build;
        subtest 'site index content' => test_content( $tmpdir, $site, $page, build => 'index.html' );
        ok !$tmpdir->child( 'deploy', 'index.html' )->exists, 'not deployed yet';
        ok !$tmpdir->child( 'build', 'blog', 'index.html' )->exists,
            'site index renames app page';
    };

    subtest 'deploy' => sub {
        $site->deploy;
        subtest 'site index content' => test_content( $tmpdir, $site, $page, deploy => 'index.html' );
        ok !$tmpdir->child( 'deploy', 'blog', 'index.html' )->exists,
            'site index renames app page';
    };
};

subtest 'site urls' => sub {
    my $tmpdir = tempdir;
    my $site = site( $tmpdir,
        base_url => 'http://example.com/',
    );
    is $site->url( '/index.html' ),
       'http://example.com/index.html';
    is $site->url( '/blog/2014/01/01/a-page.html' ),
       'http://example.com/blog/2014/01/01/a-page.html';
};

done_testing;

sub site {
    my ( $tmpdir, %site_args ) = @_;

    my $blog = Statocles::App::Blog->new(
        store => $SHARE_DIR->child( 'blog' ),
        url_root => '/blog',
        theme => $SHARE_DIR->child( 'theme' ),
    );

    my $site = Statocles::Site->new(
        title => 'Test Site',
        apps => { blog => $blog },
        build_store => $tmpdir->child( 'build' ),
        deploy_store => $tmpdir->child( 'deploy' ),
        %site_args,
    );

    return $site;
}

sub test_content {
    my ( $tmpdir, $site, $page, $dir, $file ) = @_;
    return sub {
        my $path = $tmpdir->child( $dir, $file );
        my $html = $path->slurp;
        eq_or_diff $html, $page->render( site => $site );

        like $html, qr{@{[$site->title]}}, 'page contains site title ' . $site->title;
        for my $nav ( @{ $site->nav->{ 'main' } } ) {
            my $title = $nav->{title};
            my $url = $nav->{href};
            like $html, qr{$title}, 'page contains nav main title ' . $title;
            like $html, qr{$url}, 'page contains nav main url ' . $url;
        }
    };
}
