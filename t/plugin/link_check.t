
=head1 DESCRIPTION

=cut

use Mojo::Base -strict;
use Test::Mojo;
use Test::More;
use FindBin qw( $Bin );
use Mojo::File qw( path tempdir );

$ENV{MOJO_HOME} = path( $Bin, '..', 'share', 'link_check' );
my $t = Test::Mojo->new( Statocles => {
    export => {
        pages => [qw( / )],
    },
    plugins => [ 'LinkCheck' ],
} );
if ( !$ENV{HARNESS_IS_VERBOSE} ) {
    my $log_str;
    open my $log_fh, '>', \$log_str;
    $t->app->log->level( 'warn' );
    $t->app->log->handle( $log_fh );
}
$t->app->log->max_history_size( 5000 );

my $to = tempdir;
$t->app->export->export({ to => $to });

my @broken_urls = map { $_->[2] } grep { $_->[2] =~ /URL broken/ } @{ $t->app->log->history };
is_deeply \@broken_urls,
    [
        q{URL broken on /: '/NOT_FOUND' not found},
    ]
    or diag explain $t->app->log->history;

done_testing;
