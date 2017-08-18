package My::Test::Statocles::Store;

use Test::Lib;
use My::Test;

use My::Test::Store;

my $SHARE_DIR = path( __DIR__, '..', 'share' );

use Moo;

with 'My::Test::Store';

has '+class' => ( is => 'ro',
                  default => 'Statocles::Store'
                  );

has '+share_dir' => ( is => 'ro',
                      default => sub { $SHARE_DIR }
                  );


sub args {
    my $self = shift;
    return { @_ };
}

sub required {

    return args( @_ );
}

__PACKAGE__->new->run_tests;


done_testing;

