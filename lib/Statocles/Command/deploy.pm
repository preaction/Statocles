package Statocles::Command::deploy;
our $VERSION = '0.092';
# ABSTRACT: Deploy the site

use Statocles::Base 'Command';

sub run {
    my ( $self, @argv ) = @_;
    my %deploy_opt;
    GetOptionsFromArray( \@argv, \%deploy_opt,
        'date|d=s',
        'clean',
        'message|m=s',
    );
    $self->site->deploy( %deploy_opt );
    return 0;
}

1;
