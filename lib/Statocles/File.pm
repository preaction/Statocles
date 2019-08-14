package Statocles::File;
our $VERSION = '0.095';
# ABSTRACT: A wrapper for a file on the filesystem

=head1 SYNOPSIS

    my $store = Statocles::Store->new( path => 'my/store' );
    my $file = Statocles::File->new(
        store => $store,
        path => 'file.txt', # my/store/file.txt
    );

=head1 DESCRIPTION

This class encapsulates the information for a file on the filesystem and provides
methods to read the file.

=head1 SEE ALSO

L<Statocles::Store>, L<Statocles::Document>

=cut

use Statocles::Base 'Class';

=attr store

The store that contains this file

=cut

has store => (
    is => 'ro',
    isa => StoreType,
    coerce => StoreType->coercion,
);

=attr path

The path to this file, relative to the store

=cut

has path => (
    is => 'ro',
    isa => Path,
    coerce => Path->coercion,
);

=attr fh

The file handle containing the contents of the page.

=cut

has fh => (
    is => 'ro',
    isa => FileHandle,
    lazy => 1,
    default => sub {
        return shift->path->openr_utf8;
    },
);

1;
