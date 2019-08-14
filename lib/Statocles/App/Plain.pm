package Statocles::App::Plain;
our $VERSION = '0.095';
# ABSTRACT: (DEPRECATED) Plain documents made into pages with no extras

use Statocles::Base 'Class';
extends 'Statocles::App::Basic';
use Statocles::Util qw( derp );

=attr store

The L<store|Statocles::Store> containing this app's documents. Required.

=cut

before pages => sub {
    derp qq{Statocles::App::Plain has been renamed to Statocles::App::Basic and will be removed in 2.0. Change the app class to "Statocles::App::Basic" to silence this message.};
};

=method command

    my $exitval = $app->command( $app_name, @args );

Run a command on this app. Commands allow creating, editing, listing, and
viewing pages.

=cut

before command => sub {
    derp qq{Statocles::App::Plain has been renamed to Statocles::App::Basic and will be removed in 2.0. Change the app class to "Statocles::App::Basic" to silence this message.};
};

1;
__END__

=head1 SYNOPSIS

    my $app = Statocles::App::Plain->new(
        url_root => '/',
        store => 'share/root',
    );
    my @pages = $app->pages;

=head1 DESCRIPTION

B<NOTE:> This application has been renamed L<Statocles::App::Basic>. This
class will be removed with v2.0. See L<Statocles::Help::Upgrading>.

This application builds simple pages based on L<documents|Statocles::Document>. Use this
to have basic informational pages like "About Us" and "Contact Us".

