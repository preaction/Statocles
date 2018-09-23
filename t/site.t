
use Test::Lib;
use My::Test;
use Capture::Tiny qw( capture );
use Statocles::Site;
use Statocles::Theme;
use Statocles::Store;
use TestDeploy;
use TestApp;
use TestStore;
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
        store => TestStore->new(
            path => '.',
            objects => [
                Statocles::Document->new(
                    path => '/extra.markdown',
                    content => 'Extra',
                ),
                Statocles::File->new(
                    path => '/image.jpg',
                ),
            ],
        ),
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
                    methods( path => re( qr{^\Q/image.jpg} ) ),
                    methods( path => re( qr{^\Q/extra.html} ) ),
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
                    methods( path => re( qr{^\Q/image.jpg} ) ),
                    methods( path => re( qr{^\Q/extra.html} ) ),
                    methods( path => re( qr{^\Q/index.html} ) ),
                    methods( path => re( qr{^\Q/static.txt} ) ),
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
        store => TestStore->new(
            path => '.',
            objects => [
                Statocles::Document->new(
                    path => '/extra.markdown',
                    date => '2018-01-01',
                    content => 'Extra',
                ),
                Statocles::File->new(
                    path => '/image.jpg',
                ),
            ],
        ),
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
                    loc => 'http://example.com/extra.html',
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


done_testing;

