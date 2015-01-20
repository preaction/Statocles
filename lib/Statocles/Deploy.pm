package Statocles::Deploy;
# ABSTRACT: Base role for ways to deploy a site

use Statocles::Base 'Role';

=method deploy( FROM_STORE, MESSAGE )

Deploy the site, copying from the given L<store object|Statocles::Store>, optionally
committing with the given message.

This must be implemented by the composing class.

=cut

requires qw( deploy );

1;
__END__

=head1 DESCRIPTION

A Statocles::Deploy deploys a site to a destination, like Git, SFTP, or
otherwise.

=head1 SEE ALSO

=over 4

=item L<Statocles::Store>

=back
