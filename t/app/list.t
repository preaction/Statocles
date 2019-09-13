
=head1 DESCRIPTION

This tests the list application, Statocles::App::List

=cut

use Mojo::Base -strict;
use Test::Mojo;
use Test::More;
use FindBin qw( $Bin );
use Mojo::File qw( path );

$ENV{MOJO_HOME} = path( $Bin, '..', 'share', 'list' );
my $t = Test::Mojo->new( Statocles => {
    apps => {
        list => {
            route => '/',
            limit => 2,
        },
    },
} );

$t->get_ok( '/' )->status_is( 200 )
  ->text_is( 'article:nth-child( 1 ) header h1 a', 'Alpha' )
  ->or( sub { diag shift->tx->res->dom->at( 'ul' ) } )
  ->text_is( 'article:nth-child( 2 ) header h1 a', 'Bravo' )
  ->or( sub { diag shift->tx->res->dom->at( 'ul' ) } )
  ->element_exists( '.pager .next [rel=next][href=/2]', 'next button is enabled' )
  ->element_exists( '.pager .prev button[disabled]', 'previous button is disabled' )
  ->get_ok( '/2' )->status_is( 200 )
  ->text_is( 'article:nth-child( 1 ) header h1 a', 'Charlie' )
  ->or( sub { diag shift->tx->res->dom->at( 'ul' ) } )
  ->element_exists( '.pager .next button[disabled]', 'next button is disabled' )
  ->element_exists( '.pager .prev [rel=prev][href=/]', 'previous button is enabled' )
  ;

is_deeply $t->app->export->pages, [ '/sitemap.xml', '/robots.txt', '/' ];

done_testing;
