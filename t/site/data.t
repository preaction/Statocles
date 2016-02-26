
use Test::Lib;
use My::Test;
my $SHARE_DIR = path( __DIR__, '..', 'share' );

my ( $site, $build_dir, $deploy_dir ) = build_test_site_apps(
    $SHARE_DIR,
    base_url => 'http://example.com/test',
    deploy => {
        base_url => 'http://example.com',
    },
    data => {
        profile_url => '/profile',
    },
);

sub test_page_content {
    my ( $site, $page, $dir, $deploy ) = @_;

    my $base_url = Mojo::URL->new( $deploy ? $deploy->base_url : $site->base_url );
    my $base_path = $base_url->path;
    $base_path =~ s{/$}{};

    my $path = $dir->child( $page->path );
    my $got_dom = Mojo::DOM->new( $path->slurp );

    if ( ok my $footer_link = $got_dom->at( 'footer a' ) ) {
        is $footer_link->attr( 'href' ),
            join( "", $base_path, $site->data->{profile_url} ),
            'data is correct and rewritten for site root';
    }
}

subtest 'build' => sub {
    $site->build;

    for my $page ( $site->app( 'blog' )->pages ) {
        next unless $page->path =~ /[.]html$/;
        subtest 'data in ' . $page->path
            => \&test_page_content, $site, $page, $build_dir;
        ok !$deploy_dir->child( $page->path )->exists, $page->path . ' not deployed yet';
    }

};

subtest 'deploy' => sub {
    $site->deploy;

    for my $page ( $site->app( 'blog' )->pages ) {
        next unless $page->path =~ /[.]html$/;
        subtest 'data in ' . $page->path
            => \&test_page_content, $site, $page, $deploy_dir, $site->_deploy;
    }

};

done_testing;
