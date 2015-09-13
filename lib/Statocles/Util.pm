package Statocles::Util;
# ABSTRACT: Various utility functions to reduce dependencies

use Statocles::Base;
use Exporter 'import';

our @EXPORT_OK = qw(
    dircopy run_editor
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

=sub run_editor

    my $was_run = run_editor( $path );

Invoke the user's text editor (from the C<EDITOR> environment variable) to edit
the given path. Returns true if an editor was invoked, false otherwise. If the
editor was not able to be invoked (C<EDITOR> was set but could not be run), an
exception is thrown.

=cut

sub run_editor {
    my ( $path ) = @_;
    return 0 unless $ENV{EDITOR};
    no warnings 'exec'; # We're checking everything ourselves
    system split( /\s+/, $ENV{EDITOR} ), $path;
    if ($? == -1) {
        die sprintf qq{Failed to invoke editor "%s": %s\n}, $ENV{EDITOR}, $!;
    }
    elsif ($? & 127) {
        die sprintf qq{Editor "%s" died from signal %d\n}, $ENV{EDITOR}, ( $? & 127 );
    }
    elsif ( my $exit = $? >> 8 ) {
        die sprintf qq{Editor "%s" exited with error (non-zero) status: %d\n}, $ENV{EDITOR}, $exit;
    }
    return 1;
}

1;
__END__

=head1 SYNOPSIS

    use Statocles::Util qw( dircopy );

    dircopy $source, $destination;

=head1 DESCRIPTION

This module contains some utility functions to help reduce non-core dependencies.

