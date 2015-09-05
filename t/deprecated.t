
use Statocles::Base 'Test';
my $site = Statocles::Site->new( deploy => tempdir );

subtest 'Statocles::Site index app' => sub {
    require Mojo::DOM;
    my $SHARE_DIR = path( __DIR__, 'share' );

    subtest 'deprecation message' => sub {
        my $log_str;
        open my $log_fh, '>', \$log_str;
        my $log = Mojo::Log->new( level => 'warn', handle => $log_fh );

        my ( $site, $build_dir, $deploy_dir ) = build_test_site_apps(
            $SHARE_DIR,
            index => 'blog',
            log => $log,
        );

        subtest 'build' => sub {
            $site->build;

            ok $build_dir->child( 'index.html' )->exists,
                'site index renames app page';
            ok !$deploy_dir->child( 'index.html' )->exists, 'not deployed yet';
            ok !$build_dir->child( 'blog', 'index.html' )->exists,
                'site index renames app page';

            my $dom = Mojo::DOM->new( $build_dir->child( '/blog/page/2/index.html' )->slurp_utf8 );
            ok !$dom->at( '[href=/blog]' ), 'no link to /blog';
            ok !$dom->at( '[href=/blog/index.html]' ), 'no link to /blog/index.html';
        };

        like $log_str, qr{\Q[warn] site "index" property should be absolute path to index page (got "blog")};
    };

    subtest 'error messages' => sub {

        subtest 'index_app does not give any pages' => sub {
            my $log_str;
            open my $log_fh, '>', \$log_str;
            my $log = Mojo::Log->new( level => 'warn', handle => $log_fh );

            # Empty Static app
            my $tmpdir = tempdir;
            my $static = Statocles::App::Static->new(
                store => $tmpdir,
                url_root => '/static',
            );

            my ( $site ) = build_test_site_apps(
                $SHARE_DIR,
                apps => {
                    static => $static,
                },
                index => 'static',
                log => $log,
            );

            throws_ok { $site->build } qr{ERROR: Index app "static" did not generate any pages};
        };

    };

};

subtest 'Statocles::Store::File' => sub {
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    eval { require Statocles::Store::File; };
    if ( $Statocles::VERSION < 1 ) {
        like $warnings[0], qr{\QStatocles::Store::File is deprecated and will be removed in v1.000. Please use Statocles::Store instead. See Statocles::Help::Upgrading for more information.};
    }
    else {
        ok $@, 'Statocles::Store::File failed to load';
        ok !$INC{'Statocles/Store/File.pm'}, 'Statocles::Store::File is not loaded';
    }
};

subtest 'Statocles::Store->write_* should not return anything' => sub {
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    require Statocles::Store;
    my $store = Statocles::Store->new(
        path => tempdir,
    );
    my $foo = $store->write_document( 'test' => { foo => 'bar' } );
    if ( $Statocles::VERSION < 1 ) {
        like $warnings[0], qr{\QStatocles::Store->write_document returning a value is deprecated and will be removed in v1.0. Use Statocles::Store->path to find the full path to the document.};
        is $foo, $store->path->child( 'test' );
    }
    else {
        ok !@warnings, 'warning was removed';
        ok !$foo, 'value was not returned';
    }
};

done_testing;
