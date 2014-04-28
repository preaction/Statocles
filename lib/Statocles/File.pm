package Statocles::File;
# ABSTRACT: A file containing Statocles documents

use Statocles::Class;
use YAML;

has path => (
    is => 'ro',
    isa => Str,
    required => 1,
);

has documents => (
    is => 'rw',
    isa => ArrayRef[InstanceOf['Statocles::Document']],
    default => sub { [] },
);

sub read {
    my ( $self ) = @_;
    my @yaml_docs = YAML::LoadFile( $self->path );
    my @docs = map { Statocles::Document->new( file => $self, %$_ ) } @yaml_docs;
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

A Statocles::File contains one or more Statocles::Documents. This class
handles the parsing and inflating of Document objects.

