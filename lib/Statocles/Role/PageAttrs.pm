package Statocles::Role::PageAttrs;
our $VERSION = '0.090';
# ABSTRACT: A role implementing common attributes for pages/documents

use Statocles::Base 'Role';
use Statocles::Util qw( uniq_by );
use Statocles::Person;

=attr title

The title of the page. Any unsafe characters in the title (C<E<lt>>,
C<E<gt>>, C<">, and C<&>) will be escaped by the template, so no HTML
allowed.

=cut

has title => (
    is => 'rw',
    isa => Str,
    default => '',
);

=attr author

The author of the page.

=cut

has author => (
    is => 'rw',
    isa => Maybe[Person],
    coerce => Person->coercion,
    lazy => 1,
    builder => '_build_author',
);

sub _build_author {
    my ( $self ) = @_;
    return $self->site->author || Statocles::Person->new( name => '' );
}

=attr links

A hash of arrays of links to pages related to this page. Possible keys:

    feed        - Feed pages related to this page
    alternate   - Alternate versions of this page posted to other sites
    stylesheet  - Additional stylesheets for this page
    script      - Additional scripts for this page

Each item in the array is a L<link object|Statocles::Link>. The most common
attributes are:

    text        - The text of the link
    href        - The page for the link
    type        - The MIME type of the link, optional

=cut

has _links => (
    is => 'ro',
    isa => LinkHash,
    lazy => 1,
    default => sub { +{} },
    coerce => LinkHash->coercion,
    init_arg => 'links',
);

=attr images

A hash of images related to this page. Each value should be an L<image
object|Statocles::Image>.  These are used by themes to show images next
to articles, thumbnails, and/or shortcut icons.

=cut

has _images => (
    is => 'ro',
    isa => HashRef[InstanceOf['Statocles::Image']],
    lazy => 1,
    default => sub { +{} },
    init_arg => 'images',
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

=method links

    my @links = $page->links( $key );
    my $link = $page->links( $key );
    $page->links( $key => $add_link );

Get or append to the links set for the given key. See L<the links
attribute|/links> for some commonly-used keys.

If only one argument is given, returns a list of L<link
objects|Statocles::Link>. In scalar context, returns the first link in
the list.

If two or more arguments are given, append the new links to the given
key. C<$add_link> may be a URL string, a hash reference of L<link
attributes|Statocles::Link/ATTRIBUTES>, or a L<Statocles::Link
object|Statocles::Link>. When adding links, nothing is returned.

=cut

sub links {
    my ( $self, $name, @add_links ) = @_;
    if ( @add_links ) {
        push @{ $self->_links->{ $name } }, map { Link->coerce( $_ ) } @add_links;
        return;
    }
    return $self->_links if !$name;
    my @links = uniq_by { $_->href }
        $self->_links->{ $name } ? @{ $self->_links->{ $name } } : ();
    return wantarray ? @links : $links[0];
}

=method images

    my $image = $page->images( $key );

Get the images for the given key. See L<the images attribute|/images> for some
commonly-used keys. Returns an L<image object|Statocles::Image>.

=cut

sub images {
    my ( $self, $name ) = @_;
    # This exists here as a placeholder in case we ever need to handle
    # arrays of images, which I anticipate will happen when we build
    # image galleries or want to be able to pick a single random image
    # from an array.
    return $name ? $self->_images->{ $name } : $self->_images;
}

1;
