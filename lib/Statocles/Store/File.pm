package Statocles::Store::File;
# ABSTRACT: (DEPRECATED) A store made up of plain files

use Statocles::Base 'Class';
extends 'Statocles::Store';

warn "Statocles::Store::File is deprecated and will be removed in v1.000. Please use Statocles::Store instead. See Statocles::Help::Upgrading for more information.\n";

1;
__END__

=head1 DESCRIPTION

This store was removed and its functionality put completely into L<Statocles::Store>.
This module is deprecated and will be removed at the 2.0 release according to the
deprecation policy L<Statocles::Help::Policy>. See L<Statocles::Help::Upgrading>
for how to upgrade.
