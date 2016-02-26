
use Test::Lib;
use My::Test;
use Statocles::App::Basic;

my $SHARE_DIR = path( __DIR__ )->parent->parent->child( 'share' );
my $site = build_test_site(
    theme => $SHARE_DIR->child( 'theme' ),
);

test_constructor(
    "Statocles::App::Basic",
    required => {
        url_root => '/',
        store => $SHARE_DIR->child( qw( app basic ) ),
    },
);

done_testing;
