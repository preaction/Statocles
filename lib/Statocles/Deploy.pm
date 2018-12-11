package Statocles::Deploy;
our $VERSION = '0.094';
# ABSTRACT: Base role for ways to deploy a site

=head1 DESCRIPTION

A Statocles::Deploy deploys a site to a destination, like Git, SFTP, or
otherwise.

=head1 SEE ALSO

L<Statocles::Deploy::Git>

=cut

use Mojo::Base 'Mojo::EventEmitter';

=attr base_url

The base URL for this deploy. Site URLs will be automatically rewritten to be
based on this URL.

This allows you to have different versions of the site deployed to different
URLs.

=cut

has base_url => '/';

=attr app

The app this deploy is deploying for. This will be set before the app calls
L<the deploy method|/deploy>.

=cut

has app => sub { die q{"app" is required} };

=method deploy

    my @paths = $deploy->deploy( $from_path, $message );

Deploy the site, copying from the given L<path object|Mojo::File>, optionally
committing with the given message. Returns a list of file paths deployed.

This must be implemented by the composing class.

=cut

sub deploy { ... }

1;

