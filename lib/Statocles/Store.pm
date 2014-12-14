package Statocles::Store;
# ABSTRACT: A repository for Documents and Pages

use Statocles::Class;
use Scalar::Util qw( blessed );
use Statocles::Document;
use YAML;
use List::MoreUtils qw( firstidx );
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

=method clear()

Clear the cached documents in this Store.

=cut

has documents => (
    is => 'rw',
    isa => ArrayRef[InstanceOf['Statocles::Document']],
    lazy => 1,
    builder => 'read_documents',
    clearer => 'clear',
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
            my $rel_path = rootdir->child( $path->relative( $root_path ) );
            my $data = $self->read_document( $rel_path );
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
    site->log->debug( "Read document: " . $path );
    my $full_path = $self->path->child( $path );
    my @lines = $full_path->lines_utf8;

    shift @lines while $lines[0] =~ /^---/;
    # The next --- is the end of the YAML frontmatter
    my $i = firstidx { /^---/ } @lines;

    my $doc;
    # If we found the marker between YAML and Markdown
    if ( $i > 0 ) {
        # Before the marker is YAML
        eval {
            $doc = YAML::Load( join "", @lines[0..$i-1] );
        };
        if ( $@ ) {
            die "Error parsing YAML in '$full_path'\n$@";
        }
        # After the marker is Markdown
        if ( !$doc->{content} ) {
            $doc->{content} = join "", @lines[$i+1..$#lines];
        }
    }
    # Otherwise, must be completely YAML
    else {
        eval {
            $doc = YAML::Load( join "", @lines );
        };
        if ( $@ ) {
            die "Error parsing YAML in '$full_path'\n$@";
        }
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
    site->log->debug( "Write document: " . $path );

    $doc = { %{ $doc } }; # Shallow copy for safety
    my $content = delete( $doc->{content} ) // '';
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

=method read_file( $path )

Read the file from the given C<path>.

=cut

sub read_file {
    my ( $self, $path ) = @_;
    site->log->debug( "Read file: " . $path );
    return $self->path->child( $path )->slurp_utf8;
}

=method has_file( $path )

Returns true if a file exists with the given C<path>.

NOTE: This should not be used to check for directories, as not all stores have
directories.

=cut

sub has_file {
    my ( $self, $path ) = @_;
    return $self->path->child( $path )->is_file;
}

=method write_file( $path, $content )

Write the given C<content> to the given C<path>. This is mostly used to write
out L<page objects|Statocles::Page>.

=cut

sub write_file {
    my ( $self, $path, $content ) = @_;
    site->log->debug( "Write file: " . $path );
    my $full_path = $self->path->child( $path );
    $full_path->touchpath->spew_utf8( $content );
    return;
}

1;
__END__

=head1 DESCRIPTION

A Statocles::Store reads and writes L<documents|Statocles::Document> and
files (mostly L<pages|Statocles::Page>).

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

