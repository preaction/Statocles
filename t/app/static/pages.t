
use Statocles::Base 'Test';
use Statocles::App::Static;

my $SHARE_DIR = path( __DIR__ )->parent->parent->child( 'share' );
my $site = build_test_site(
    theme => $SHARE_DIR->child( 'theme' ),
);

my %pages = (
    '/static.txt' => sub {
        my ( $text ) = @_;
        eq_or_diff $text, $SHARE_DIR->child( qw( app static static.txt ) )->slurp_utf8;
    },

    '/static.markdown' => sub {
        my ( $text ) = @_;
        eq_or_diff $text, $SHARE_DIR->child( qw( app static static.markdown ) )->slurp_utf8;
    },
);

my $app = Statocles::App::Static->new(
    url_root => '/',
    store => $SHARE_DIR->child( qw( app static ) ),
);

test_pages( $site, $app, { noindex => 1 }, %pages );

subtest 'non-root app' => sub {
    my $app = Statocles::App::Static->new(
        url_root => '/nonroot',
        store => $SHARE_DIR->child( qw( app static ) ),
    );

    test_pages(
        $site, $app, { noindex => 1 },

        ( map {; "/nonroot$_" => $pages{ $_ } } keys %pages ),
    );

};

done_testing;
