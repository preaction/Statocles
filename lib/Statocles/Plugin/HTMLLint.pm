package Statocles::Plugin::HTMLLint;
our $VERSION = '0.079';
# ABSTRACT: Check HTML for common errors and issues

use Statocles::Base 'Class';
with 'Statocles::Plugin';
BEGIN {
    eval { require HTML::Lint::Pluggable; HTML::Lint::Pluggable->VERSION( 0.06 ); 1 }
        or die "Error loading Statocles::Plugin::HTMLLint. To use this plugin, install HTML::Lint::Pluggable";
};

=attr plugins

The L<HTML::Lint::Pluggable> plugins to use. Defaults to a generic set of
plugins good for HTML5: 'HTML5' and 'TinyEntitesEscapeRule'

=cut

has plugins => (
    is => 'ro',
    isa => ArrayRef,
    default => sub { [qw( HTML5 TinyEntitesEscapeRule )] },
);

=method check_pages

    $plugin->check_pages( $event );

Check the pages inside the given
L<Statocles::Event::Pages|Statocles::Event::Pages> event.

=cut

sub check_pages {
    my ( $self, $event ) = @_;
    my @plugins = @{ $self->plugins };

    for my $page ( @{ $event->pages } ) {
        if ( $page->DOES( 'Statocles::Page::Document' ) ) {
            my $html = $page->render( site => $event->emitter );
            my $page_url = $page->path;

            my $lint = HTML::Lint::Pluggable->new;
            $lint->load_plugins( @plugins );
            $lint->parse( $html );

            if ( $lint->errors ) {
                $event->emitter->log->warn( "Lint failures on $page_url:" );
                for my $error ( $lint->errors ) {
                    $event->emitter->log->warn( "-" . $error->as_string );
                }
            }

        }
    }
}

=method register

Register this plugin to install its event handlers. Called automatically.

=cut

sub register {
    my ( $self, $site ) = @_;
    $site->on( build => sub { $self->check_pages( @_ ) } );
}

1;

=head1 SYNOPSIS

    # site.yml
    site:
        class: Statocles::Site
        args:
            plugins:
                lint:
                    $class: Statocles::Plugin::HTMLLint

=head1 DESCRIPTION

This plugin checks all of the HTML to ensure it's correct and complete. If something
is missing, this plugin will write a warning to the screen.

