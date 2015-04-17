
use Statocles::Base 'Test';
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

    if ( ok $elem = $got_dom->at( 'head > link' ), 'has stylesheet' ) {
        my $site_path = Mojo::URL->new( $base_url )->path;
        $site_path =~ s{/$}{};
        is $elem->attr( 'href' ), $site_path . '/theme/css/normalize.css';
    }
}

subtest 'build' => sub {
    $site->build;

    my @pages;
    for my $page ( $site->app( 'blog' )->pages, $site->app( 'static' )->pages ) {
        ok $build_dir->child( $page->path )->exists, $page->path . ' built';
        ok !$deploy_dir->child( $page->path )->exists, $page->path . ' not deployed yet';
        push @pages, $page->path;
    }

    subtest 'check static content' => sub {
        for my $page ( $site->app( 'static' )->pages ) {
            my $fh = $page->render;
            my $content = do { local $/; <$fh> };
            ok $build_dir->child( $page->path )->slurp_raw eq $content,
                $page->path . ' content is correct';
            ok !$deploy_dir->child( $page->path )->exists,
                $page->path . ' is not deployed';
            push @pages, $page->path;
        }
    };

    subtest 'check theme' => sub {
        my $iter = $site->theme->store->find_files;
        while ( my $theme_file = $iter->() ) {
            my $path = path( 'theme' => $theme_file );
            ok $build_dir->child( $path )->exists,
                'theme file ' . $theme_file . 'exists in build dir';
            ok !$deploy_dir->child( $path )->exists,
                'theme file ' . $theme_file . 'not in deploy dir';
            push @pages, $path;
        }
    };

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

    for my $page ( $site->app( 'blog' )->pages, $site->app( 'static' )->pages ) {
        ok $build_dir->child( $page->path )->exists, $page->path . ' built';
        ok $deploy_dir->child( $page->path )->exists, $page->path . ' deployed';
    }

    subtest 'check static content' => sub {
        for my $page ( $site->app( 'static' )->pages ) {
            my $fh = $page->render;
            my $content = do { local $/; <$fh> };
            ok $deploy_dir->child( $page->path )->slurp_raw eq $content,
                $page->path . ' content is correct';
        }
    };

    subtest 'check theme' => sub {
        my $iter = $site->theme->store->find_files;
        while ( my $theme_file = $iter->() ) {
            ok $deploy_dir->child( 'theme', $theme_file )->exists,
                'theme file ' . $theme_file . 'exists in deploy dir';
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

        subtest 'check static content' => sub {
            for my $page ( $site->app( 'static' )->pages ) {
                my $fh = $page->render;
                my $content = do { local $/; <$fh> };
                is $build_dir->child( $page->path )->slurp_raw, $content,
                    $page->path . ' content is correct';
            }
        };

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

        subtest 'check static content' => sub {
            for my $page ( $site->app( 'static' )->pages ) {
                my $fh = $page->render;
                my $content = do { local $/; <$fh> };
                is $deploy_dir->child( $page->path )->slurp_raw, $content,
                    $page->path . ' content is correct';
            }
        };

    };
};

done_testing;
