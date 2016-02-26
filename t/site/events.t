
use Test::Lib;
use My::Test;
use Statocles::Page::Plain;
my $SHARE_DIR = path( __DIR__, '..', 'share' );

subtest 'build events' => sub {
    my ( $site, $build_dir, $deploy_dir ) = build_test_site_apps( $SHARE_DIR );

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
                    methods( path => re( qr{^\Q/blog/2014/04/23/slug/index.html} ) ),
                    methods( path => re( qr{^\Q/blog/2014/04/30/plug/index.html} ) ),
                    methods( path => re( qr{^\Q/blog/2014/06/02/more_tags/index.html} ) ),
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

    $site->build;

    ok $build_dir->child( qw( foo bar baz.html ) )->exists,
        'page added in before_build_write exists';
    my $sitemap_dom = Mojo::DOM->new( $build_dir->child( 'sitemap.xml' )->slurp_utf8 );
    is $sitemap_dom->find( 'loc' )->grep( sub { $_->text eq '/foo/bar/baz.html' } )->size, 1,
        'page added in before_build_write added to sitemap.xml';
};

done_testing;
