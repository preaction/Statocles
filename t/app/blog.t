
=head1 DESCRIPTION

This tests the blog application, Statocles::App::Blog

=cut

use Mojo::Base -strict;
use Test::Mojo;
use Test::More;
use FindBin qw( $Bin );
use Mojo::File qw( path );

$ENV{MOJO_HOME} = path( $Bin, '..', 'share', 'blog' );
my $t = Test::Mojo->new( Statocles => {
    apps => {
        blog => {
            route => '/',
        },
    },
} );

$t->get_ok( '/' )->status_is( 200 )
  ->text_is( 'article:nth-of-type(1) h1 a', 'Second Post', 'most recent post is first in list' )
  ->or( sub { diag shift->tx->res->body } )
  ->text_is( 'article:nth-of-type(2) h1 a', 'First Post' )
  ->or( sub { diag shift->tx->res->body } )

  ->get_ok( '/first-post' )->status_is( 200 )
  ->text_is( 'h1', 'First Post' )

  ->get_ok( '/second-post' )->status_is( 200 )
  ->text_is( 'h1', 'Second Post' )

  ->get_ok( '/.rss', { Accept => 'application/rss+xml' } )->status_is( 200 )
  ->text_is( 'item:nth-of-type(1) title', 'Second Post', 'most recent post is first in list' )
  ->or( sub { diag shift->tx->res->body } )
  ->text_is( 'item:nth-of-type(2) title', 'First Post' )
  ->or( sub { diag shift->tx->res->body } )

  ->get_ok( '/.atom', { Accept => 'application/atom+xml' } )->status_is( 200 )
  ->text_is( 'entry:nth-of-type(1) title', 'Second Post', 'most recent post is first in list' )
  ->or( sub { diag shift->tx->res->body } )
  ->text_is( 'entry:nth-of-type(2) title', 'First Post' )
  ->or( sub { diag shift->tx->res->body } )

  ;

done_testing;
