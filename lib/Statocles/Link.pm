package Statocles::Link;
our $VERSION = '0.087';
# ABSTRACT: A link object to build <a> and <link> tags

use Statocles::Base 'Class';
use Scalar::Util qw( blessed );

=attr href

The URL location being linked to. Sets the C<href> attribute.

=cut

has href => (
    is => 'rw',
    isa => Str,
    required => 1,
    coerce => sub {
        my ( $href ) = @_;
        if ( blessed $href && $href->isa( 'Path::Tiny' ) ) {
            return $href->absolute( '/' )->stringify;
        }
        return $href;
    },
);

=attr text

The text inside the link tag. Only useful for <a> links.

=cut

has text => (
    is => 'ro',
    isa => Maybe[Str],
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

=attr type

The MIME type of the resource being linked to. Sets the C<type> attribute for C<link>
tags.

=cut

has type => (
    is => 'ro',
    isa => Str,
);

=method new_from_element

    my $link = Statocles::Link->new_from_element( $dom_elem );

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
__END__

=head1 SYNOPSIS

    my $link = Statocles::Link->new( text => 'Foo', href => 'http://example.com' );
    say $link->href;
    say $link->text;

    say sprintf '<a href="%s">%s</a>', $link->href, $link->text;

=head1 DESCRIPTION

This object encapsulates a link (either an C<a> or C<link> tag in HTML). These objects
are friendly for templates and can provide some sanity checks.

