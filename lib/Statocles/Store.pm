package Statocles::Store;
# ABSTRACT: A repository for Documents and Pages

use Statocles::Class;
use Statocles::Document;
use YAML;
use File::Spec::Functions qw( splitdir );

my $DT_FORMAT = '%Y-%m-%d %H:%M:%S';

=attr path

The path to the directory containing the L<documents|Statocles::Document>.

=cut

has path => (
    is => 'ro',
    isa => Path,
    coerce => Path->coercion,
    required => 1,
);

=attr documents

All the L<documents|Statocles::Document> currently read by this store.

=cut

has documents => (
    is => 'rw',
    isa => ArrayRef[InstanceOf['Statocles::Document']],
    lazy => 1,
    builder => 'read_documents',
);

=method read_documents()

Read the directory C<path> and create the L<document|Statocles::Document> objects inside.

=cut

sub read_documents {
    my ( $self ) = @_;
    my $root_path = $self->path;
    my @docs;
    my $iter = $root_path->iterator( { recurse => 1, follow_symlinks => 1 } );
    while ( my $path = $iter->() ) {
        if ( $path =~ /[.]ya?ml$/ ) {
            my $data = $self->read_document( $path );
            my $rel_path = rootdir->child( $path->relative( $root_path ) );
            push @docs, Statocles::Document->new( path => $rel_path, %$data );
        }
    }
    return \@docs;
}

=method read_document( path )

Read a single L<document|Statocles::Document> in either pure YAML or combined
YAML/Markdown (Frontmatter) format and return a datastructure suitable to be
given to L<Statocles::Document|Statocles::Document>.

=cut

sub read_document {
    my ( $self, $path ) = @_;
    open my $fh, '<', $path or die "Could not open '$path' for reading: $!\n";
    my $doc;
    my $buffer = '';
    while ( my $line = <$fh> ) {
        if ( !$doc ) { # Building YAML
            if ( $line =~ /^---/ && $buffer ) {
                $doc = YAML::Load( $buffer );
                $buffer = '';
            }
            else {
                $buffer .= $line;
            }
        }
        else { # Building Markdown
            $buffer .= $line;
        }
    }
    close $fh;

    # Clear the remaining buffer
    if ( !$doc && $buffer ) { # Must be only YAML
        $doc = YAML::Load( $buffer );
    }
    elsif ( !$doc->{content} && $buffer ) {
        $doc->{content} = $buffer;
    }

    return $self->_thaw_document( $doc );
}

sub _thaw_document {
    my ( $self, $doc ) = @_;
    if ( exists $doc->{last_modified} ) {
        $doc->{last_modified} = Time::Piece->strptime( $doc->{last_modified}, $DT_FORMAT );
    }
    return $doc;
}

=method write_document( $path, $doc )

Write a L<document|Statocles::Document> to the store. Returns the full path to
the newly-updated document.

The document is written in Frontmatter format.

=cut

sub write_document {
    my ( $self, $path, $doc ) = @_;
    $path = Path->coercion->( $path ); # Allow stringified paths, $path => $doc
    if ( $path->is_absolute ) {
        die "Cannot write document '$path': Path must not be absolute";
    }

    $doc = { %{ $doc } }; # Shallow copy for safety
    my $content = delete $doc->{content};
    my $header = YAML::Dump( $self->_freeze_document( $doc ) );
    chomp $header;

    my $full_path = $self->path->child( $path );
    $full_path->touchpath->spew( join "\n", $header, '---', $content );

    return $full_path;
}

sub _freeze_document {
    my ( $self, $doc ) = @_;
    if ( exists $doc->{last_modified} ) {
        $doc->{last_modified} = $doc->{last_modified}->strftime( $DT_FORMAT );
    }
    return $doc;
}

=method write_page( $path, $html )

Write the L<page|Statocles::Page> C<html> to the given C<path>.

=cut

sub write_page {
    my ( $self, $path, $html ) = @_;
    my $full_path = $self->path->child( $path );
    $full_path->touchpath->spew( $html );
    return;
}

1;
__END__

=head1 DESCRIPTION

A Statocles::Store reads and writes L<documents|Statocles::Document> and
L<pages|Statocles::Page>.

This class handles the parsing and inflating of
L<"document objects"|Statocles::Document>.

=head2 Frontmatter Document Format

Documents are formatted with a YAML document on top, and Markdown content
on the bottom, like so:

    ---
    title: This is a title
    author: preaction
    ---
    # This is the markdown content
    
    This is a paragraph

