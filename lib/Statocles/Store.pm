package Statocles::Store;
our $VERSION = '0.080';
# ABSTRACT: The source for data documents and files

use Statocles::Base 'Class';
use Scalar::Util qw( weaken blessed );
use Statocles::Util qw( derp );
use Statocles::Document;
use YAML;
use File::Spec::Functions qw( splitdir );
use Module::Runtime qw( use_module );

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

=attr document_extensions

An array of file extensions that should be considered documents. Defaults to
"markdown" and "md".

=cut

has document_extensions => (
    is => 'ro',
    isa => ArrayRef[Str],
    default => sub { [qw( markdown md )] },
    coerce => sub {
        my ( $ext ) = @_;
        if ( !ref $ext ) {
            return [ split /[, ]/, $ext ];
        }
        return $ext;
    },
);

=attr documents

All the L<documents|Statocles::Document> currently read by this store.

=method clear

    $store->clear;

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

# If true, we've already checked if this store's path exists. We need to
# check this lazily to ensure the site is created and the logger is
# ready to go.
#
# XXX: Making sure the logger is ready before the thing that needs it is
# the entire reason that dependency injection exists. We should use the
# container to make sure the logger is wired up with every object that
# needs it...
has _check_exists => (
    is => 'rw',
    isa => Bool,
    lazy => 1,
    default => sub {
        my ( $self ) = @_;
        if ( !$self->path->exists ) {
            site->log->warn( sprintf qq{Store path "%s" does not exist}, $self->path );
        }
        return 1;
    },
);

sub BUILD {
    my ( $self ) = @_;
    $FILE_STORES{ $self->_realpath }++;
}

sub DEMOLISH {
    my ( $self, $in_global_destruction ) = @_;
    return if $in_global_destruction; # We're ending, we don't need to care anymore
    if ( --$FILE_STORES{ $self->_realpath } <= 0 ) {
        delete $FILE_STORES{ $self->_realpath };
    }
}

=method read_documents

    my $docs = $store->read_documents;

Read the directory C<path> and create the L<document
objects|Statocles::Document> inside.  Returns an arrayref of document objects.

=cut

sub read_documents {
    my ( $self ) = @_;
    $self->_check_exists;
    my $root_path = $self->path;
    my @docs;
    my $iter = $root_path->iterator( { recurse => 1, follow_symlinks => 1 } );
    while ( my $path = $iter->() ) {
        next unless $path->is_file;
        next unless $self->_is_owned_path( $path );
        next unless $self->is_document( $path );
        my $rel_path = rootdir->child( $path->relative( $root_path ) );
        push @docs, $self->read_document( $rel_path );
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

=method read_document

    my $doc = $store->read_document( $path )

Read a single L<document|Statocles::Document> in Markdown with optional YAML
frontmatter.

=cut

sub read_document {
    my ( $self, $path ) = @_;
    site->log->debug( "Read document: " . $path );
    my $full_path = $self->path->child( $path );
    my $relative_path = $full_path->relative( cwd );
    my %doc = $self->parse_frontmatter( $relative_path, $full_path->slurp_utf8 );
    my $class = $doc{class} ? use_module( delete $doc{class} ) : 'Statocles::Document';
    my $obj = eval { $class->new( %doc, path => $path, store => $self ) };
    if ( $@ ) {
        if ( ref $@ && $@->isa( 'Error::TypeTiny::Assertion' ) ) {
            if ( $@->attribute_name eq 'date' ) {
                die sprintf qq{Could not parse date "%s" in "%s": Does not match "YYYY-MM-DD" or "YYYY-MM-DD HH:MM:SS"\n},
                    $@->value,
                    $relative_path;
            }

            die sprintf qq{Error creating document in "%s": Value "%s" is not valid for attribute "%s" (expected "%s")\n},
                $relative_path,
                $@->value,
                $@->attribute_name,
                $@->type;
        }
        else {
            die sprintf qq{Error creating document in "%s": %s\n},
                $@;
        }
    }
    return $obj;
}

=method parse_frontmatter

    my %doc_attrs = $store->parse_frontmatter( $from, $content )

Parse a document with YAML frontmatter. $from is a string identifying where the
content comes from (a path or other identifier). $content is the content to
parse for frontmatter.

=cut

sub parse_frontmatter {
    my ( $self, $from, $content ) = @_;
    return unless $content;
    my $doc;

    my @lines = split /\n/, $content;
    if ( @lines && $lines[0] =~ /^---/ ) {
        shift @lines;

        # The next --- is the end of the YAML frontmatter
        my ( $i ) = grep { $lines[ $_ ] =~ /^---/ } 0..$#lines;

        # If we did not find the marker between YAML and Markdown
        if ( !defined $i ) {
            die qq{Could not find end of front matter (---) in "$from"\n};
        }

        # Before the marker is YAML
        eval {
            $doc = YAML::Load( join "\n", splice( @lines, 0, $i ), "" );
        };
        if ( $@ ) {
            die qq{Error parsing YAML in "$from"\n$@};
        }

        # Remove the last '---' mark
        shift @lines;
    }

    $doc->{content} = join "\n", @lines, "";

    return %$doc;
}

=method write_document

    $store->write_document( $path, $doc );

Write a L<document|Statocles::Document> to the store at the given store path.

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

    if ( defined wantarray ) {
        derp "Statocles::Store->write_document returning a value is deprecated and will be removed in v1.0. Use Statocles::Store->path to find the full path to the document.";
    }
    return $full_path;
}

sub _freeze_document {
    my ( $self, $doc ) = @_;
    delete $doc->{path}; # Path should not be in the document
    delete $doc->{store};
    if ( exists $doc->{date} ) {
        $doc->{date} = $doc->{date}->strftime('%Y-%m-%d %H:%M:%S');
    }
    for my $hash_type ( qw( links images ) ) {
        if ( exists $doc->{ $hash_type } && !keys %{ $doc->{ $hash_type } } ) {
            delete $doc->{ $hash_type };
        }
    }
    return $doc;
}

=method is_document

    my $bool = $store->is_document( $path );

Returns true if the path looks like a document path (matches the L</document_extensions>).

=cut

sub is_document {
    my ( $self, $path ) = @_;
    my $match = join "|", @{ $self->document_extensions };
    return $path =~ /[.](?:$match)$/;
}

=method read_file

    my $content = $store->read_file( $path )

Read the file from the given C<path>.

=cut

sub read_file {
    my ( $self, $path ) = @_;
    site->log->debug( "Read file: " . $path );
    return $self->path->child( $path )->slurp_utf8;
}

=method has_file

    my $bool = $store->has_file( $path )

Returns true if a file exists with the given C<path>.

NOTE: This should not be used to check for directories, as not all stores have
directories.

=cut

sub has_file {
    my ( $self, $path ) = @_;
    return $self->path->child( $path )->is_file;
}

=method find_files

    my $iter = $store->find_files( %opt )
    while ( my $path = $iter->() ) {
        # ...
    }

Returns an iterator that, when called, produces a single path suitable to be passed
to L<read_file>.

Available options are:

    include_documents      - If true, will include files that look like documents.
                             Defaults to false.

=cut

sub find_files {
    my ( $self, %opt ) = @_;
    $self->_check_exists;
    my $iter = $self->path->iterator({ recurse => 1 });
    return sub {
        my $path;
        while ( $path = $iter->() ) {
            next if $path->is_dir;
            next if !$self->_is_owned_path( $path );
            next if !$opt{include_documents} && $self->is_document( $path );
            last;
        }
        return unless $path; # iterator exhausted
        return $path->relative( $self->path )->absolute( '/' );
    };
}

=method open_file

    my $fh = $store->open_file( $path )

Open the file with the given path. Returns a filehandle.

The filehandle opened is using raw bytes, not UTF-8 characters.

=cut

sub open_file {
    my ( $self, $path ) = @_;
    return $self->path->child( $path )->openr_raw;
}

=method write_file

    $store->write_file( $path, $content );

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
    elsif ( blessed $content && $content->isa( 'Path::Tiny' ) ) {
        $content->copy( $full_path->touchpath );
    }
    else {
        $full_path->touchpath->spew_utf8( $content );
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
    $self->path->child( $path )->remove_tree;
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

