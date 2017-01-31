package Statocles::Store::File;
our $VERSION = '0.084';
# ABSTRACT: (DEPRECATED) A store made up of plain files

use Statocles::Base 'Class';
use Statocles::Util qw( derp );
extends 'Statocles::Store';

derp "Statocles::Store::File is deprecated and will be removed in v1.000. Please use Statocles::Store instead.";

1;
__END__

=head1 DESCRIPTION

This store was removed and its functionality put completely into L<Statocles::Store>.
This module is deprecated and will be removed at the 2.0 release according to the
deprecation policy L<Statocles::Help::Policy>. See L<Statocles::Help::Upgrading>
for how to upgrade.
