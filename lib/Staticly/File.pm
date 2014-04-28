package Staticly::File;
# ABSTRACT: A file containing Staticly documents

use Staticly::Class;
use YAML;

has path => (
    is => 'ro',
    isa => Str,
    required => 1,
);

has documents => (
    is => 'rw',
    isa => ArrayRef[InstanceOf['Staticly::Document']],
    default => sub { [] },
);

sub read {
    my ( $self ) = @_;
    my @yaml_docs = YAML::LoadFile( $self->path );
    my @docs = map { Staticly::Document->new( file => $self, %$_ ) } @yaml_docs;
    $self->documents( \@docs );
    return;
}

sub write {
    my ( $self ) = @_;
    YAML::DumpFile( $self->path, map { $_->dump } @{ $self->documents } );
    return;
}

sub add_document {
    my ( $self, @docs ) = @_;
    $_->file( $self ) for @docs;
    push @{ $self->documents }, @docs;
    return;
}

1;
__END__

=head1 DESCRIPTION

A Staticly::File contains one or more Staticly::Documents. This class
handles the parsing and inflating of Document objects.

