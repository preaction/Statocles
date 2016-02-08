package Statocles::Image;
# ABSTRACT: A reference to an image

=head1 SYNOPSIS

    my $img = Statocles::Image->new(
        src     => '/path/to/image.jpg',
        alt     => 'Alternative text',
    );

=head1 DESCRIPTION

This class holds a link to an image, and the attributes required to
render its markup. This is used by L<documents|Statocles::Document/images>
to associate images with the content.

=cut

use Statocles::Base 'Class';
use Scalar::Util qw( blessed );

=attr src

The source URL of the image. Required.

=cut

has src => (
    is => 'rw',
    isa => Str,
    required => 1,
    coerce => sub {
        my ( $href ) = @_;
        if ( blessed $href && $href->isa( 'Path::Tiny' ) ) {
            return $href->stringify;
        }
        return $href;
    },
);

=attr alt

The text to display if the image cannot be fetched or rendered. This is also
the text to use for non-visual media.

If missing, the image is presentational only, not content.

=cut

has alt => (
    is => 'rw',
    isa => Str,
    default => sub { '' },
);

=attr width

The width of the image, in pixels.

=cut

has width => (
    is => 'rw',
    isa => Int,
);

=attr height

The height of the image, in pixels.

=cut

has height => (
    is => 'rw',
    isa => Int,
);

=attr role

The L<ARIA|http://www.w3.org/TR/wai-aria/> role for this image. If the L</alt>
attribute is empty, this attribute defaults to C<"presentation">.

=cut

has role => (
    is => 'rw',
    isa => Maybe[Str],
    lazy => 1,
    default => sub {
        return !$_[0]->alt ? 'presentation' : undef;
    },
);

=attr data

A hash of arbitrary data available to theme templates. This is a good place to
put extra structured data like image credits, copyright, or location.

=cut

has data => (
    is => 'ro',
    isa => HashRef,
    default => sub { {} },
);

1;
