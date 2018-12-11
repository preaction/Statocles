package Statocles::Command::deploy;
our $VERSION = '0.094';
# ABSTRACT: Deploy the site

use Mojo::Base 'Mojolicious::Command';

has build_dir => sub { shift->app->home->child( '.statocles', 'build' )->make_path };

sub run {
    my ( $self, @argv ) = @_;
    my %deploy_opt;
    GetOptionsFromArray( \@argv, \%deploy_opt,
        #'date|d=s',
        'clean',
    );

    $self->app->export->export({ to => $self->build_dir });
    my $deploy = $self->app->deploy;
    $deploy->deploy( $self->build_dir, %deploy_opt );

    return 0;
}

1;
