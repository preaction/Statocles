
use Statocles::Base 'Test';

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

done_testing;
