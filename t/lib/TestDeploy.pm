package TestDeploy;

use Statocles::Base 'Class';
with 'Statocles::Deploy';

has last_deploy_args => ( is => 'rw' );

sub deploy {
    my ( $self, $pages, %options ) = @_;
    $self->last_deploy_args( [ $pages, \%options ] );
}

1;
