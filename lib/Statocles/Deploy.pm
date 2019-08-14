package Statocles::Deploy;
our $VERSION = '0.095';
# ABSTRACT: Base role for ways to deploy a site

use Statocles::Base 'Role';

=attr base_url

The base URL for this deploy. Site URLs will be automatically rewritten to be
based on this URL.

This allows you to have different versions of the site deployed to different
URLs.

=cut

has base_url => (
    is => 'ro',
    isa => Str,
);

=attr site

The site this deploy is deploying for. This will be set before the site calls
L<the deploy method|/deploy>.

=cut

has site => (
    is => 'rw',
    isa => InstanceOf['Statocles::Site'],
);

=method deploy

    my @paths = $deploy->deploy( $from_store, $message );

Deploy the site, copying from the given L<store object|Statocles::Store>, optionally
committing with the given message. Returns a list of file paths deployed.

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

=item L<Statocles::Deploy::File>

=item L<Statocles::Deploy::Git>

=back
