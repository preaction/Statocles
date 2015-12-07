package Statocles::Document;
# ABSTRACT: Base class for all Statocles documents

use Statocles::Base 'Class';
use Statocles::Image;

=attr path

The path to this document. This is not settable from the frontmatter.

=cut

has path => (
    is => 'rw',
    isa => Path,
    coerce => Path->coercion,
);

=attr title

    ---
    title: My First Post
    ---

The title of this document. Used in the template and the main page title.

=cut

has title => (
    is => 'rw',
    isa => Str,
);

=attr author

    ---
    author: preaction <doug@example.com>
    ---

The author of this document. Optional.

=cut

has author => (
    is => 'rw',
    isa => Str,
);

=attr content

The raw content of this document, in markdown. This is everything below
the ending C<---> of the frontmatter.

=cut

has content => (
    is => 'rw',
    isa => Str,
);

=attr tags

    ---
    tags: recipe, beef, cheese
    tags:
        - recipe
        - beef
        - cheese
    ---

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

    ---
    links:
        stylesheet:
            - href: /theme/css/extra.css
        alternate:
            - href: http://example.com/blog/alternate
              title: A contributed blog
    ---

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

=attr images

    ---
    images:
        title:
            src: title.jpg
            alt: A title image for this post
        banner: banner.jpg
    ---

Related images for this document. These are used by themes to display
images in appropriate templates. Each image has a category, like C<title>,
C<banner>, or C<thumbnail>, mapped to an L<image object|Statocles::Image>.
See the L<Statocles::Image|Statocles::Image> documentation for a full
list of supported attributes. The most common attributes are:

=over 4

=item src

The source path of the image. Relative paths will be resolved relative
to this document.

=item alt

The alternative text to display if the image cannot be downloaded or
rendered. Also the text to use for non-visual media.

=back

=cut

has images => (
    is => 'ro',
    isa => HashRef[InstanceOf['Statocles::Image']],
    default => sub { +{} },
    coerce => sub {
        my ( $ref ) = @_;
        my %img;
        for my $name ( keys %$ref ) {
            my $attrs = $ref->{ $name };
            if ( !ref $attrs ) {
                $attrs = { src => $attrs };
            }
            $img{ $name } = Statocles::Image->new(
                %{ $attrs },
            );
        }
        return \%img;
    },
);

=attr date

    ---
    date: 2015-03-27
    date: 2015-03-27 12:04:00
    ---

The date/time this document is for. For pages, this is the last modified date.
For blog posts, this is the post's date.

Should be in C<YYYY-MM-DD> or C<YYYY-MM-DD HH:MM:SS> format.

=cut

has date => (
    is => 'rw',
    isa => InstanceOf['Time::Piece'],
    predicate => 'has_date',
);

=attr template

    ---
    template: /blog/recipe.html
    ---

The path to a template override for this document. If set, the L<document
page|Statocles::Page::Document> will use this instead of the template provided
by the application.

The template path should not have the final extention (by default C<.ep>).
Different template parsers will have different extentions.

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

    ---
    layout: /site/layout-dark.html
    ---

The path to a layout template override for this document. If set, the L<document
page|Statocles::Page::Document> will use this instead of the layout provided
by the application.

The template path should not have the final extention (by default C<.ep>).
Different template parsers will have different extentions.

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

    ---
    data:
      - Eggs
      - Milk
      - Cheese
    ---
    % for my $item ( @{ $self->data } ) {
        <%= $item %>
    % }

Any kind of extra data to attach to this document, either array (like above),
hash, string, or number, or combinations of all of these. This is available
immediately in the document content, and later in the page template.

Every document's content is parsed as a template. The C<data> attribute can be
used in the template to allow for some structured data that would be cumbersome
to have to mark up time and again.

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

Documents are usually written as files, with the L<content|/content> in Markdown,
and the other attributes as frontmatter, a block of YAML at the top of the file.

An example file with frontmatter looks like:

    ---
    title: My Blog Post
    author: preaction
    links:
        stylesheet:
            - href: /theme/css/extra.css
    ---
    In my younger and more vulnerable years, my father gave me some

=head1 SEE ALSO

=over 4

=item L<Statocles::Help::Content>

The content guide describes how to edit content in Statocles sites, which are
represented by Document objects.

=back

