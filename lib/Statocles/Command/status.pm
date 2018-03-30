package Statocles::Command::status;
our $VERSION = '0.094';
# ABSTRACT: Show status information for the site

use Statocles::Base 'Command';

sub run {
    my ( $self, @argv ) = @_;
    my $status = $self->_get_status;
    if ($status->{last_deploy_date}) {
        say "Last deployed on " .
            DateTime::Moonpig->from_epoch(
                epoch => $status->{last_deploy_date},
            )->strftime("%Y-%m-%d at %H:%M");
        say "Deployed up to date " .
            ( $status->{last_deploy_args}{date} || '-' );
    }
    else {
        say "Never been deployed";
    }
    return 0;
}

1;
