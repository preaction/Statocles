
=head1 DESCRIPTION

This tests the main Statocles application

=cut

use Mojo::Base -strict;
use Test::Mojo;
use Test::More;
use FindBin qw( $Bin );
use Mojo::File qw( path );

$ENV{MOJO_HOME} = path( $Bin, 'share', 'app' );
my $t = Test::Mojo->new( Statocles => {} );

$t->get_ok( '/' )->status_is( 200 )

  ->get_ok( '/blog/first-post' )->status_is( 200 )

  ->get_ok( '/blog/second-post' )->status_is( 200 )

  ->get_ok( '/avatar.jpg' )->status_is( 200 )

  ->get_ok( '/about' )->status_is( 200 )

  ->get_ok( '/advent/2019' )->status_is( 200 )->text_is( h1 => 2019 )
  ->get_ok( '/advent/2018' )->status_is( 200 )->text_is( h1 => 2018 )
  ->get_ok( '/advent/2019.rss', { Accept => 'application/rss+xml' } )->status_is( 200 )->text_is( h1 => 2019 )
  ->get_ok( '/advent/2018.rss', { Accept => 'application/rss+xml' } )->status_is( 200 )->text_is( h1 => 2018 )

  ->get_ok( '/sitemap.xml' )->status_is( 200 )
  ->text_like(
      'url:first-child loc', qr{http://\d+27\.\d+\.\d+\.\d+:\d+/blog/first-post},
      'sitemap.xml <loc> is a full url',
  )

  ;

done_testing;
