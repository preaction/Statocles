
use Test::Lib;
use My::Test;
use Statocles::Site;
my $SHARE_DIR = path( __DIR__, '..', 'share' );

my ( $site, $build_dir, $deploy_dir ) = build_test_site_apps( $SHARE_DIR );

sub test_page_content {
    my ( $site, $page, $dir ) = @_;
    my $elem;
    my $path = $dir->child( $page->path );

    if ( $path =~ /[.]html$/ ) {
        my $got_dom = Mojo::DOM->new( $path->slurp );

        if ( ok $elem = $got_dom->at('title'), 'has title' ) {
            like $elem->text, qr{@{[$site->title]}}, 'page contains site title ' . $site->title;
        }
    }
    else {
        ok $path->exists, 'path exists at least';
    }
}

sub test_base_url {
    my ( $base_url, $page, $dir ) = @_;
    my $elem;
    my $path = $dir->child( $page->path );
    my $got_dom = Mojo::DOM->new( $path->slurp );

    my $site_path = Mojo::URL->new( $base_url )->path;
    $site_path =~ s{/$}{};
    my @links = $got_dom->find( 'head > link' )->each;
    is $links[0]->attr( 'href' ), $site_path . '/theme/css/normalize.css';
    is $links[1]->attr( 'href' ), '//cdn.example.com/css/cdn.css';

    if ( ok $elem = $got_dom->at( '.brand' ), 'has brand' ) {
        is $elem->attr( 'href' ), $site_path . '/',
            'single "/" is replaced with base_url ' . $site_path;
    }
}

subtest 'build' => sub {
    cmp_deeply $site->pages, [], 'page cache is empty until a build';

    $site->build;

    my @pages;
    for my $page ( $site->app( 'blog' )->pages, $site->app( 'basic' )->pages ) {
        ok $build_dir->child( $page->path )->exists, $page->path . ' built';
        ok !$deploy_dir->child( $page->path )->exists, $page->path . ' not deployed yet';
        push @pages, $page->path;
    }

    subtest 'check theme' => sub {
        my $iter = $site->theme->store->iterator;
        while ( my $obj = $iter->() ) {
            next if $obj->path =~ /[.]ep$/;
            my $path = path( 'theme' => $obj->path );
            ok $build_dir->child( $path )->exists,
                'theme file ' . $path . ' exists in build dir';
            eq_or_diff
                $build_dir->child( $path )->slurp_utf8,
                $site->theme->store->path->child( $obj->path )->slurp_utf8,
                'theme file ' . $obj->path . ' content is correct';
            ok !$deploy_dir->child( $path )->exists,
                'theme file ' . $obj->path . 'not in deploy dir';
            push @pages, $path;
        }
    };

    # Add 2 pages for robots.txt and sitemap.xml
    is scalar @{ $site->pages }, scalar @pages + 2, 'cached page count is correct';

    subtest 'build deletes files before building' => sub {
        $build_dir->child( 'DELETE_ME' )->spew( "This should be deleted" );
        $site->build;
        ok !$build_dir->child( 'DELETE_ME' )->exists, 'unbuilt file is deleted';
        for my $path ( @pages ) {
            ok $build_dir->child( $path )->exists, $path . ' built';
        }
    };

};

subtest 'deploy' => sub {
    $site->deploy;

    for my $page ( $site->app( 'blog' )->pages, $site->app( 'basic' )->pages ) {
        ok $build_dir->child( $page->path )->exists, $page->path . ' built';
        ok $deploy_dir->child( $page->path )->exists, $page->path . ' deployed';
    }

    subtest 'check theme' => sub {
        my $iter = $site->theme->store->iterator;
        while ( my $obj = $iter->() ) {
            next if $obj->path =~ /[.]ep$/;
            ok $deploy_dir->child( 'theme', $obj->path )->exists,
                'theme file ' . $obj->path . 'exists in deploy dir';
            eq_or_diff
                $build_dir->child( theme => $obj->path )->slurp_utf8,
                $site->theme->store->path->child( $obj->path )->slurp_utf8,
                'theme file ' . $obj->path . ' content is correct';
        }
    };

};

subtest 'base URL with folder rewrites content' => sub {
    my ( $site, $build_dir, $deploy_dir ) = build_test_site_apps(
        $SHARE_DIR,
        base_url => '/', # The default
        deploy => {
            base_url => 'http://example.com/deploy/',
        },
    );

    subtest 'build' => sub {
        $site->build;

        for my $page ( $site->app( 'blog' )->pages ) {
            subtest 'page content: ' . $page->path
                => \&test_page_content, $site, $page, $build_dir;

            if ( $page->path =~ /[.]html$/ ) {
                subtest 'base url: ' . $page->path
                    => \&test_base_url, '/', $page, $build_dir;
            }

            ok !$deploy_dir->child( $page->path )->exists, 'not deployed yet';
        }

    };

    subtest 'deploy' => sub {
        $site->deploy;

        for my $page ( $site->app( 'blog' )->pages ) {
            subtest 'page content: ' . $page->path
                => \&test_page_content, $site, $page, $deploy_dir;

            if ( $page->path =~ /[.]html$/ ) {
                subtest 'base url: ' . $page->path
                    => \&test_base_url, 'http://example.com/deploy', $page, $deploy_dir;
            }
        }

    };
};

done_testing;
