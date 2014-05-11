package Statocles::Command;
# ABSTRACT: The statocles command-line interface

use Statocles::Class;
use Getopt::Long qw( GetOptionsFromArray );
use Pod::Usage::Return qw( pod2usage );
use Beam::Wire;

=attr site

The Statocles::Site we're working with.

=cut

has site => (
    is => 'ro',
    isa => InstanceOf['Statocles::Site'],
);

=method main( @argv )

Run the command given in @argv. See L<statocles> for a list of commands and
options.

=cut

sub main {
    my ( $class, @argv ) = @_;

    my %opt = (
        config => 'site.yml',
        site => 'site',
    );
    GetOptionsFromArray( \@argv, \%opt,
        'config:s',
        'site:s',
        'help|h',
    );
    return pod2usage(0) if $opt{help};

    my $wire = Beam::Wire->new( file => $opt{config} );

    my $cmd = $class->new(
        site => $wire->get( $opt{site} ),
    );

    if ( @argv == 1 ) {
        my $method = $argv[0];
        $cmd->site->$method;
    }

    return 0;
}

1;
__END__

=head1 SYNOPSIS

    use Statocles::Command;
    exit Statocles::Command->main( @ARGV );

=head1 DESCRIPTION

This module implements the Statocles command-line interface.
