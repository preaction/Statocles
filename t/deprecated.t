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
            my @pages = $site->pages;

            ok scalar( grep { $_->path eq '/index.html' } @pages ),
                'site index renames app page';
            ok !scalar( grep { $_->path eq '/blog/index.html' } @pages ),
                'site index renames app page';

            my ( $page ) = grep { $_->path eq '/blog/page/2/index.html' } @pages;
            my $dom = $page->dom;
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

            throws_ok { $site->pages } qr{ERROR: Index app "basic" did not generate any pages};
        };

    };

};

subtest 'Statocles::Store::File' => sub {
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    eval { require Statocles::Store::File; };
    if ( $Statocles::VERSION < 1 ) {
        like $warnings[0], qr{\QStatocles::Store::File is deprecated and will be removed in v1.000. Please use Statocles::Store instead. See Statocles::Help::Upgrading};
    }
    else {
        ok $@, 'Statocles::Store::File failed to load';
        ok !$INC{'Statocles/Store/File.pm'}, 'Statocles::Store::File is not loaded';
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
            %Statocles::Util::DERPED = ();
        };

        subtest 'command shows warning' => sub {
            my @warnings;
            local $SIG{__WARN__} = sub { push @warnings, @_ };
            capture {
                $app->command( 'name', 'help' );
            };
            like $warnings[0], qr{\QStatocles::App::Plain has been renamed to Statocles::App::Basic and will be removed in 2.0. Change the app class to "Statocles::App::Basic" to silence this message.}, 'warn on pages method';
            %Statocles::Util::DERPED = ();
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

subtest 'Statocles::Test::test_pages' => sub {
    require Statocles::Test;
    if ( $Statocles::VERSION < 1 ) {
        my @warnings;
        ok( Statocles::Test->can('test_pages'), 'test_pages function exists' )
          or return;
        local $@;
        eval "
        package Statocles::App::MockTest;
        use Statocles::Base 'Class';
        with 'Statocles::Role::App';
        sub pages { return () }
        1
      " or die "Cant construct a Statocles::Role::App: $@";

        my $site = build_test_site();

        my $app = Statocles::App::MockTest->new( url_root => '/' );

        local $SIG{__WARN__} = sub { push @warnings, @_ };
        Statocles::Test::test_pages( $site, $app, {} );
        like $warnings[0], qr{\QStatocles::Test::test_pages is deprecated and will be removed in v1.000},
          'warn on test_constructor function';
    }
    else {
        ok(
            !Statocles::Test->can('test_pages'),
            'test_pages function does not exist'
        );
    }
};

subtest 'data attributes that are not hashes' => sub {
    require Statocles::Document;
    if ( $Statocles::VERSION < 2 ) {
      my @warnings;
      local $SIG{__WARN__} = sub { push @warnings, @_ };
      Statocles::Document->new( path => '/foo/bar', data => [] );
      like $warnings[-1], qr{\QInvalid data attribute in document "/foo/bar".},
        'arrayref warns';
      Statocles::Document->new( path => '/foo/bar', data => 0 );
      like $warnings[-1], qr{\QInvalid data attribute in document "/foo/bar".},
        'nonref warns';
    }
    else {
        dies_ok { Statocles::Document->new( data => [] ) } 'arrayref not allowed';
        dies_ok { Statocles::Document->new( data => 0 ) } 'nonref not allowed';
    }
};

subtest 'default layout should be layout/default.html.ep not site/layout.html.ep' => sub {
    require Statocles::Site;
    if ( $Statocles::VERSION < 2 ) {
        my $theme = tempdir();
        $theme->child( 'site', 'layout.html.ep' )->touchpath;
        my @warnings;
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        my $site = Statocles::Site->new(
            theme => $theme,
            deploy => tempdir,
        );
        $site->template( 'layout.html' );
        like $warnings[-1], qr{\QUsing default layout "site/layout.html.ep" is deprecated},
            'default template warns';
        $site->template( 'layout.html' );
        is scalar @warnings, 1, 'only warn about default layout once';
    }
    else {
        dies_ok { } 'layout/default.html.ep does not exist';
    }
};

done_testing;
