
use Statocles::Base 'Test';
use Statocles::App::Plain;

my $SHARE_DIR = path( __DIR__ )->parent->parent->child( 'share' );
my $site = build_test_site(
    theme => $SHARE_DIR->child( 'theme' ),
);

test_constructor(
    "Statocles::App::Plain",
    required => {
        url_root => '/',
        store => $SHARE_DIR->child( qw( app plain ) ),
    },
);

done_testing;
