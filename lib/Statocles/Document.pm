package Statocles::Document;
# ABSTRACT: Base class for all Statocles documents

use Statocles::Base 'Class';

=attr path

The path to this document. This is not settable from the frontmatter.

=cut

has path => (
    is => 'rw',
    isa => Path,
    coerce => Path->coercion,
);

=attr title

The title of this document.

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

The raw content of this document, in markdown. This is everything below
the frontmatter.

=cut

has content => (
    is => 'rw',
    isa => Str,
);

=attr tags

The tags for this document. Tags are used to categorize documents.

Tags may be specified as an array or as a comma-separated string of
tags.

=cut

has tags => (
    is => 'rw',
    isa => ArrayRef,
    default => sub { [] },
    coerce => sub {
        return [] unless $_[0];
        if ( !ref $_[0] ) {
            return [ split /\s*,\s*/, $_[0] ];
        }
        return $_[0];
    },
);

=attr links

Related links for this document. Links are used to build relationships
to other web addresses. Link categories are named based on their
relationship. Some possible categories are:

=over 4

=item stylesheet

Additional stylesheets for the content of this document.

=item script

Additional scripts for the content of this document.

=item alternate

A link to the same document in another format or posted to another web site

=back

Each category contains an arrayref of hashrefs of L<link objects|Statocles::Link>.
See the L<Statocles::Link|Statocles::Link> documentation for a full list of
supported attributes. The most common attributes are:

=over 4

=item href

The URL for the link.

=item text

The text of the link. Not needed for stylesheet or script links.

=back

=cut

has links => (
    is => 'rw',
    isa => LinkHash,
    default => sub { +{} },
    coerce => LinkHash->coercion,
);

=attr date

The date/time this document is for. For pages, this is the last modified date.
For blog posts, this is the post's date.

=cut

has date => (
    is => 'rw',
    isa => InstanceOf['Time::Piece'],
    predicate => 'has_date',
);

=attr template

A template override for this document. If set, the L<document
page|Statocles::Page::Document> will use this instead of the template provided
by the application.

=cut

has template => (
    is => 'rw',
    isa => Maybe[ArrayRef[Str]],
    coerce => sub {
        return $_[0] if ref $_[0];
        return [ grep { $_ ne '' } split m{/}, $_[0] ];
    },
    predicate => 'has_template',
);

=attr layout

A layout template override for this document. If set, the L<document
page|Statocles::Page::Document> will use this instead of the layout provided
by the application.

=cut

has layout => (
    is => 'rw',
    isa => Maybe[ArrayRef[Str]],
    coerce => sub {
        return $_[0] if ref $_[0];
        return [ grep { $_ ne '' } split m{/}, $_[0] ];
    },
    predicate => 'has_layout',
);

=attr data

Any kind of miscellaneous data. This is available immediately in the document
content.

=cut

has data => (
    is => 'rw',
);

1;
__END__

=head1 DESCRIPTION

A Statocles::Document is the base unit of content in Statocles.
L<Applications|Statocles::App> take documents to build
L<pages|Statocles::Page>.

This is the Model class in the Model-View-Controller pattern.

=head1 SEE ALSO

=over 4

=item L<Statocles::Help::Content>

The content guide describes how to edit content in Statocles sites, which are
represented by Document objects.

=back

