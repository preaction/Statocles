package Statocles::Plugin;
our $VERSION = '0.081';
# ABSTRACT: Base role for Statocles plugins

=head1 SYNOPSIS

    # lib/My/Plugin.pm
    package My::Plugin;
    use Moo; # or Moose
    with 'Statocles::Plugin';

    sub register {
        my ( $self, $site ) = @_;
        # Register things like event handlers and theme helpers
    }

    1;

    # site.yml
    site:
        args:
            plugins:
                name:
                    $class: My::Plugin

=head1 DESCRIPTION

Statocles Plugins are attached to sites and add features such as template helpers
and event handlers.

This is the base role that all plugins should consume.

=cut

use Statocles::Base 'Role';

=method register

    $plugin->register( $site );

Register this plugin with the given L<Statocles::Site
object|Statocles::Site>. This is called automatically when the site is
created.

=cut

requires 'register';

1;
__END__

=head1 BUNDLED PLUGINS

These plugins come with Statocles. L<More plugins may be available from
CPAN|http://metacpan.org>.

=over 4

=item L<Statocles::Plugin::LinkCheck>

Check your site for broken links and images.

=item L<Statocles::Plugin::Highlight>

Syntax highlighting for code and configuration.

=item L<Statocles::Plugin::HTMLLint>

Check your HTML for best practices.

=back

=head1 OVERVIEW

=head2 CONFIGURATION

Site-level configuration of a plugin can be placed in the configuration file,
usually C<site.yml> as arguments:

    # site.yml
    site:
        args:
            plugins:
                name:
                    $class: My::Plugin
                    $args:
                         myattr: 'value'

The argument name and value type must match a declaration in the
plugin itself. For example,

    package My::Plugin {
        use Statocles::Base 'Class';
        with 'Statocles::Plugin';

        has myattr => (
            is => 'ro',
            isa => Str,
            default => sub { 'a default value' },
        )
        ...

=head2 EVENT HANDLERS

Most plugins will want to attach to one or more Statocles event
handlers in their registration. This example creates a template helper
C<myplug> and also hooks into the C<before_build_write> event.

    sub plugger {
        my ( $self, $args, @helper_args ) = @_;
        ...
    }

    sub _plugboard {
        my ( $self, $pages, @args ) = @_;
        ...
    }

    sub register {
        my ( $self, $site ) = @_;
        # We register our event handlers and theme helpers:
        $site->theme->helper( myplug => sub { $self->plugger( @_ ) } );
        $site->on( before_build_write => sub { $self->_plugboard( @_ ) } );
        return $self;
    }

The event handler itself, like C<_plugboard> above, receives arguments
from the event.  For C<before_build_write> this is a
C<Statocles::Event::Pages> object.

=head2 HELPER FUNCTIONS

A helper function like C<plugger> above receives first the template
variables and then all the helper arguments supplied in the template
itself.  In the example above (section "Event Handlers"), C<$args>
would be a hash with these keys:
=over

=item *

C<app> The current app, e.g., C<"Statocles::App::Basic">

=item *

C<doc> The current document, e.g., of class L<Statocles::Document>

=item *

C<page> The current page, e.g., of class L<Statocles::Page::Document>

=item *

C<site> The current site, e.g., of class L<Statocles::Site>

=back

