
# This test ensures that the blog posts are evaluated according to the
# current local date/time, not UTC, so that today's posts are shown even
# if it's still yesterday in UTC.
#
# See https://github.com/preaction/Statocles/issues/474

my ( $y, $m, $d );
BEGIN {
    $ENV{TZ} = "Australia/Sydney";
    ( undef, undef, undef, $d, $m, $y ) = localtime( 1458949291 );
    $y += 1900;
    $m = sprintf "%02d", $m + 1;
    $d = sprintf "%02d", $d;
    *CORE::GLOBAL::time = \&my_time;
};

# 1458949291
# GMT: Fri Mar 25 23:41:31 2016
# Sydney: Sat Mar 26 10:41:31 2016
sub my_time() { 1458949291 }

use Test::Lib;
use My::Test;
use TestStore;

use Statocles::App::Blog;
my $SHARE_DIR = path( __DIR__ )->parent->parent->child( 'share' );

my $site = build_test_site(
    store => TestStore->new(
        path => tempdir,
        objects => [
            Statocles::Document->new(
                path => Mojo::Path->new->parts( [ $y, $m, $d, 'post', 'index.markdown' ] ),
                content => '',
            ),
        ],
    ),
    theme => $SHARE_DIR->child( 'theme' ),
    base_url => 'http://example.com/',
);

my $app = Statocles::App::Blog->new(
    site => $site,
    url_root => '/',
);

my $expect_path = join "/", $y, $m, $d, 'post', 'index.html';

my @pages = $site->pages;
ok +( grep { $_->path eq $expect_path } @pages ), "today's post was added correctly"
    or diag "Found pages: ", explain [ map { $_->path } @pages ];

done_testing;
