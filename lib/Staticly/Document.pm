package Staticly::Document;
# ABSTRACT: Base class for all Staticly documents

use Staticly::Class;

has file => (
    is => 'rw',
    isa => InstanceOf['Staticly::File'],
);

has title => (
    is => 'rw',
    isa => Str,
);

has author => (
    is => 'rw',
    isa => Str,
);

has content => (
    is => 'rw',
    isa => Str,
);

sub dump {
    my ( $self ) = @_;
    return {
        map { $_ => $self->$_ } qw( title author content )
    };
}

1;
__END__

=head1 DESCRIPTION

A Statically::Document is the base unit of content in Staticly. Applications
take Documents to build Pages.

This is the Model class in the Model-View-Controller pattern.
