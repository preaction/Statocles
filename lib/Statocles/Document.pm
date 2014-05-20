package Statocles::Document;
# ABSTRACT: Base class for all Statocles documents

use Statocles::Class;

=attr path

The path to this document.

=cut

has path => (
    is => 'rw',
    isa => Str,
);

=attr title

The title from this document.

=cut

has title => (
    is => 'rw',
    isa => Str,
);

=attr author

The author of this document.

=cut

has author => (
    is => 'rw',
    isa => Str,
);

=attr content

The raw content of this document, in markdown.

=cut

has content => (
    is => 'rw',
    isa => Str,
);

=method dump

Get this document as a hash reference.

=cut

sub dump {
    my ( $self ) = @_;
    return {
        map { $_ => $self->$_ } qw( title author content )
    };
}

1;
__END__

=head1 DESCRIPTION

A Statically::Document is the base unit of content in Statocles. Applications
take Documents to build Pages.

This is the Model class in the Model-View-Controller pattern.
