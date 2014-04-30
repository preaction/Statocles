package Statocles::Theme;
# ABSTRACT: Templates, headers, footers, and navigation

use Statocles::Class;

has templates => (
    is => 'ro',
    isa => HashRef[HashRef[InstanceOf['Text::Template']]],
);

sub template {
    my ( $self, $app, $template ) = @_;
    return $self->templates->{ $app }{ $template };
}

1;
__END__

=head1 DESCRIPTION

A Theme contains all the templates that applications need.


