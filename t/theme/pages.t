
use Statocles::Base 'Test';
use Statocles::Theme;

my $SHARE_DIR = path( __DIR__ )->parent->child( 'share' );
my $site = build_test_site(
    theme => $SHARE_DIR->child( 'theme' ),
);

my $app = Statocles::Theme->new(
    #url_root => '/theme',      # Default to /theme
    site => $site,
    store => $SHARE_DIR->child( qw( theme ) ),
);

my %pages;
my $iter = $SHARE_DIR->child( 'theme' )->iterator( { recurse => 1 } );
while ( my $path = $iter->() ) {
    next unless $path->is_file;
    my $rel_path = $path->relative( $SHARE_DIR->child( 'theme' ) );
    $pages{ "/theme/" . $rel_path } = sub {
        my ( $output ) = @_;
        eq_or_diff $output, $path->slurp_utf8, 'Theme file is correct: ' . $rel_path;
    };
}

test_pages( $site, $app, %pages );

done_testing;

