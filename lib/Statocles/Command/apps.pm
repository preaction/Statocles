package Statocles::Command::apps;
our $VERSION = '0.098';
# ABSTRACT: List the apps in the site

use Statocles::Base 'Command';

sub run {
    my ( $self, @argv ) = @_;
    my $apps = $self->site->apps;
    for my $app_name ( keys %{ $apps } ) {
        my $app = $apps->{$app_name};
        my $root = $app->url_root;
        my $class = ref $app;
        say "$app_name ($root -- $class)";
    }
    return 0;
}

1;
