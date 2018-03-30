
use Test::Lib;
use My::Test;
use Statocles::Site;
use Statocles::Theme;
use Statocles::Store;
my $SHARE_DIR = path( __DIR__, '..', 'share' );

my %required = (
    deploy => '.',
);

test_constructor(
    'Statocles::Site',
    required => \%required,
    default => {
        index => '/',
        theme => Statocles::Theme->new( store => '::default' ),
    },
);

done_testing;
