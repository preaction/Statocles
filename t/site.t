
use Statocles::Base 'Test';
use Statocles::Site;
use Statocles::Theme;
use Statocles::App::Blog;
use Statocles::App::Static;
use Mojo::DOM;
use Mojo::URL;
my $SHARE_DIR = path( __DIR__, 'share' );

subtest 'site writes application' => sub {
    my $tmpdir = tempdir;
    my $site = test_site( $tmpdir );

    subtest 'build' => sub {
        $site->build;

        for my $page ( $site->app( 'blog' )->pages, $site->app( 'static' )->pages ) {
            ok $tmpdir->child( 'build', $page->path )->exists, $page->path . ' built';
            ok !$tmpdir->child( 'deploy', $page->path )->exists, $page->path . ' not deployed yet';
        }

        subtest 'check static content' => sub {
            for my $page ( $site->app( 'static' )->pages ) {
                my $fh = $page->render;
                my $content = do { local $/; <$fh> };
                ok $tmpdir->child( 'build', $page->path )->slurp_raw eq $content,
                    $page->path . ' content is correct';
            }
        };

    };

    subtest 'deploy' => sub {
        $site->deploy;

        for my $page ( $site->app( 'blog' )->pages, $site->app( 'static' )->pages ) {
            ok $tmpdir->child( 'build', $page->path )->exists, $page->path . ' built';
            ok $tmpdir->child( 'deploy', $page->path )->exists, $page->path . ' deployed';
        }

        subtest 'check static content' => sub {
            for my $page ( $site->app( 'static' )->pages ) {
                my $fh = $page->render;
                my $content = do { local $/; <$fh> };
                ok $tmpdir->child( 'build', $page->path )->slurp_raw eq $content,
                    $page->path . ' content is correct';
            }
        };

    };
};

subtest 'site index and navigation' => sub {
    my $tmpdir = tempdir;
    my $site = test_site( $tmpdir,
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
    my $page = ( $blog->pages )[0];

    subtest 'build' => sub {
        $site->build;
        subtest 'site index content: ' . $page->path => test_content( $tmpdir, $site, $page, build => 'index.html' );
        ok !$tmpdir->child( 'deploy', 'index.html' )->exists, 'not deployed yet';
        ok !$tmpdir->child( 'build', 'blog', 'index.html' )->exists,
            'site index renames app page';
    };

    subtest 'deploy' => sub {
        $site->deploy;
        subtest 'site index content: ' . $page->path => test_content( $tmpdir, $site, $page, deploy => 'index.html' );
        ok !$tmpdir->child( 'deploy', 'blog', 'index.html' )->exists,
            'site index renames app page';
    };
};

subtest 'sitemap.xml and robots.txt' => sub {
    my $tmpdir = tempdir;
    my $site = test_site( $tmpdir, index => 'blog' );

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
        '/blog/2014/04/23/slug.html' => '2014-04-23',
        '/blog/2014/04/30/plug.html' => '2014-04-30',
        '/blog/2014/05/22/(regex)[name].file.html' => '2014-05-22',
        '/blog/2014/06/02/more_tags.html' => '2014-06-02',
        '/index.html' => '2014-06-02',
        '/blog/page-2.html' => '2014-06-02',
        '/blog/tag/more/index.html' => '2014-06-02',
        '/blog/tag/better/index.html' => '2014-06-02',
        '/blog/tag/better/page-2.html' => '2014-06-02',
        '/blog/tag/error-message/index.html' => '2014-05-22',
        '/blog/tag/even-more-tags/index.html' => '2014-06-02',
    );

    my @posts = qw(
        /blog/2014/04/23/slug.html
        /blog/2014/04/30/plug.html
        /blog/2014/05/22/(regex)[name].file.html
        /blog/2014/06/02/more_tags.html
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
                    lastmod => $page_mod{ $_ },
                }
            }
            @lists
        ),
        ( # Post pages
            map {
                {
                    loc => "http://example.com$_",
                    priority => '0.5',
                    changefreq => 'weekly',
                    lastmod => $page_mod{ $_ },
                }
            }
            @posts
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
    subtest 'domain only' => sub {
        my $tmpdir = tempdir;
        my $site = test_site( $tmpdir,
            base_url => 'http://example.com/',
        );

        is $site->url( '/index.html' ),
           'http://example.com/index.html';
        is $site->url( '/blog/2014/01/01/a-page.html' ),
           'http://example.com/blog/2014/01/01/a-page.html';
    };

    subtest 'domain and folder' => sub {
        my $tmpdir = tempdir;
        my $site = test_site( $tmpdir,
            base_url => 'http://example.com/folder',
        );

        is $site->url( '/index.html' ),
           'http://example.com/folder/index.html';
        is $site->url( '/blog/2014/01/01/a-page.html' ),
           'http://example.com/folder/blog/2014/01/01/a-page.html';
    };

    subtest 'base URL with folder rewrites content' => sub {
        my $tmpdir = tempdir;
        my $site = test_site( $tmpdir,
            base_url => 'http://example.com/folder',
        );

        subtest 'build' => sub {
            $site->build;

            for my $page ( $site->app( 'blog' )->pages ) {
                subtest 'page content: ' . $page->path => test_content( $tmpdir, $site, $page, build => $page->path );
                ok !$tmpdir->child( 'deploy', $page->path )->exists, 'not deployed yet';
            }

            subtest 'check static content' => sub {
                for my $page ( $site->app( 'static' )->pages ) {
                    my $fh = $page->render;
                    my $content = do { local $/; <$fh> };
                    is $tmpdir->child( 'build', $page->path )->slurp_raw, $content,
                        $page->path . ' content is correct';
                }
            };

        };

        subtest 'deploy' => sub {
            $site->deploy;

            for my $page ( $site->app( 'blog' )->pages ) {
                subtest 'page content: ' . $page->path => test_content( $tmpdir, $site, $page, deploy => $page->path );
            }

            subtest 'check static content' => sub {
                for my $page ( $site->app( 'static' )->pages ) {
                    my $fh = $page->render;
                    my $content = do { local $/; <$fh> };
                    is $tmpdir->child( 'deploy', $page->path )->slurp_raw, $content,
                        $page->path . ' content is correct';
                }
            };

        };
    };
};

done_testing;

sub test_site {
    my ( $tmpdir, %site_args ) = @_;

    my $blog = Statocles::App::Blog->new(
        store => $SHARE_DIR->child( qw( app blog ) ),
        url_root => '/blog',
        theme => $SHARE_DIR->child( 'theme' ),
        page_size => 2,
    );

    my $static = Statocles::App::Static->new(
        store => $SHARE_DIR->child( qw( app static ) ),
        url_root => '/static',
    );

    $tmpdir->child( 'build' )->mkpath;
    $tmpdir->child( 'deploy' )->mkpath;

    my $site = Statocles::Site->new(
        title => 'Test Site',
        apps => {
            blog => $blog,
            static => $static,
        },
        build_store => $tmpdir->child( 'build' ),
        deploy_store => $tmpdir->child( 'deploy' ),
        base_url => 'http://example.com',
        %site_args,
    );

    subtest 'new site changes global site' => sub {
        is +site->log, $site->log;
    };

    return $site;
}

sub test_content {
    my ( $tmpdir, $site, $page, $dir, $file ) = @_;
    my $base_url = Mojo::URL->new( $site->base_url );
    my $base_path = $base_url->path;
    $base_path =~ s{/$}{};

    return sub {
        my $path = $tmpdir->child( $dir, $file );
        my $got_dom = Mojo::DOM->new( $path->slurp );

        my $expect_dom = Mojo::DOM->new( $page->render( site => $site ) );
        if ( $base_path =~ /\S/ ) {
            for my $attr ( qw( src href ) ) {
                for my $el ( $expect_dom->find( "[$attr]" )->each ) {
                    my $url = $el->attr( $attr );
                    next unless $url =~ m{^/};
                    $el->attr( $attr, join "", $base_path, $url );
                }
            }
        }

        if ( $got_dom->at('title') ) {
            like $got_dom->at('title')->text, qr{@{[$site->title]}}, 'page contains site title ' . $site->title;
        }

        if ( $got_dom->at( 'nav' ) ) {
            my @nav_got    = $got_dom->at('nav')->find( 'a' )->map( sub { { href => $_->attr( 'href' ), title => $_->text } } )->each;
            my @nav_expect = @{ $site->nav->{ 'main' } };
            if ( $base_path =~ /\S/ ) {
                @nav_expect = map {; { title => $_->{title}, href => join "", $base_path, $_->{href} } } @nav_expect;
            }
            cmp_deeply \@nav_got, \@nav_expect or diag explain \@nav_got;
        }

    };
}

