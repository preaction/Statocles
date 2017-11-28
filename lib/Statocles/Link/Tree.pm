package Statocles::Link::Tree;
our $VERSION = '0.088';
# ABSTRACT: A link object with child links, making a tree

=head1 SYNOPSIS

    my $link = Statocles::Link::Tree->new(
        href => '/',
        text => 'Home',
        children => [
            {
                href => '/blog',
                text => 'Blog',
            },
            {
                href => '/projects',
                text => 'Projects',
            },
        ],
    );

=head1 DESCRIPTION

This class represents a link which is allowed to have child links.
This allows making trees of links for multi-level menus.

=head1 SEE ALSO

L<Statocles::Link>

=cut

use Statocles::Base 'Class';
extends 'Statocles::Link';

=attr children

    $link->children([
        # Object
        Statocles::Link::Tree->new(
            href => '/blog',
            text => 'Blog',
        ),

        # Hashref of attributes
        {
            href => '/about',
            text => 'About',
        },

        # URL only
        'http://example.com',
    ]);

The children of this link. Should be an arrayref of
C<Statocles::Link::Tree> objects, hashrefs of attributes for
C<Statocles::Link::Tree> objects, or URLs which will be used as the
C<href> attribute for a C<Statocles::Link::Tree> object.

=cut

has children => (
    is => 'rw',
    isa => LinkTreeArray,
    coerce => LinkTreeArray->coercion,
    default => sub { [] },
);

1;
