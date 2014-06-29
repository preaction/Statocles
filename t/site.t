
use Statocles::Test;
use Statocles::Site;
use Statocles::Theme;
use Statocles::Store;
use Statocles::App::Blog;
use Mojo::DOM;
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

subtest 'sitemap.xml and robots.txt' => sub {
    my $tmpdir = tempdir;
    my $site = site( $tmpdir, index => 'blog' );

    my @pages = map { $_->pages } values %{ $site->apps };
    my $today = Time::Piece->new->strftime( '%Y-%m-%d' );
    my $to_href = sub {
        my $lastmod = $_->at('lastmod');
        return {
            loc => $_->at('loc')->text,
            changefreq => $_->at('changefreq')->text,
            priority => $_->at('priority')->text,
            ( $lastmod ? ( lastmod => $lastmod->text ) : () ),
        };
    };

    my %page_mod = (
        '/blog/2014/04/23/slug.html' => '2014-04-30',
        '/blog/2014/04/30/plug.html' => '2014-04-30',
        '/blog/2014/05/22/(regex)[name].file.html' => '2014-05-22',
        '/blog/2014/06/02/more_tags.html' => '2014-06-02',
    );
    my @lists = qw(
        /index.html
        /blog/page-2.html
        /blog/tag/more/index.html
        /blog/tag/better/index.html
        /blog/tag/better/page-2.html
        /blog/tag/error-message/index.html
        /blog/tag/even-more-tags/index.html
    );

    my @expect = (
        ( # List pages
            map {;
                {
                    loc => "http://example.com$_",
                    priority => '0.3',
                    changefreq => 'daily',
                }
            }
            @lists
        ),
        ( # Post pages
            map {
                {
                    loc => "http://example.com$_",
                    priority => '0.5',
                    changefreq => 'never',
                    lastmod => $page_mod{ $_ },
                }
            }
            keys %page_mod
        )
    );

    subtest 'build' => sub {
        $site->build;
        my $dom = Mojo::DOM->new( $tmpdir->child( 'build', 'sitemap.xml' )->slurp );
        is $dom->at('urlset')->type, 'urlset';
        my @urls = $dom->at('urlset')->children->map( $to_href )->each;
        cmp_deeply \@urls, bag( @expect ) or diag explain \@urls;
        cmp_deeply
            [ $tmpdir->child( 'build', 'robots.txt' )->lines ],
            [
                "Sitemap: http://example.com/sitemap.xml\n",
                "User-Agent: *\n",
                "Disallow: ",
            ];
        ok !$tmpdir->child( 'deploy', 'sitemap.xml' )->exists, 'not deployed yet';
        ok !$tmpdir->child( 'deploy', 'robots.txt' )->exists, 'not deployed yet';
    };
    subtest 'deploy' => sub {
        $site->deploy;
        my $dom = Mojo::DOM->new( $tmpdir->child( 'deploy', 'sitemap.xml' )->slurp );
        is $dom->at('urlset')->type, 'urlset';
        my @urls = $dom->at('urlset')->children->map( $to_href )->each;
        cmp_deeply \@urls, bag( @expect ) or diag explain \@urls;
        cmp_deeply
            [ $tmpdir->child( 'deploy', 'robots.txt' )->lines ],
            [
                "Sitemap: http://example.com/sitemap.xml\n",
                "User-Agent: *\n",
                "Disallow: ",
            ];
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
        page_size => 2,
    );

    my $site = Statocles::Site->new(
        title => 'Test Site',
        apps => { blog => $blog },
        build_store => $tmpdir->child( 'build' ),
        deploy_store => $tmpdir->child( 'deploy' ),
        base_url => 'http://example.com',
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
