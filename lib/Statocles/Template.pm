package Statocles::Template;
# ABSTRACT: A template object to pass around

use Statocles::Class;
use Mojo::Template;
use File::Slurp qw( read_file );

has content => (
    is => 'ro',
    isa => Str,
    lazy => 1,
    default => sub {
        my ( $self ) = @_;
        return scalar read_file( $self->path );
    },
);

has path => (
    is => 'ro',
    isa => Str,
);

sub render {
    my ( $self, %args ) = @_;
    my $t = Mojo::Template->new;
    $t->prepend( $self->_vars( keys %args ) );
    return $t->render( $self->content, \%args );
}

sub _vars {
    my ( $self, @vars ) = @_;
    return join " ", 'my $vars = shift;', map { "my \$$_ = \$vars->{'$_'};" } @vars;
}

1;
__END__

=head1 DESCRIPTION


