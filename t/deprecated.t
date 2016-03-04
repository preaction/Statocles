use Test::Lib;
use My::Test;
use Statocles::Site;
use Capture::Tiny qw( capture );
my $SHARE_DIR = path( __DIR__ )->child( 'share' );
my $site = Statocles::Site->new(
    deploy => tempdir,
    theme => $SHARE_DIR->child( 'theme' ),
);

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
            my $static = Statocles::App::Basic->new(
                store => $tmpdir,
                url_root => '/static',
            );

            my ( $site ) = build_test_site_apps(
                $SHARE_DIR,
                apps => {
                    basic => $static,
                },
                index => 'basic',
                log => $log,
            );

            throws_ok { $site->build } qr{ERROR: Index app "basic" did not generate any pages};
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

subtest 'Statocles::App::Plain' => sub {

    if ( $Statocles::VERSION < 2 ) {
        require Statocles::App::Plain;
        my $app = Statocles::App::Plain->new(
            url_root => '/',
            site => $site,
            store => $SHARE_DIR->child( qw( app basic ) ),
        );

        subtest 'pages shows warning' => sub {
            my @warnings;
            local $SIG{__WARN__} = sub { push @warnings, @_ };
            $app->pages;
            like $warnings[0], qr{\QStatocles::App::Plain has been renamed to Statocles::App::Basic and will be removed in 2.0. Change the app class to "Statocles::App::Basic" to silence this message.}, 'warn on pages method';
        };

        subtest 'command shows warning' => sub {
            my @warnings;
            local $SIG{__WARN__} = sub { push @warnings, @_ };
            capture {
                $app->command( 'name', 'help' );
            };
            like $warnings[0], qr{\QStatocles::App::Plain has been renamed to Statocles::App::Basic and will be removed in 2.0. Change the app class to "Statocles::App::Basic" to silence this message.}, 'warn on pages method';
        };
    }
    else {
        eval { require Statocles::App::Plain; };
        ok $@, 'unable to load Statocles::App::Plain because it was deleted';
    }
};

subtest 'Statocles::App::Static' => sub {

    if ( $Statocles::VERSION < 2 ) {
        require Statocles::App::Static;
        my $app = Statocles::App::Static->new(
            url_root => '/',
            site => $site,
            store => $SHARE_DIR->child( qw( app basic ) ),
        );

        subtest 'pages shows warning' => sub {
            my @warnings;
            local $SIG{__WARN__} = sub { push @warnings, @_ };
            $app->pages;
            like $warnings[0], qr{\QStatocles::App::Static has been replaced by Statocles::App::Basic and will be removed in 2.0. Change the app class to "Statocles::App::Basic" to silence this message.}, 'warn on pages method';
        };
    }
    else {
        eval { require Statocles::App::Static; };
        ok $@, 'unable to load Statocles::App::Static because it was deleted';
    }
};

subtest 'tzoffset shim' => sub {
    use Statocles::Types qw( DateTimeObj );
    if ( $Statocles::VERSION < 2 ) {
        my $dt = DateTimeObj->coerce( '2015-01-01' );
        ok $dt->can( 'tzoffset' ), 'tzoffset method exists';

        my @warnings;
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        is $dt->tzoffset, 0, 'tzoffset is correct';
        like $warnings[0], qr{\QThe tzoffset shim method will be removed in Statocles version 2.0. See Statocles::Help::Upgrading for instructions to remove this warning.}, 'warn on tzoffset method';
    }
    else {
        my $dt = DateTimeObj->coerce( '2015-01-01' );
        ok !$dt->can( 'tzoffset' ), 'tzoffset method does not exist';
    }
};

subtest 'Statocles::Base q[Test]' => sub {
    require Statocles::Base;
    if ( $Statocles::VERSION < 1 ) {
      ok( exists $Statocles::Base::IMPORT_BUNDLES{Test}, 'Test Bundle defined' ) or return;
      my @warnings;
      local $SIG{__WARN__} = sub { push @warnings, @_ };
      local $@;
      my $ok;
      eval {
          package T::My::Mock::Namespace;
          Statocles::Base->import('Test');
          $ok = 1;
      };
      ok( $ok, 'Importing Test did not fail' ) or  diag($@);
      like $warnings[0], qr{\QBundle Test deprecated and will be removed in v1.000, do not use},
        'Bundle test warns about deprecation';
    }
    else {
     ok( !exists $Statocles::Base::IMPORT_BUNDLES{Test}, 'Test Bundle not defined' );
    }
};

subtest 'Statocles::Test::test_constructor' => sub {
    require Statocles::Test;
    require Statocles::Link;
    if ( $Statocles::VERSION < 1 ) {
      my @warnings;
      ok( Statocles::Test->can('test_constructor'), 'test_constructor function exists' ) or return;
      local $SIG{__WARN__} = sub { push @warnings, @_ };
      Statocles::Test::test_constructor('Statocles::Link', required => { href => '/blog' } );
      like $warnings[0], qr{\QStatocles::Test::test_constructor is deprecated and will be removed in v1.000},
        'warn on test_constructor function';
    }
    else {
      ok( !Statocles::Test->can('test_constructor'), 'test_constructor function does not exist');
    }
};

done_testing;
