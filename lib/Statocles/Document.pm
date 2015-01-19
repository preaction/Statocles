package Statocles::Document;
# ABSTRACT: Base class for all Statocles documents

use Statocles::Base 'Class';

=attr path

The path to this document.

=cut

has path => (
    is => 'rw',
    isa => Path,
    coerce => Path->coercion,
);

=attr title

The title from this document.

=cut

has title => (
    is => 'rw',
    isa => Str,
);

=attr author

The author of this document.

=cut

has author => (
    is => 'rw',
    isa => Str,
);

=attr content

The raw content of this document, in markdown.

=cut

has content => (
    is => 'rw',
    isa => Str,
);

=attr tags

The tags for this document. Tags are used to categorize documents.

Tags may be specified as an array or as a comma-seperated string of
tags.

=cut

has tags => (
    is => 'rw',
    isa => ArrayRef,
    default => sub { [] },
    coerce => sub {
        if ( !ref $_[0] ) {
            return [ split /\s*,\s*/, $_[0] ];
        }
        return $_[0];
    },
);

=attr links

Related links for this document. Links are used to build relationships
to other web addresses. Link categories are named based on their
relationship.

    alternate - The same document posted to another web site

Each category contains an arrayref of hashrefs of L<link objects|Statocles::Link>.
See the L<Statocles::Link|Statocles::Link> documentation for a full list of
supported attributes. The most common attributes are:

    text - The text of the link
    href - The URL for the link

=cut

has links => (
    is => 'rw',
    isa => LinkHash,
    default => sub { +{} },
    coerce => LinkHash->coercion,
);

=attr last_modified

The date/time this document was last modified.

=cut

has last_modified => (
    is => 'rw',
    isa => InstanceOf['Time::Piece'],
);

1;
__END__

=head1 DESCRIPTION

A Statocles::Document is the base unit of content in Statocles.
L<Applications|Statocles::App> take documents to build
L<pages|Statocles::Page>.

This is the Model class in the Model-View-Controller pattern.
