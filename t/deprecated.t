
use Statocles::Base 'Test';
my $site = Statocles::Site->new( deploy => tempdir );

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
