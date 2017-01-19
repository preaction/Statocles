package Statocles::Event;
our $VERSION = '0.083';
# ABSTRACT: Events objects for Statocles

=head1 EVENTS

=head2 Statocles::Event::Pages

An event with L<page objects|Statocles::Page>.

=cut

package Statocles::Event::Pages;

use Statocles::Base 'Class';
extends 'Beam::Event';

=attr pages

An array of L<Statocles::Page> objects

=cut

has pages => (
    is => 'ro',
    isa => ArrayRef[ConsumerOf['Statocles::Page']],
    required => 1,
);

1;
