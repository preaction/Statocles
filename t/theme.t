
=head1 DESCRIPTION

This tests the Statocles themes, including the fallback theme included in
the Statocles class.

=cut

use Mojo::Base -strict;
use Test::Mojo;
use Test::More;
use FindBin qw( $Bin );
use Mojo::File qw( path );

my @THEMES = qw( default bootstrap );

my $theme_dir = path( $Bin, 'share', 'theme' );
$ENV{MOJO_HOME} = $theme_dir;

subtest "Fallback theme" => \&test_theme, $theme_dir->child( 'templates' );
for my $theme ( @THEMES ) {
    subtest "Bundled theme: $theme" => \&test_theme,
        '+Statocles/theme/' . $theme, $theme_dir->child( 'templates' );
}

done_testing;

# XXX: This does not test bundled apps (like the Blog), and it should
sub test_theme {
    my @theme_dirs = @_;
    my %item = (
        title => 'My Title',
        date => '2019-01-01 00:00:00',
        author => 'Doug Bell',
        html => qq{One\n<hr>\nTwo\n<hr>\nThree},
    );

    my $t = Test::Mojo->new( Statocles => {
        apps => {
            blog => {
                route => '/',
            },
        },
        theme => [ @theme_dirs ],
    } );

    $t->get_ok( '/' )->status_is( 200 )
      ->content_like( qr{<h1>Categories</h1>}, 'category header exists' )
      ->element_exists( 'a[href=/tag/foo]', 'foo category link exists' )
      ->text_is( 'a[href=/tag/foo]', 'foo', 'foo category link text is correct' )
      ->or( sub { diag shift->tx->res->dom->at( 'header + *' ) } )
      ->element_exists( 'a[href=/tag/bar]', 'bar category link exists' )
      ->text_is( 'a[href=/tag/bar]', 'bar', 'bar category link text is correct' )

      ->get_ok( '/layout-extends-default' )->status_is( 200 )
      ->content_like( qr{<!-- head -->}, 'head content section exists' )
      ->content_like( qr{<!-- navbar -->}, 'navbar content section exists' )
      ->content_like( qr{<!-- hero -->}, 'hero content section exists' )
      ->content_like( qr{<!-- sidebar -->}, 'sidebar content section exists' )
      ->content_like( qr{<!-- footer -->}, 'footer content section exists' )
      ->content_like( qr{<!-- content -->}, 'content helper exists' )

      ->get_ok( '/layout-override-main' )->status_is( 200 )
      ->content_like( qr{<!-- main -->}, 'main content section replaced' )
      ->element_exists( 'main', 'main element still exists' )
      ->content_like( qr{<!-- head -->}, 'head content section exists' )
      ->content_like( qr{<!-- navbar -->}, 'navbar content section exists' )
      ->content_like( qr{<!-- hero -->}, 'hero content section exists' )
      ->content_like( qr{<!-- sidebar -->}, 'sidebar content section exists' )
      ->content_like( qr{<!-- footer -->}, 'footer content section exists' )
      ->content_unlike( qr{<!-- content -->}, 'content helper replaced by main' )

      ->get_ok( '/layout-override-container' )->status_is( 200 )
      ->content_like( qr{<!-- container -->}, 'container content section replaced' )
      ->content_like( qr{<!-- head -->}, 'head content section exists' )
      ->element_exists( 'header', 'header element still exists' )
      ->content_unlike( qr{<!-- navbar -->}, 'navbar content section replaced by header section' )
      ->content_unlike( qr{<!-- hero -->}, 'hero content section replaced by header section' )
      ->content_unlike( qr{<!-- sidebar -->}, 'sidebar content section replaced by container section' )
      ->content_like( qr{<!-- footer -->}, 'footer content section exists' )
      ->content_unlike( qr{<!-- content -->}, 'content helper replaced by container section' )

      ->get_ok( '/default' )->status_is( 200 )
      ->text_is( 'header h1', 'Default', 'item title is correct' )
      ->text_like( 'header aside time', qr{^\s*Posted on 2019-01-01\s*$}, 'item date is correct' )
      ->text_is( 'header aside .author', 'by Doug Bell', 'item author is correct' )
      ->text_is( 'section#section-1:nth-of-type(1) p', 'One', 'first section is correct' )
      ->or( sub { diag shift->tx->res->dom->at( 'main' ) } )
      ->text_is( 'section#section-2:nth-of-type(2) p', 'Two', 'second section is correct' )
      ->or( sub { diag shift->tx->res->dom->at( 'main' ) } )
      ->text_is( 'section#section-3:nth-of-type(3) p', 'Three', 'third section is correct' )
      ->or( sub { diag shift->tx->res->dom->at( 'main' ) } )

      ->get_ok( '/extends-default' )->status_is( 200 )
      ->text_is( 'header h1', 'Extends Default', 'item title is correct' )
      ->text_like( 'header aside time', qr{^\s*Posted on 2019-01-01\s*$}, 'item date is correct' )
      ->text_is( 'header aside .author', 'by Doug Bell', 'item author is correct' )
      ->text_is( 'section#section-1:nth-of-type(1) p', 'One', 'first section is correct' )
      ->or( sub { diag shift->tx->res->dom->at( 'main' ) } )
      ->text_is( 'section#section-2:nth-of-type(2) p', 'Two', 'second section is correct' )
      ->or( sub { diag shift->tx->res->dom->at( 'main' ) } )
      ->text_is( 'section#section-3:nth-of-type(3) p', 'Three', 'third section is correct' )
      ->or( sub { diag shift->tx->res->dom->at( 'main' ) } )
      ->content_like( qr{<!-- content_before -->}, 'content_before content section exists' )
      ->content_like( qr{<!-- content_after -->}, 'content_after content section exists' )

      ;
}

