package Statocles::Page::Feed;
# ABSTRACT: A page for a feed of another page

use Statocles::Base 'Class';
with 'Statocles::Page';

=attr page

The source L<list page|Statocles::Page::List> to use for this feed.

=cut

has page => (
    is => 'ro',
    isa => InstanceOf['Statocles::Page::List'],
);

=method vars

Get the template variables for this page.

=cut

sub vars {
    my ( $self ) = @_;
    return (
        pages => $self->page->pages,
    );
}

1;
__END__

=head1 DESCRIPTION

A feed page encapsulates a L<list page|Statocles::Page::List> to display in a
feed view (RSS or ATOM or similar).

