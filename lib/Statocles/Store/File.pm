package Statocles::Store::File;
# ABSTRACT: A store made up of plain files

use Statocles::Base 'Class';
with 'Statocles::Store';
use Scalar::Util qw( weaken blessed );
use Statocles::Document;
use YAML;
use File::Spec::Functions qw( splitdir );

my $DATETIME_FORMAT = '%Y-%m-%d %H:%M:%S';
my $DATE_FORMAT = '%Y-%m-%d';

# A hash of PATH => COUNT for all the open store paths. Stores are not allowed to
# discover the files or documents of other stores (unless the two stores have the same
# path)
my %FILE_STORES = ();

=attr path

The path to the directory containing the L<documents|Statocles::Document>.

=cut

has path => (
    is => 'ro',
    isa => AbsPath,
    coerce => AbsPath->coercion,
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

# Cache our realpath in case it disappears before we get demolished
has _realpath => (
    is => 'ro',
    isa => Path,
    lazy => 1,
    default => sub { $_[0]->path->realpath },
);

sub BUILD {
    my ( $self ) = @_;
    if ( !$self->path->exists ) {
        die sprintf "Store path '%s' does not exist", $self->path->stringify;
    }
    elsif ( !$self->path->is_dir ) {
        die sprintf "Store path '%s' is not a directory", $self->path->stringify;
    }

    $FILE_STORES{ $self->_realpath }++;
}

sub DEMOLISH {
    my ( $self, $in_global_destruction ) = @_;
    return if $in_global_destruction; # We're ending, we don't need to care anymore
    if ( --$FILE_STORES{ $self->_realpath } <= 0 ) {
        delete $FILE_STORES{ $self->_realpath };
    }
}

=method read_documents()

Read the directory C<path> and create the L<document|Statocles::Document> objects inside.

=cut

sub read_documents {
    my ( $self ) = @_;
    my $root_path = $self->path;
    my @docs;
    my $iter = $root_path->iterator( { recurse => 1, follow_symlinks => 1 } );
    while ( my $path = $iter->() ) {
        next unless $path->is_file;
        next unless $self->_is_owned_path( $path );
        if ( $path =~ /[.]markdown$/ ) {
            my $rel_path = rootdir->child( $path->relative( $root_path ) );
            push @docs, $self->read_document( $rel_path );
        }
    }
    return \@docs;
}

sub _is_owned_path {
    my ( $self, $path ) = @_;
    my $self_path = $self->_realpath;
    $path = $path->realpath;
    my $dir = $path->parent;
    for my $store_path ( keys %FILE_STORES ) {
        # This is us!
        next if $store_path eq $self_path;
        # If our store is contained inside this store's path, we win
        next if $self_path =~ /^\Q$store_path/;
        return 0 if $path =~ /^\Q$store_path/;
    }
    return 1;
}

=method read_document( path )

Read a single L<document|Statocles::Document> in Markdown with optional YAML
frontmatter.

=cut

sub read_document {
    my ( $self, $path ) = @_;
    site->log->debug( "Read document: " . $path );
    my $full_path = $self->path->child( $path );
    my %doc = $self->parse_frontmatter( $full_path, $full_path->slurp_utf8 );
    return Statocles::Document->new( %doc, path => $path );
}

=method parse_frontmatter( $from, $content )

Parse a document with YAML frontmatter. $from is a string identifying where the
content comes from (a path or other identifier). $content is the content to
parse for frontmatter.

=cut

sub parse_frontmatter {
    my ( $self, $from, $content ) = @_;
    my $doc;

    my @lines = split /\n/, $content;
    if ( $lines[0] =~ /^---/ ) {
        shift @lines;

        # The next --- is the end of the YAML frontmatter
        my ( $i ) = grep { $lines[ $_ ] =~ /^---/ } 0..$#lines;

        # If we did not find the marker between YAML and Markdown
        if ( !defined $i ) {
            die "Could not find end of front matter (---) in '$from'\n";
        }

        # Before the marker is YAML
        eval {
            $doc = YAML::Load( join "\n", splice( @lines, 0, $i ), "" );
        };
        if ( $@ ) {
            die "Error parsing YAML in '$from'\n$@";
        }

        # Remove the last '---' mark
        shift @lines;
    }

    $doc->{content} = join "\n", @lines, "";

    if ( exists $doc->{date} ) {

        my $dt;
        eval {
            $dt = Time::Piece->strptime( $doc->{date}, $DATETIME_FORMAT );
        };

        if ( $@ ) {
            eval {
                $dt = Time::Piece->strptime( $doc->{date}, $DATE_FORMAT );
            };

            if ( $@ ) {
                die sprintf "Could not parse date '%s'. Does not match '%s' or '%s'",
                    $doc->{date},
                    $DATETIME_FORMAT,
                    $DATE_FORMAT,
                    ;
            }

        }

        $doc->{date} = $dt;
    }

    return %$doc;
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
    $full_path->touchpath->spew_utf8( join "\n", $header, '---', $content );

    return $full_path;
}

sub _freeze_document {
    my ( $self, $doc ) = @_;
    delete $doc->{path}; # Path should not be in the document
    if ( exists $doc->{date} ) {
        $doc->{date} = $doc->{date}->strftime( $DATETIME_FORMAT );
    }
    if ( exists $doc->{links} ) {
        if ( !keys %{ $doc->{links} } ) {
            delete $doc->{links};
        }
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

=method find_files()

Returns an iterator that, when called, produces a single path suitable to be passed
to L<read_file>.

=cut

sub find_files {
    my ( $self ) = @_;
    my $iter = $self->path->iterator({ recurse => 1 });
    return sub {
        my $path = $iter->();
        return unless $path; # iterator exhausted
        $path = $iter->() while $path && ( $path->is_dir || !$self->_is_owned_path( $path ) );
        return unless $path; # iterator exhausted
        return $path->relative( $self->path )->absolute( '/' );
    };
}

=method open_file( $path )

Open the file with the given path. Returns a filehandle.

The filehandle opened is using raw bytes, not UTF-8 characters.

=cut

sub open_file {
    my ( $self, $path ) = @_;
    return $self->path->child( $path )->openr_raw;
}

=method write_file( $path, $content )

Write the given C<content> to the given C<path>. This is mostly used to write
out L<page objects|Statocles::Page>.

C<content> may be a simple string or a filehandle. If given a string, will
write the string using UTF-8 characters. If given a filehandle, will write out
the raw bytes read from it with no special encoding.

=cut

sub write_file {
    my ( $self, $path, $content ) = @_;
    site->log->debug( "Write file: " . $path );
    my $full_path = $self->path->child( $path );

    if ( ref $content eq 'GLOB' ) {
        my $fh = $full_path->touchpath->openw_raw;
        while ( my $line = <$content> ) {
            $fh->print( $line );
        }
    }
    else {
        $full_path->touchpath->spew_utf8( $content );
    }

    return;
}

1;
__END__

=head1 DESCRIPTION

This store reads/writes files from the filesystem.

=head2 Frontmatter Document Format

Documents are formatted with a YAML document on top, and Markdown content
on the bottom, like so:

    ---
    title: This is a title
    author: preaction
    ---
    # This is the markdown content
    
    This is a paragraph

