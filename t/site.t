
use Test::Lib;
use My::Test;
use Capture::Tiny qw( capture );
use Statocles::Site;
use Statocles::Theme;
use Statocles::Store;
use TestDeploy;
use TestApp;
my $SHARE_DIR = path( __DIR__, 'share' );

my %required = (
    deploy => '.',
);

test_constructor(
    'Statocles::Site',
    required => \%required,
    default => {
        index => '/',
        theme => Statocles::Theme->new( store => '::default' ),
    },
);

subtest 'build events' => sub {
    my $site = Statocles::Site->new(
        deploy => TestDeploy->new,
        apps => {
            base => TestApp->new(
                url_root => '/',
                pages => [
                    {
                        class => 'Statocles::Page::Plain',
                        path => '/index.html',
                        content => 'Index',
                    },
                    {
                        class => 'Statocles::Page::File',
                        path => '/static.txt',
                        file_path => $SHARE_DIR->child( qw( app basic static.txt ) ),
                    },
                ],
            ),
        },
    );

    $site->on( 'before_build_write', sub {
        subtest 'before_build_write' => sub {
            my ( $event ) = @_;
            isa_ok $event, 'Statocles::Event::Pages';
            ok scalar @{ $event->pages }, 'got some pages';
            cmp_deeply $event->pages,
                array_each(
                    methods( path => re( qr{^/} ) )
                ),
                'all pages are absolute';

            cmp_deeply $event->pages,
                superbagof(
                    methods( path => re( qr{^\Q/index.html} ) ),
                    methods( path => re( qr{^\Q/static.txt} ) ),
                ),
                'page paths are correct';

            ok !grep( { $_->path =~ m{\Q/robots.txt} } @{ $event->pages } ), 'robots.txt not made yet';
            ok !grep( { $_->path =~ m{\Q/sitemap.xml} } @{ $event->pages } ), 'sitemap.xml not made yet';

            # Add a new page in the plugin
            push @{ $event->pages }, Statocles::Page::Plain->new(
                path => '/foo/bar/baz.html',
                content => 'added by plugin',
            );
        }, @_;
    } );

    $site->on( 'build', sub {
        subtest 'build' => sub {
            my ( $event ) = @_;
            pass "Build event fired during build";
            isa_ok $event, 'Statocles::Event::Pages';
            ok scalar @{ $event->pages }, 'got some pages';
            cmp_deeply $event->pages,
                array_each(
                    methods( path => re( qr{^/} ) )
                ),
                'all pages are absolute';

            cmp_deeply $event->pages,
                superbagof(
                    methods( path => re( qr{^\Q/robots.txt} ) ),
                    methods( path => re( qr{^\Q/sitemap.xml} ) ),
                    # Page we added before_build_write exists
                    methods( path => re( qr{^\Q/foo/bar/baz.html} ) ),
                ),
                'page paths are correct';
        }, @_;
    } );

    my @pages = $site->pages;

    ok scalar( grep { $_->path eq '/foo/bar/baz.html' } @pages ),
        'page added in before_build_write exists';

    my ( $sitemap ) = grep { $_->path eq '/sitemap.xml' } @pages;
    my $sitemap_dom = Mojo::DOM->new( $sitemap->content );
    is $sitemap_dom->find( 'loc' )->grep( sub { $_->text eq '/foo/bar/baz.html' } )->size, 1,
        'page added in before_build_write added to sitemap.xml';
};

subtest 'pages' => sub {

    my $site = Statocles::Site->new(
        deploy => TestDeploy->new,
        index => '/foo/other.html',
        base_url => 'http://example.com',
        apps => {
            base => TestApp->new(
                url_root => '/',
                pages => [
                    {
                        class => 'Statocles::Page::Plain',
                        path => '/foo/other.html',
                        date => '2018-01-01',
                        content => join "\n",
                            '<a href="http://example.com">Full</a>',
                            '<a href="#anchor">Anchor</a>',
                            '<a href="index.html">Relative</a>',
                    },
                    {
                        class => 'Statocles::Page::Plain',
                        path => '/foo/index.html',
                        date => '2018-01-01',
                        content => join "\n",
                            '<a href="/foo/other.html">Index</a>',
                            '<a href="other.html">Relative</a>',
                    },
                    {
                        class => 'Statocles::Page::File',
                        path => '/static.txt',
                        file_path => $SHARE_DIR->child( qw( app basic static.txt ) ),
                    },
                ],
            ),
        },
    );

    my @pages = $site->pages;

    my ( $index_page ) = grep { $_->path eq '/index.html' } @pages;
    ok $index_page, 'site index renames app page';
    ok !scalar( grep { $_->path eq '/foo/other.html' } @pages ),
        'site index renames app page';

    subtest 'links on index page are correct' => sub {
        my $dom = $index_page->dom;
        ok $dom->at( '[href=http://example.com]' ), 'full url is not rewritten';
        ok $dom->at( '[href=#anchor]' ), 'anchor is not rewritten';
        ok $dom->at( '[href=/foo/index.html]' ), 'relative url on index is rewritten';
    };

    subtest 'links to index page are correct' => sub {
        my ( $nonindex_page ) = grep { $_->path eq '/foo/index.html' } @pages;
        my $dom = $nonindex_page->dom;
        ok !$dom->at( '[href=/foo/other.html]' ), 'no link to /foo/other.html';
        ok $dom->at( '[href=/]' ), 'link to index fixed';
    };

    subtest 'sitemap.xml' => sub {
        my ( $robots ) = grep { $_->path eq '/robots.txt' } @pages;

        cmp_deeply
            [ grep { /\S/ } split qr{\n}, $robots->content ],
            [
                "Sitemap: http://example.com/sitemap.xml",
                "User-Agent: *",
                "Disallow:",
            ] or diag explain $robots->content;
    };

    subtest 'robots.txt' => sub {
        my @expect = sort { $a->{loc} cmp $b->{loc} }
            (
                {
                    loc => 'http://example.com/',
                    changefreq => 'weekly',
                    priority => '0.5',
                    lastmod => '2018-01-01',
                },
                {
                    loc => 'http://example.com/foo/',
                    changefreq => 'weekly',
                    priority => '0.5',
                    lastmod => '2018-01-01',
                },
            );

        my $to_href = sub {
            my $lastmod = $_->at('lastmod');
            return {
                loc => $_->at('loc')->text,
                changefreq => $_->at('changefreq')->text,
                priority => $_->at('priority')->text,
                ( $lastmod ? ( lastmod => $lastmod->text ) : () ),
            };
        };

        my ( $sitemap ) = grep { $_->path eq '/sitemap.xml' } @pages;
        my $dom = Mojo::DOM->new( $sitemap->content );
        if ( ok my $elem = $dom->at('urlset'), 'urlset exists' ) {;
            my @urls = $dom->at('urlset')->children->map( $to_href )->each;
            cmp_deeply \@urls, \@expect or diag explain \@urls, \@expect;
        }
    };

};

subtest 'nav' => sub {
    my $site = Statocles::Site->new(
        base_url => 'http://example.com',
        deploy => TestDeploy->new,
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

subtest 'url method' => sub {
    my $site = Statocles::Site->new(
        deploy => TestDeploy->new,
        base_url => 'http://example.com/',
    );

    subtest 'domain only' => sub {
        my $site = Statocles::Site->new(
            deploy => TestDeploy->new,
            base_url => 'http://example.com/',
        );
        is $site->url( '/blog/2014/01/01/a-page.html' ),
           'http://example.com/blog/2014/01/01/a-page.html';
        subtest 'index.html is removed' => sub {
            is $site->url( '/index.html' ),
               'http://example.com/';
        };
    };

    subtest 'domain and folder' => sub {
        my $site = Statocles::Site->new(
            deploy => TestDeploy->new,
            base_url => 'http://example.com/folder',
        );
        is $site->url( '/blog/2014/01/01/a-page.html' ),
           'http://example.com/folder/blog/2014/01/01/a-page.html';
        subtest 'index.html is removed' => sub {
            is $site->url( '/index.html' ),
               'http://example.com/folder/';
        };
    };

    subtest 'stores with base_url' => sub {
        my $site = Statocles::Site->new(
            deploy => TestDeploy->new,
        );

        is $site->url( '/blog/2014/01/01/a-page.html' ), '/blog/2014/01/01/a-page.html';
        subtest 'index.html is removed' => sub {
            is $site->url( '/index.html' ), '/';
        };

        subtest 'current writing deploy overrides site base url' => sub {
            $site->base_url( 'http://example.com/' );
            is $site->url( '/blog/2014/01/01/a-page.html' ), 'http://example.com/blog/2014/01/01/a-page.html';
            subtest 'index.html is removed' => sub {
                is $site->url( '/index.html' ), 'http://example.com/';
            };
        };
    };
};

subtest 'template' => sub {

    subtest 'default templates' => sub {
        my $site = Statocles::Site->new(
            deploy => TestDeploy->new,
        );

        subtest 'meta template' => sub {
            my $tmpl = $site->template( 'robots.txt' );
            isa_ok $tmpl, 'Statocles::Template';
            is $tmpl->path, 'site/robots.txt.ep';
        };

        subtest 'layout template' => sub {
            my $tmpl = $site->template( 'layout.html' );
            isa_ok $tmpl, 'Statocles::Template';
            is $tmpl->path, 'layout/default.html.ep';
        };

    };

    subtest 'overrides' => sub {
        my $site = Statocles::Site->new(
            deploy => TestDeploy->new,
            theme => $SHARE_DIR->child( 'theme' ),
            templates => {
                'robots.txt' => 'custom/robots.txt',
                'layout.html' => 'custom/layout.html',
            },
        );

        subtest 'app template' => sub {
            my $tmpl = $site->template( 'robots.txt' );
            isa_ok $tmpl, 'Statocles::Template';
            is $tmpl->path, 'custom/robots.txt.ep';
        };

        subtest 'layout template' => sub {
            my $tmpl = $site->template( 'layout.html' );
            isa_ok $tmpl, 'Statocles::Template';
            is $tmpl->path, 'custom/layout.html.ep';
        };
    };
};

subtest 'error messages' => sub {

    subtest 'index directory does not exist' => sub {
        throws_ok {
            Statocles::Site->new(
                title => 'Example Site',
                build_store => tempdir,
                deploy => tempdir,
                index => '/DOES_NOT_EXIST',
            )->pages;
        } qr{\QERROR: Index path "/DOES_NOT_EXIST" does not exist. Do you need to create "/DOES_NOT_EXIST/index.markdown"?},
        'error message is correct';
    };

    subtest 'index file does not exist' => sub {
        throws_ok {
            Statocles::Site->new(
                title => 'Example Site',
                build_store => tempdir,
                deploy => tempdir,
                index => '/DOES_NOT_EXIST.html',
            )->pages;
        } qr{\QERROR: Index path "/DOES_NOT_EXIST.html" does not exist. Do you need to create "/DOES_NOT_EXIST.markdown"?},
        'error message is correct';
    };

    subtest 'two apps build pages with same path' => sub {
        local $ENV{MOJO_LOG_LEVEL} = "warn";

        my $basic_app = TestApp->new(
            url_root => '/',
            pages => [
                {
                    path => '/index.html',
                    content => '<h1>Index Page</h1>',
                },
            ],
        );
        my $static_app = TestApp->new(
            url_root => '/',
            pages => [
                {
                    class => 'Statocles::Page::File',
                    path => '/index.html',
                    file_path => $SHARE_DIR->child( 'store/docs/required.markdown' ),
                },
            ],
        );

        my $site = Statocles::Site->new(
            deploy => TestDeploy->new,
            apps => { basic => $basic_app, static => $static_app },
        );

        my ( $out, $err, @pages ) = capture { $site->pages };
        like $err, qr{\Q[warn] Duplicate page "/index.html" from apps: basic, static. Using basic};
        ok !$out or diag $out;

        # This test will only fail randomly if it fails, because of hash ordering
        my ( $index_page ) = grep { $_->path eq '/index.html' } @pages;
        is $index_page->dom->at('h1')->text, 'Index Page', q{basic app always wins because it's generated};
    };

    subtest 'single app generates two pages with the same path' => sub {
        my $app = TestApp->new(
            url_root => '/',
            pages => [
                {
                    path => '/index.html',
                    content => 'Index',
                },
                {
                    path => '/foo.html',
                    content => 'Foo',
                },
                {
                    path => '/foo.html',
                    content => 'Bar',
                },
            ],
        );

        my $site = Statocles::Site->new(
            apps => { test => $app },
            deploy => TestDeploy->new,
        );

        my ( $out, $err, @pages ) = capture { $site->pages };
        like $err, qr{\Q[warn] Duplicate page with path "/foo.html" from app "test"};
        ok !$out or diag $out;
    };

};



done_testing;

