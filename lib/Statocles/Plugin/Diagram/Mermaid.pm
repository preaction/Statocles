package Statocles::Plugin::Diagram::Mermaid;
our $VERSION = '0.097';
# ABSTRACT: Render diagrams using mermaid https://mermaidjs.github.io

=head1 SYNOPSIS

    # --- Configuration
    # site.yml
    ---
    site:
        class: Statocles::Site
        args:
            plugins:
                diagram:
                    $class: Statocles::Plugin::Diagram::Mermaid

    # --- Usage
    <%= diagram mermaid => begin %>
    sequenceDiagram
    loop every day
        Alice->>John: Hello John, how are you?
        John-->>Alice: Great!
    end
    <% end %>

=head1 DESCRIPTION

This plugin adds the C<diagram> helper function to all templates and
content documents, allowing for creation of L<mermaid|https://mermaidjs.github.io>
diagrams.

=cut

use Mojo::URL;
use Statocles::Base 'Class';
with 'Statocles::Plugin';


=attr mermaid_url

Set the url to use as a, possibly local, alternative to the default script
L<mermaid.min.js|https://unpkg.com/mermaid/dist/mermaid.min.js> for including in
a script tag.

=cut

has mermaid_url => (
  is => 'ro',
  isa => InstanceOf['Mojo::URL'],
  default => sub { Mojo::URL->new('https://unpkg.com/mermaid/dist/mermaid.min.js') },
  coerce => sub {
      my ( $args ) = @_;
      return Mojo::URL->new( $args );
  },
);


=method diagram

    %= diagram $type => $content

Wrap the given C<$content> with the html for displaying the diagram with
C<mermaid.js>.

In most cases displaying a diagram will require the use of C<begin>/C<end>:

    %= diagram mermaid => begin
    graph TD
    A[Christmas] -->|Get money| B(Go shopping)
    B --> C{Let me think}
    C -->|One| D[Laptop]
    C -->|Two| E[iPhone]
    C -->|Three| F[Car]
    % end

=cut

# https://unpkg.com/mermaid@7.1.0/dist/mermaid.min.js
# <script src="./mermaid.min.js"></script>
#   <script>
#     mermaid.initialize({startOnLoad: true, theme: 'forest'});
#   </script>
sub mermaid {
  my ($self, $args, @args) = @_;
  my ( $text, $type ) = ( pop @args, pop @args );

  # Handle Mojolicious begin/end
  if ( ref $text eq 'CODE' ) {
      $text = $text->();
      # begin/end starts with a newline, so remove it to prevent too
      # much top space
      $text =~ s/\n$//;
  }

  my $page = $args->{page} || $args->{self};
  if ( $page ) {
      # Add the appropriate stylesheet to the page
      my $mermaid_url = $self->mermaid_url->to_string;
      if ( !grep { $_->href eq $mermaid_url } $page->links( 'script' ) ) {
          $page->links( script => {href => $mermaid_url} );
          $page->links( script => {
            href => '',
            text => q|mermaid.initialize({startOnLoad: true, theme: 'forest'});|
          } );
      }
  }
  return qq{<div class="mermaid">$text</div>};
}

=method register

Register this plugin with the site. Called automatically.

=cut

sub register {
    my ( $self, $site ) = @_;
    $site->theme->helper( diagram => sub { $self->mermaid( @_ ) } );
}

1;
