
use Test::Lib;
use My::Test;
my $SHARE_DIR = path( __DIR__, '..', 'share' );

my ( $site, $build_dir, $deploy_dir ) = build_test_site_apps(
    $SHARE_DIR,
    base_url => 'http://example.com',
    deploy => {
        base_url => 'http://example.com',
    },
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

sub test_nav_content {
    my ( $site, $page, $dir, $deploy ) = @_;

    my $base_url = Mojo::URL->new( $deploy ? $deploy->base_url : $site->base_url );
    my $base_path = $base_url->path;
    $base_path =~ s{/$}{};

    my $path = $dir->child( $page->path );
    my $got_dom = Mojo::DOM->new( $path->slurp );
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
}

my $blog = $site->app( 'blog' );

subtest 'build' => sub {
    $site->build;
    for my $page ( $blog->pages ) {
        next unless $page->path =~ /[.]html$/;
        subtest 'site index content: ' . $page->path
            => \&test_nav_content, $site, $page, $build_dir;
    }
};

subtest 'deploy' => sub {
    $site->deploy;
    for my $page ( $blog->pages ) {
        next unless $page->path =~ /[.]html$/;
        subtest 'site index content: ' . $page->path
            => \&test_nav_content, $site, $page, $deploy_dir, $site->_deploy;
    }
};

done_testing;
