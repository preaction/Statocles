package Statocles::Plugin::HTMLLint;
our $VERSION = '0.095';
# ABSTRACT: Check HTML for common errors and issues

use Statocles::Base 'Class';
with 'Statocles::Plugin';
BEGIN {
    eval { require HTML::Lint::Pluggable; HTML::Lint::Pluggable->VERSION( 0.06 ); 1 }
        or die "Error loading Statocles::Plugin::HTMLLint. To use this plugin, install HTML::Lint::Pluggable";
};

=attr fatal

If set to true, and there are any linting errors, the plugin will also call
C<die()> after printing the problems. Defaults to false.

=cut

has fatal => (
    is => 'ro',
    isa => Bool,
    default => 0,
);

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

    my $lint = HTML::Lint::Pluggable->new;
    $lint->load_plugins( @plugins );

    for my $page ( @{ $event->pages } ) {
        if ( $page->DOES( 'Statocles::Page::Document' ) ) {
            my $html = "".$page->dom;
            my $page_url = $page->path;

            $lint->newfile( $page_url );
            $lint->parse( $html );
            $lint->eof;
        }
    }

    if ( my @errors = $lint->errors ) {
        for my $error ( @errors ) {
            $event->emitter->log->warn( "-" . $error->as_string );
        }

        die 'Linting failed!' if $self->fatal;
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
is missing, this plugin will write a warning to the screen. If fatal is set to true,
it will also call C<die()> afterwards.

