package Statocles::Person;
our $VERSION = '0.099';
# ABSTRACT: Information about a person, including name and e-mail

=head1 SYNOPSIS

    # site.yml
    site:
        $class: Statocles::Site
        author:
            $class: Statocles::Person
            name: Doug Bell
            email: doug@example.com

    # Perl code
    my $person = Statocles::Person->new(
        name => 'Doug Bell',
        email => 'doug@example.com',
    );

=head1 DESCRIPTION

This class stores information about a person, most commonly an author of
a site or a document.

This class can parse plain strings like C<< Doug Bell <doug@example.com> >>
into an object with name and e-mail set correctly.

Person objects stringify into the C<name> field, for
backwards-compatibility.

=head1 SEE ALSO

=over

=item L<Statocles::Document/author>

=item L<Statocles::Site/author>

=back

=cut

use Statocles::Base 'Class';
use overload
    q{""} => sub { shift->name },
    ;

=attr name

The author's name. Required.

=cut

has name => (
    is => 'rw',
    isa => Str,
    required => 1,
);

=attr email

The author's email. Optional.

=cut

has email => (
    is => 'rw',
    isa => Str,
);

=method new

    my $person = Statocles::Person->new(
        name => 'Doug Bell',
        email => 'doug@example.com',
    );

    my $person = Statocles::Person->new( 'Doug Bell <doug@example.com>' );

Construct a new Person object. Arguments can be a list of name/value pairs, or
a single string with the format C<< Name <email@domain> >> (the e-mail part
is optional).

=cut

sub BUILDARGS {
    my ( $class, @args ) = @_;

    return $args[0] if @args == 1 && ref $args[0] eq 'HASH';

    if ( @args == 1 ) {
        if ( $args[0] =~ s/\s*<([^>]+)>\s*// ) {
            @args = (
                name => $args[0],
                email => $1,
            );
        }
        else {
            @args = (
                name => $args[0],
            );
        }
    }

    return { @args };
}

1;
