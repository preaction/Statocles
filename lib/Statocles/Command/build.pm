package Statocles::Command::build;
our $VERSION = '0.092';
# ABSTRACT: Build the site in a directory

use Statocles::Base 'Command';

sub run {
    my ( $self, @argv ) = @_;
    my %build_opt;
    GetOptionsFromArray( \@argv, \%build_opt,
        'date|d=s',
    );
    $self->site->build( %build_opt );
    return 0;
}

1;
