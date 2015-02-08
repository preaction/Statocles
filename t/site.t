
use Statocles::Base 'Test';
use Statocles::Site;
use Statocles::App::Blog;
use Statocles::App::Static;
use Statocles::Deploy::File;
use Mojo::DOM;
use Mojo::URL;
my $SHARE_DIR = path( __DIR__, 'share' );

subtest 'constructor' => sub {
    my $cwd = cwd;
    my $tmp = tempdir;
    chdir $tmp;
    mkdir '.statocles-build';

    my %required = (
        deploy => '.',
    );

    test_constructor(
        'Statocles::Site',
        required => \%required,
        default => {
            theme => Statocles::Theme->new( store => '::default' ),
            build_store => Statocles::Store::File->new( path => '.statocles-build' ),
        },
    );

    chdir $cwd;

    subtest 'build dir gets created automatically' => sub {
        my $tmp = tempdir;
        chdir $tmp;

        lives_ok { Statocles::Site->new( %required ) };
        ok -d '.statocles-build', 'directory was created';

        lives_ok { Statocles::Site->new( build_store => 'builddir', %required ) };
        ok -d 'builddir', 'directory was created';

        chdir $cwd;
    };

};

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
                ok !$tmpdir->child( 'deploy', $page->path )->exists,
                    $page->path . ' is not deployed';
            }
        };

        subtest 'check theme' => sub {
            my $iter = $site->theme->store->find_files;
            while ( my $theme_file = $iter->() ) {
                ok $tmpdir->child( 'build', 'theme', $theme_file )->exists,
                    'theme file ' . $theme_file . 'exists in build dir';
                ok !$tmpdir->child( 'deploy', 'theme', $theme_file )->exists,
                    'theme file ' . $theme_file . 'not in deploy dir';
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
                ok $tmpdir->child( 'deploy', $page->path )->slurp_raw eq $content,
                    $page->path . ' content is correct';
            }
        };

        subtest 'check theme' => sub {
            my $iter = $site->theme->store->find_files;
            while ( my $theme_file = $iter->() ) {
                ok $tmpdir->child( 'deploy', 'theme', $theme_file )->exists,
                    'theme file ' . $theme_file . 'exists in deploy dir';
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
                    title => 'About Us',
                    href => '/about.html',
                    text => 'About',
                },
            ],
        },
    );

    subtest 'nav( NAME ) method' => sub {
        my @links = $site->nav( 'main' );
        cmp_deeply \@links, [
            methods(
                title => 'Blog',
                href => '/index.html',
                text => 'Blog',
            ),
            methods(
                title => 'About Us',
                href => '/about.html',
                text => 'About',
            ),
        ];

        cmp_deeply [ $site->nav( 'MISSING' ) ], [], 'missing nav returns empty list';
    };

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
        '' => '2014-06-02',
        '/blog/page/2' => '2014-06-02',
        '/blog/tag/more' => '2014-06-02',
        '/blog/tag/better' => '2014-06-02',
        '/blog/tag/better/page/2' => '2014-06-02',
        '/blog/tag/error-message' => '2014-05-22',
        '/blog/tag/even-more-tags' => '2014-06-02',
    );

    my @posts = qw(
        /blog/2014/04/23/slug.html
        /blog/2014/04/30/plug.html
        /blog/2014/05/22/(regex)[name].file.html
        /blog/2014/06/02/more_tags.html
    );

    my @lists = ( '', qw(
        /blog/page/2
        /blog/tag/more
        /blog/tag/better
        /blog/tag/better/page/2
        /blog/tag/error-message
        /blog/tag/even-more-tags
    ) );

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
            [ grep { /\S/ } $tmpdir->child( 'build', 'robots.txt' )->lines ],
            [
                "Sitemap: http://example.com/sitemap.xml\n",
                "User-Agent: *\n",
                "Disallow:\n",
            ] or diag explain [ $tmpdir->child( 'build', 'robots.txt' )->lines ];
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
            [ grep { /\S/ } $tmpdir->child( 'deploy', 'robots.txt' )->lines ],
            [
                "Sitemap: http://example.com/sitemap.xml\n",
                "User-Agent: *\n",
                "Disallow:\n",
            ] or diag explain [ $tmpdir->child( 'build', 'robots.txt' )->lines ];
    };
};

subtest 'site urls' => sub {
    subtest 'domain only' => sub {
        my $tmpdir = tempdir;
        my $site = test_site( $tmpdir,
            base_url => 'http://example.com/',
        );

        is $site->url( '/blog/2014/01/01/a-page.html' ),
           'http://example.com/blog/2014/01/01/a-page.html';
        subtest 'index.html is removed' => sub {
            is $site->url( '/index.html' ),
               'http://example.com';
        };
    };

    subtest 'domain and folder' => sub {
        my $tmpdir = tempdir;
        my $site = test_site( $tmpdir,
            base_url => 'http://example.com/folder',
        );

        is $site->url( '/blog/2014/01/01/a-page.html' ),
           'http://example.com/folder/blog/2014/01/01/a-page.html';
        subtest 'index.html is removed' => sub {
            is $site->url( '/index.html' ),
               'http://example.com/folder';
        };
    };

    subtest 'stores with base_url' => sub {
        my $tmpdir = tempdir;
        my $site = test_site( $tmpdir,
            deploy => {
                base_url => 'http://example.com/',
            },
            base_url => '',
        );

        is $site->url( '/blog/2014/01/01/a-page.html' ), '/blog/2014/01/01/a-page.html';
        subtest 'index.html is removed' => sub {
            is $site->url( '/index.html' ), '/';
        };

        subtest 'current writing deploy overrides site base url' => sub {
            $site->_write_deploy( $site->deploy );
            is $site->url( '/blog/2014/01/01/a-page.html' ), 'http://example.com/blog/2014/01/01/a-page.html';
            subtest 'index.html is removed' => sub {
                is $site->url( '/index.html' ), 'http://example.com';
            };
        };
    };

    subtest 'base URL with folder rewrites content' => sub {
        my $tmpdir = tempdir;
        my $site = test_site( $tmpdir,
            deploy => {
                base_url => 'http://example.com/deploy',
            },
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
                subtest 'page content: ' . $page->path => test_content( $tmpdir, $site, $page, deploy => $page->path, $site->deploy );
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

subtest 'error messages' => sub {

    subtest 'index_app does not give any pages' => sub {
        my $tmpdir = tempdir;
        $tmpdir->child( 'static' )->mkpath;
        my $static = Statocles::App::Static->new(
            store => $tmpdir->child( qw( static ) ),
            url_root => '/static',
        );

        $tmpdir->child( 'build' )->mkpath;
        $tmpdir->child( 'deploy' )->mkpath;

        my $site = Statocles::Site->new(
            title => 'Test Site',
            theme => $SHARE_DIR->child( 'theme' ),
            apps => {
                static => $static,
            },
            build_store => $tmpdir->child( 'build' ),
            deploy => $tmpdir->child( 'deploy' ),
            base_url => 'http://example.com',
            index => 'static',
        );

        throws_ok { $site->build } qr{ERROR: Index app "static" did not generate any pages};
    };

};

done_testing;

sub test_site {
    my ( $tmpdir, %site_args ) = @_;

    my $blog = Statocles::App::Blog->new(
        store => $SHARE_DIR->child( qw( app blog ) ),
        url_root => '/blog',
        page_size => 2,
    );

    my $static = Statocles::App::Static->new(
        store => $SHARE_DIR->child( qw( app static ) ),
        url_root => '/static',
    );

    $tmpdir->child( 'build' )->mkpath;
    $tmpdir->child( 'deploy' )->mkpath;

    my $build_store
        = Statocles::Store::File->new(
            path => $tmpdir->child( 'build' ),
            %{ delete $site_args{build_store} || {} },
        );

    my $deploy
        = Statocles::Deploy::File->new(
            path => $tmpdir->child( 'deploy' ),
            %{ delete $site_args{deploy} || {} },
        );


    my $site = Statocles::Site->new(
        title => 'Test Site',
        theme => $SHARE_DIR->child( 'theme' ),
        apps => {
            blog => $blog,
            static => $static,
        },
        build_store => $build_store,
        deploy => $deploy,
        base_url => 'http://example.com',
        data => {
            profile_url => '/profile',
        },
        %site_args,
    );

    subtest 'new site changes global site' => sub {
        is +site->log, $site->log;
    };

    return $site;
}

sub test_content {
    my ( $tmpdir, $site, $page, $dir, $file, $deploy ) = @_;
    my $base_url = Mojo::URL->new( $deploy ? $deploy->base_url : $site->base_url );
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
            my @nav_got = $got_dom->at('nav')->find( 'a' )
                        ->map( sub { Statocles::Link->new_from_element( $_ ) } )
                        ->each;
            my @nav_expect = $site->nav( 'main' );
            if ( $base_path =~ /\S/ ) {
                for my $link ( @nav_expect ) {
                    $link->href( join "", $base_path, $link->href );
                }
            }
            cmp_deeply \@nav_got, \@nav_expect or diag explain \@nav_got;
        }

        if ( $path =~ /[.]html$/ && ok my $footer_link = $got_dom->at( 'footer a' ) ) {
            is $footer_link->attr( 'href' ),
                join( "", $base_path, $site->data->{profile_url} ),
                'data is correct and rewritten for site root';
        }

    };
}

