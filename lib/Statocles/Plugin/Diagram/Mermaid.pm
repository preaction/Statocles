package Statocles::Plugin::Diagram::Mermaid;

use Mojo::URL;
use Statocles::Base 'Class';
with 'Statocles::Plugin';

has mermaid_url => (
  is => 'ro',
  isa => InstanceOf['Mojo::URL'],
  # We can't check for existence, because @INC might contain nonexistent
  # directories (I think)
  default => sub { Mojo::URL->new('https://unpkg.com/mermaid/dist/mermaid.min.js') },
  coerce => sub {
      my ( $args ) = @_;
      return Mojo::URL->new( $args );
  },
);

# https://unpkg.com/mermaid@7.1.0/dist/mermaid.min.js
# <script src="./mermaid.min.js"></script>
#   <script>
#     mermaid.initialize({startOnLoad: true, theme: 'forest'});
#   </script>
sub mermaid {
  my ($self, $args, @args) = @_;

  my $page = $args->{page} || $args->{self};
  if ( $page ) {
      # Add the appropriate stylesheet to the page
      my $mermaid_url = $self->mermaid_url->to_string;
      if ( !grep { $_->href eq $mermaid_url } $page->links( 'script' ) ) {
          $page->links( script => {href =>$mermaid_url} );
          $page->links( script => {
            href => '',
            text => q|mermaid.initialize({startOnLoad: true, theme: 'forest'});|
          } );
      }
  }
  return ;
}

sub register {
    my ( $self, $site ) = @_;
    $site->theme->helper( diagram => sub { $self->mermaid( @_ ) } );
}

1;
