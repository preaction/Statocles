package Statocles::Util;
# ABSTRACT: Various utility functions to reduce dependencies

use Statocles::Base;
use Exporter 'import';

our @EXPORT_OK = qw(
    dircopy
);

=sub dircopy

    dircopy $source, $destination;

Copy everything in $source to $destination, recursively.

=cut

sub dircopy($$) {
    my ( $source, $destination ) = @_;
    $source = Path::Tiny->new( $source );
    $destination = Path::Tiny->new( $destination );
    $destination->mkpath;
    my $iter = $source->iterator({ recurse => 1 });
    while ( my $thing = $iter->() ) {
        my $relative = $thing->relative( $source );
        if ( $thing->is_dir ) {
            mkdir $destination->child( $relative );
        }
        else {
            $thing->copy( $destination->child( $relative ) );
        }
    }
}

1;
__END__

=head1 SYNOPSIS

    use Statocles::Util qw( dircopy );

    dircopy $source, $destination;

=head1 DESCRIPTION

This module contains some utility functions to help reduce non-core dependencies.

