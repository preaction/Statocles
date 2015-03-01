
use Statocles::Base 'Test';
my $SHARE_DIR = path( __DIR__, '..', 'share' );

subtest 'build events' => sub {
    my ( $site, $build_dir, $deploy_dir ) = build_test_site_apps( $SHARE_DIR );
    my ( $event );
    $site->on( 'build', sub {
        pass "Build event fired during build";
        ( $event ) = @_;
    } );

    $site->build;

    isa_ok $event, 'Statocles::Event::Pages';
    ok scalar @{ $event->pages }, 'got some pages';
    cmp_deeply $event->pages,
        array_each(
            methods( path => re( qr{^/} ) )
        ),
        'all pages are absolute';

    cmp_deeply $event->pages,
        superbagof(
            methods( path => re( qr{^\Q/theme/site/layout.html.ep} ) ),
            methods( path => re( qr{^\Q/robots.txt} ) ),
            methods( path => re( qr{^\Q/sitemap.xml} ) ),
        ),
        'page paths are correct';

};

done_testing;
