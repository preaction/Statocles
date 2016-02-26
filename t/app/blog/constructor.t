
use Test::Lib;
use My::Test;
use Statocles::App::Blog;
my $SHARE_DIR = path( __DIR__ )->parent->parent->child( 'share' );

my $site = build_test_site(
    theme => $SHARE_DIR->child( 'theme' ),
);

my %required = (
    store => $SHARE_DIR->child( qw( app blog ) ),
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

subtest 'attribute types/coercions' => sub {
    subtest 'store' => sub {
        my $app = Statocles::App::Blog->new( %required );
        ok $app->store->DOES( 'Statocles::Store' );
        is $app->store->path, $SHARE_DIR->child( qw( app blog ) );
    },

};

done_testing;
