package Statocles::Store;
our $VERSION = '0.098';
# ABSTRACT: The source for data documents and files

use Statocles::Base 'Class';
use Scalar::Util qw( weaken blessed );
use Statocles::Util qw( derp );
use Statocles::Document;
use Statocles::File;

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
            Statocles->log( warn => sprintf qq{Store path "%s" does not exist}, $self->path );
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

=method is_document

    my $bool = $store->is_document( $path );

Returns true if the path looks like a document path (matches the L</document_extensions>).

=cut

sub is_document {
    my ( $self, $path ) = @_;
    my $match = join "|", @{ $self->document_extensions };
    return $path =~ /[.](?:$match)$/;
}

=method has_file

    my $bool = $store->has_file( $path )

Returns true if a file exists with the given C<path>.

=cut

sub has_file {
    my ( $self, $path ) = @_;
    return $self->path->child( $path )->is_file;
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
    Statocles->log( debug => "Write file: " . $path );
    my $full_path = $self->path->child( $path )->touchpath;

    #; say "Writing full path: " . $full_path;

    if ( ref $content eq 'GLOB' ) {
        my $fh = $full_path->openw_raw;
        while ( my $line = <$content> ) {
            $fh->print( $line );
        }
    }
    elsif ( blessed $content && $content->isa( 'Path::Tiny' ) ) {
        $content->copy( $full_path );
    }
    elsif ( blessed $content && $content->isa( 'Statocles::Document' ) ) {
        $full_path->spew_utf8( $content->deparse_content );
    }
    elsif ( blessed $content && $content->isa( 'Statocles::File' ) ) {
        $content->path->copy( $full_path );
    }
    else {
        $full_path->spew_utf8( $content );
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

=method iterator

    my $iter = $store->iterator;

Iterate over all the objects in this store. Returns an iterator that
will yield a L<Statocles::Document> object or a L<Statocles::File>
object.

Hidden files and folders are automatically ignored by this method.

    my $iter = $store->iterator;
    while ( my $obj = $iter->() ) {
        if ( $obj->isa( 'Statocles::Document' ) ) {
            ...;
        }
        else {
            ...;
        }
    }

=cut

sub iterator {
    my ( $self ) = @_;
    $self->_check_exists;
    my $iter = $self->path->iterator({ recurse => 1 });
    return sub {
        PATH:
        while ( my $path = $iter->() ) {
            next if $path->is_dir;
            next unless $self->_is_owned_path( $path );

            # Check for hidden files and folders
            next if $path->basename =~ /^[.]/;
            my $parent = $path->realpath->parent;
            while ( $self->path->subsumes( $parent ) && !$parent->is_rootdir ) {
                last if !$parent->basename;
                next PATH if $parent->basename =~ /^[.]/;
                $parent = $parent->parent;
            }

            my $from = $path->relative( $self->path );
            if ( $self->is_document( $path ) ) {
                my $content = $path->slurp_utf8;
                my $obj = eval {
                    Statocles::Document->parse_content(
                        content => $content,
                        path => $from.'',
                        store => $self,
                    )
                };
                if ( $@ ) {
                    if ( ref $@ && $@->isa( 'Error::TypeTiny::Assertion' ) ) {
                        if ( $@->attribute_name eq 'date' ) {
                            die sprintf qq{Could not parse date "%s" in "%s": Does not match "YYYY-MM-DD" or "YYYY-MM-DD HH:MM:SS"\n},
                                $@->value,
                                $from;
                        }

                        die sprintf qq{Error creating document in "%s": Value "%s" is not valid for attribute "%s" (expected "%s")\n},
                            $from,
                            $@->value,
                            $@->attribute_name,
                            $@->type;
                    }
                    else {
                        die sprintf qq{Error creating document in "%s": %s\n},
                            $from,
                            $@;
                    }
                }
                return $obj;
            }

            return Statocles::File->new(
                store => $self,
                path => $from.'',
            );
        }
        return undef;
    };
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

