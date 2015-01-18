package Statocles::Link;
# ABSTRACT: A link object to build <a> and <link> tags

use Statocles::Base 'Class';

=attr href

The URL location being linked to. Sets the C<href> attribute.

=cut

has href => (
    is => 'rw',
    isa => Str,
    required => 1,
);

=attr text

The text inside the link tag. Only useful for <a> links.

=cut

has text => (
    is => 'ro',
    isa => Str,
    lazy => 1,
    default => sub {
        # For ease of transition, let's default to title, which we used for the
        # text prior to this class.
        return $_[0]->title;
    },
);

=attr title

The title of the link. Sets the C<title> attribute.

=cut

has title => (
    is => 'ro',
    isa => Str,
);

=attr rel

The relationship of the link. Sets the C<rel> attribute.

=cut

has rel => (
    is => 'ro',
    isa => Str,
);

sub BUILD {
    my ( $self ) = @_;
    # Either text or title must be set, so that we can set the text
    # We want this to die as soon as possible, so we can't die in the attribute
    # default builder
    die "Link 'text' attribute is required" unless $self->text;
}

=method new_from_element( $element )

Construct a new Statocles::Link out of a Mojo::DOM element (either an <a> or a <link>).

=cut

sub new_from_element {
    my ( $class, $elem ) = @_;
    return $class->new(
        ( map {; $_ => $elem->attr( $_ ) } grep { $elem->attr( $_ ) } qw( href title rel ) ),
        ( map {; $_ => $elem->$_ } qw( text ) ),
    );
}

1;

