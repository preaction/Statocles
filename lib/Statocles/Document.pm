package Statocles::Document;
our $VERSION = '0.093';
# ABSTRACT: Base class for all Statocles documents

use Statocles::Base 'Class';
with 'Statocles::Role::PageAttrs';
use Statocles::Image;
use Statocles::Util qw( derp );
use YAML ();
use JSON::PP qw( decode_json );

=attr path

The path to this document. This is not settable from the frontmatter.

=cut

has path => (
    is => 'rw',
    isa => PagePath,
    coerce => PagePath->coercion,
);

=attr store

The Store this document comes from. This is not settable from the
frontmatter.

=cut

has store => (
    is => 'ro',
    isa => StoreType,
    coerce => StoreType->coercion,
);

=attr title

    ---
    title: My First Post
    ---

The title of this document. Used in the template and the main page
title. Any unsafe characters in the title (C<E<lt>>, C<E<gt>>, C<">, and
C<&>) will be escaped by the template, so no HTML allowed.

=cut

=attr author

    ---
    author: preaction <doug@example.com>
    ---

The author of this document. Optional. Either a simple string containing
the author's name and optionally, in E<gt>E<lt>, the author's e-mail address,
or a hashref of L<Statocles::Person attributes|Statocles::Person/ATTRIBUTES>.

    ---
    # Using Statocles::Person attributes
    author:
        name: Doug Bell
        email: doug@example.com
    ---

=cut

sub _build_author { }

=attr status

The publishing status of this document.  Optional. Statocles apps can
examine this to determine whether to turn a document into a page.  The
default value is C<published>; other reasonable values could include
C<draft> or C<private>.

=cut

has status => (
    is => 'rw',
    isa => Str,
    default => 'published',
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
    isa => DateTimeObj,
    coerce => DateTimeObj->coercion,
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
      ingredients:
        - Eggs
        - Milk
        - Cheese
    ---
    % for my $item ( @{ $self->data->{ingredients} } ) {
        <%= $item %>
    % }

A hash of extra data to attach to this document. This is available
immediately in the document content, and later in the page template.

Every document's content is parsed as a template. The C<data> attribute can be
used in the template to allow for some structured data that would be cumbersome
to have to mark up time and again.

=cut

has data => (
    is => 'rw',
);

=attr disable_content_template

    ---
    disable_content_template: true
    ---

This disables processing the content as a template. This can speed up processing
when the content is not using template directives. 

This can be also set in the application
(L<Statocles::App/disable_content_template>), or for the entire site
(L<Statocles::Site/disable_content_template>).

=cut

has disable_content_template => (
    is => 'ro',
    isa => Bool,
    lazy => 1,
    default => 0,
    predicate => 'has_disable_content_template',
);

around BUILDARGS => sub {
    my ( $orig, $self, @args ) = @_;
    my $args = $self->$orig( @args );
    if ( defined $args->{data} && ref $args->{data} ne 'HASH' ) {
        derp qq{Invalid data attribute in document "%s". Data attributes that are not hashes are deprecated and will be removed in v2.0. Please use a hash instead.},
            $args->{path};
    }
    return $args;
};

=method parse_content

    my $doc = $class->parse_content(
        path => $path,
        store => $store,
        content => $content,
    );

Construct a document the given content, with the given additional
attributes. Returns a new C<Statocles::Document> object.

This parses the YAML or JSON frontmatter into the document's attributes,
putting the rest of the file after the YAML or JSON frontmatter in the
C<content> attribute.

Custom document classes can override this method to change how file content is
parsed.

=cut

sub parse_content {
    my ( $class, %args ) = @_;

    my %doc;
    my $content = delete $args{content} or die "Content is required";

    my @lines = split /\n/, $content;
    # YAML frontmatter
    if ( @lines && $lines[0] =~ /^---/ ) {
        shift @lines;

        # The next --- is the end of the YAML frontmatter
        my ( $i ) = grep { $lines[ $_ ] =~ /^---/ } 0..$#lines;

        # If we did not find the marker between YAML and Markdown
        if ( !defined $i ) {
            die qq{Could not find end of YAML front matter (---)\n};
        }

        # Before the marker is YAML
        eval {
            %doc = %{ YAML::Load( join "\n", splice( @lines, 0, $i ), "" ) };
        };
        if ( $@ ) {
            die qq{Error parsing YAML in "$args{path}"\n$@};
        }

        # Remove the last '---' mark
        shift @lines;
    }
    # JSON frontmatter
    elsif ( @lines && $lines[0] =~ /^{/ ) {
        my $json;
        if ( $lines[0] =~ /\}$/ ) {
            # The JSON is all on a single line
            $json = shift @lines;
        }
        else {
            # The } on a line by itself is the last line of JSON
            my ( $i ) = grep { $lines[ $_ ] =~ /^}$/ } 0..$#lines;
            # If we did not find the marker between YAML and Markdown
            if ( !defined $i ) {
                die qq{Could not find end of JSON front matter (\})\n};
            }
            $json = join "\n", splice( @lines, 0, $i+1 );
        }
        eval {
            %doc = %{ decode_json( $json ) };
        };
        if ( $@ ) {
            die qq{Error parsing JSON: $@\n};
        }
    }

    # The remaining lines are content
    $doc{content} = join "\n", @lines, "";

    delete $doc{path};
    delete $doc{store};

    return $class->new( %doc, %args );
}

=method deparse_content

    my $content = $doc->deparse_content;

Deparse the document into a string ready to be stored in a file. This will
serialize the document attributes into YAML frontmatter, and place the content
after.

=cut

sub deparse_content {
    my ( $self ) = @_;
    my %data = %$self;
    delete $data{ store };
    delete $data{ path };
    my $content = delete $data{content};

    # Serialize date correctly
    if ( exists $data{date} ) {
        $data{date} = $data{date}->strftime('%Y-%m-%d %H:%M:%S');
    }

    # Don't save empty references
    for my $hash_type ( qw( links images ) ) {
        if ( exists $data{ $hash_type } && !keys %{ $data{ $hash_type } } ) {
            delete $data{ $hash_type };
        }
    }
    for my $array_type ( qw( tags ) ) {
        if ( exists $data{ $array_type } && !@{ $data{ $array_type } } ) {
            delete $data{ $array_type };
        }
    }

    return YAML::Dump( \%data ) . "---\n". $content;
}

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

