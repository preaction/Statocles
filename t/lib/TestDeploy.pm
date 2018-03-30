package TestDeploy;

use Statocles::Base 'Class';
with 'Statocles::Deploy';

has last_deploy_args => ( is => 'rw' );

sub deploy {
    my ( $self, $source_path, %options ) = @_;
    $self->last_deploy_args( [ $source_path, \%options ] );
}

1;
