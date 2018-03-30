package Statocles::Command::deploy;
our $VERSION = '0.093';
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

    my $deploy = $self->site->deploy;
    $deploy->site( $self->site );
    my @pages = $self->site->pages( %deploy_opt, base_url => $deploy->base_url );

    #; say "Deploying pages: " . join "\n", map { $_->path } @pages;
    $deploy->deploy( \@pages, %deploy_opt );

    $self->_write_status( {
        last_deploy_date => time(),
        last_deploy_args => \%deploy_opt,
    } );

    return 0;
}

1;
