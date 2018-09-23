
use Test::Lib;
use My::Test;
use Statocles::Theme;

# XXX: We should add this to t/theme/check.t instead to make sure that
# the theme's files get added as part of the site

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
    next if $path->basename =~ /^[.]/;
    next unless $path->is_file;
    next if $path =~ /[.]ep$/;
    my $rel_path = $path->relative( $SHARE_DIR->child( 'theme' ) );
    $pages{ "/theme/" . $rel_path } = sub {
        my ( $page ) = @_;
        is $page->path, '/theme/' . $rel_path, 'theme file path is correct';
    };
}
ok keys %pages, 'there are tests to perform';
test_page_objects( [ $site->pages ], %pages );

done_testing;

