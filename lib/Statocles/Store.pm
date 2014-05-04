package Statocles::Store;
# ABSTRACT: A repository for Documents and Pages

use Statocles::Class;
use Statocles::Document;
use File::Find qw( find );
use File::Path qw( make_path );
use File::Slurp qw( write_file );
use YAML;

has path => (
    is => 'ro',
    isa => Str,
    required => 1,
);

has documents => (
    is => 'rw',
    isa => ArrayRef[InstanceOf['Statocles::Document']],
    lazy => 1,
    builder => 'read_documents',
);

sub read_documents {
    my ( $self ) = @_;
    my $root_path = $self->path;
    my @docs;
    find(
        sub {
            if ( /[.]ya?ml$/ ) {
                my @yaml_docs = YAML::LoadFile( $File::Find::name );
                my $rel_path = $File::Find::name;
                $rel_path =~ s/$root_path//;
                push @docs, map { Statocles::Document->new( path => $rel_path, %$_ ) } @yaml_docs;
            }
        },
        $root_path,
    );
    return \@docs;
}

sub write_page {
    my ( $self, $page ) = @_;
    my $full_path = catfile( $self->path, $page->path );
    my ( $volume, $dirs, $file ) = splitpath( $full_path );
    make_path( catpath( $volume, $dirs, '' ) );
    write_file( $full_path, $page->render );
    return;
}

1;
__END__

=head1 DESCRIPTION

A Statocles::Store reads and writes Documents and Pages.

This class handles the parsing and inflating of Document objects.

