package Statocles::App;
# ABSTRACT: Base class for Statocles applications

use Statocles::Base 'Class';


=attr site

The site this app is part of.

=cut

has site => (
    is => 'rw',
    isa => InstanceOf['Statocles::Site'],
);

1;
__END__

=head1 DESCRIPTION

A Statocles App turns L<documents|Statocles::Documents> into a set of
L<pages|Statocles::Pages> that can then be written to the filesystem (or served
directly, if desired).
