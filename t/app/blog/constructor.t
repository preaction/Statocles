
use Test::Lib;
use My::Test;
use Statocles::App::Blog;
my $SHARE_DIR = path( __DIR__ )->parent->parent->child( 'share' );

my $site = build_test_site(
    theme => $SHARE_DIR->child( 'theme' ),
    store => $SHARE_DIR->child( qw( app ) ),
);

my %required = (
    url_root => '/blog',
);

test_constructor(
    'Statocles::App::Blog',
    required => \%required,
    default => {
        page_size => 5,
        index_tags => [],
    },
);

done_testing;
