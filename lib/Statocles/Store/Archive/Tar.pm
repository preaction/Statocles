package Statocles::Store::Archive::Tar;
our $VERSION = '0.085';
# ABSTRACT: The source for data documents and files

use Statocles::Base 'Class';
use File::Spec;
use Scalar::Util qw[ blessed ];
use Moo;
use Carp ();

extends 'Statocles::Store';


use Encode;
use Archive::Tar;

=attr path

The path to the directory which will appear to contain the L<documents|Statocles::Document>.

=cut

has archive => (
    is  => 'ro',
    isa => ( InstanceOf ['Archive::Tar'] )
      ->plus_coercions( Str, sub { Archive::Tar->new( $_ ) },
        Path, sub { Archive::Tar->new( $_ ) },
      ),
    coerce   => 1,
    required => 1
);

has archive_root => (
    is       => 'ro',
    isa      => Path,
    coerce   => 1,
    required => 1,
);

has archive_strip => (
    is      => 'ro',
    isa     => Str | Path,
    coerce  => 1,
    default => ''
);

has '_real_archive_root' => (
    is      => 'ro',
    isa     => Path,
    lazy    => 1,
    default => sub { $_[0]->_resolve_path( $_[0]->archive_root ) },
);


sub _resolve_path {

    my ( $self, $path ) = @_;

    # use Devel::StackTrace;
    # print Devel::StackTrace->new->as_string;

    $path = $self->archive_root->child( $path )->absolute
      if $path->is_relative;

    # Path::Tiny::parent correctly refuses to interpret '..',
    # so we can't use it.

    # Since our paths are not really filesystem paths, we can fudge
    # things

    ( my $volume, $path, my $file ) = File::Spec->splitpath( $path->stringify );
    my @segments = File::Spec->splitdir( $path );

    my @path;
    while ( @segments ) {
        my $segment = shift @segments;
        pop @path and next if $segment eq '..';
        push @path, $segment;
    }

    Path::Tiny::path(
        File::Spec->catpath( $volume, File::Spec->catdir( @path ), $file ) );
}

sub _archive_path {

    my ( $self, $path ) = @_;

    my $pfx = $self->_realpath->relative( $self->_real_archive_root );

    my $file = $self->archive_strip->child( $pfx->child( $path ) );

    return $file;
}

=method read_file

    my $content = $store->read_file( $path )

Read the file from the given C<path>.

=cut

sub read_file {
    my ( $self, $path ) = @_;
    site->log->debug( "Read file: " . $path );
    local $SIG{__WARN__} = sub { Carp::croak $self->archive->error };
    return decode( 'utf8',
        $self->archive->get_content( $self->_archive_path( $path ) ) );
}

sub read_file_raw {
    my ( $self, $path ) = @_;
    site->log->debug( "Read file: " . $path );
    local $SIG{__WARN__} = sub { Carp::croak $self->archive->error };
    return $self->archive->get_content( $self->_archive_path( $path ) );
}

=method has_file

    my $bool = $store->has_file( $path )

Returns true if a file exists with the given C<path>.

NOTE: This should not be used to check for directories, as not all stores have
directories.

=cut

sub has_file {
    my ( $self, $path ) = @_;
    return $self->archive->contains_file( $self->_archive_path( $path ) );
}

=method files

    my $iter = $store->files

Returns an iterator which iterates over I<all> files in the store,
regardless of type of file.  The iterator returns a L<Path::Tiny>
object or undef if no files remain.  It is used by L<find_files>.

=cut

sub files {
    my ( $self ) = @_;

    my @files
      = map { $_->full_path } grep { $_->is_file } $self->archive->get_files;

    sub {

        my $realpath     = $self->_realpath;
        my $archive_root = $self->_real_archive_root;
        while ( @files ) {

            my $file = Path::Tiny::path( shift @files );
            $file = $file->relative( $self->archive_strip );
            $file = $self->archive_root->child( $file );
            my $realfile = $self->_resolve_path( $file );
            return $realfile if $realpath->subsumes( $realfile );

        }
        return undef;

      }
}


=method write_file

    $store->write_file( $path, $content );

Write the given C<content> to the given C<path>. This is mostly used to write
out L<page objects|Statocles::Page>.

C<content> may be a:

=over

=item *

a simple string, which  will be written using UTF-8 characters.

=item *

a L<Path::Tiny> object whose C<copy> method will be used to
write it;

=item *

a filehandle which will be read from with no special encoding.

=back

=cut

sub write_file {
    my ( $self, $path, $content ) = @_;
    site->log->debug( "Write file: " . $path );

    my $file = $self->_archive_path( $path );

    if ( ref $content eq 'GLOB' ) {
        $self->archive->add_data( $file, join( '', <$content> ) );
    }
    elsif ( blessed $content && $content->isa( 'Path::Tiny' ) ) {
        $self->archive->add_data( $file, $content->slurp_raw );
    }
    else {
        $self->archive->add_data( $file, encode( 'utf8', $content ) );
    }

    return;
}

=method remove

    $store->remove( $path )

Remove the given path from the store. If the path is a directory, the entire
directory is removed.

=cut

sub remove {
    my ( $self, $path ) = @_;

    # $path may be a file or a directory
    $path = $self->_archive_path( $path );

    my $entry = do {
        local $SIG{__WARN__} = sub { };
        ( $self->archive->get_files( $path ) )[0];
    };

    if ( defined $entry && !$entry->is_dir ) {
        $self->archive->remove( $path );
    }
    else {

        my @paths = grep { $path->subsumes( $_ ) }
          map { $_->full_path } $self->archive->get_files;
        $self->archive->remove( @paths );
    }
    return;
}

1;
__END__

=head1 DESCRIPTION

A Statocles::Store reads and writes L<documents|Statocles::Document> and
files (mostly L<pages|Statocles::Page>).

This class also handles the parsing and inflating of
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

