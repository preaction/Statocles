package Statocles::Command::deploy;
our $VERSION = '0.095';
# ABSTRACT: Deploy the site

use Statocles::Base 'Command';
use Statocles::Command::build;

has build_dir => (
    is => 'ro',
    isa => Path,
    coerce => Path->coercion,
    default => sub { Path->coercion->( '.statocles/build' ) },
);

sub run {
    my ( $self, @argv ) = @_;
    my %deploy_opt;
    GetOptionsFromArray( \@argv, \%deploy_opt,
        'date|d=s',
        'clean',
        'message|m=s',
    );

    my $deploy = $self->site->deploy;
    $deploy->site( $self->site );

    my $build_cmd = Statocles::Command::build->new( site => $self->site );
    my %build_opt;
    if ( $deploy_opt{date} ) {
        $build_opt{ '--date' } = $deploy_opt{ date };
    }
    if ( $deploy->base_url ) {
        $build_opt{ '--base_url' } = $deploy->base_url;
    }
    $build_cmd->run( $self->build_dir, %build_opt );

    $deploy->deploy( $self->build_dir, %deploy_opt );

    $self->_write_status( {
        last_deploy_date => time(),
        last_deploy_args => \%deploy_opt,
    } );

    return 0;
}

1;
