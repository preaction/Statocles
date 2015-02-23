
use Statocles::Base 'Test';
use Statocles::App::Static;

my $SHARE_DIR = path( __DIR__ )->parent->parent->child( 'share' );
my $site = build_test_site(
    theme => $SHARE_DIR->child( 'theme' ),
);

test_constructor(
    "Statocles::App::Static",
    required => {
        url_root => '/',
        store => $SHARE_DIR->child( qw( app static ) ),
    },
);

done_testing;
