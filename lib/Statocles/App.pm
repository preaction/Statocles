package Statocles::App;
# ABSTRACT: Base class for Statocles applications

use Statocles::Class;

1;
__END__

=head1 DESCRIPTION

A Statocles App turns Statocles::Documents into a set of Statocles::Pages
that can then be written to the filesystem (or served directly, if desired).
