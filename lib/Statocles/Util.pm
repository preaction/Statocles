package Statocles::Util;
our $VERSION = '0.092';
# ABSTRACT: Various utility functions to reduce dependencies

use Statocles::Base;
use Exporter 'import';
use Mojo::JSON qw( to_json );

our @EXPORT_OK = qw(
    trim dircopy run_editor uniq_by derp read_stdin
);

=sub trim

    my $trimmed = trim $untrimmed;

Trim the leading and trailing whitespace from the given scalar.

=cut

sub trim(_) {
    return $_[0] if !$_[0];
    $_[0] =~ s/^\s+//;
    $_[0] =~ s/\s+$//;
    return $_[0];
}

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

Invoke the user's text editor (from the C<EDITOR> environment variable)
to edit the given path. Returns true if an editor was invoked, false if
C<EDITOR> was not set. If the editor was not able to be invoked
(C<EDITOR> was set but could not be run), an exception is thrown.

=cut

sub run_editor {
    my ( $path ) = @_;
    return 0 unless $ENV{EDITOR};
    no warnings 'exec'; # We're checking everything ourselves
    # use string "system" as env-vars need to quote to protect from spaces
    # therefore, we quote path, then append it
    system $ENV{EDITOR} . qq{ "$path"};
    if ($? != 0) {
        die sprintf qq{Editor "%s" exited with error (non-zero) status: %d\n}, $ENV{EDITOR}, $?;
    }
    return 1;
}

=sub uniq_by

    my @uniq_links = uniq_by { $_->href } @links;

Filter a list into its unique items based on the result of the passed-in block.
This lets us get unique links from their C<href> attribute.

=cut

sub uniq_by(&@) {
    my ( $sub, @list ) = @_;
    my ( %found, @out );
    for my $i ( @list ) {
        local $_ = $i;
        push @out, $i if !$found{ $sub->() }++;
    }
    return @out;
}

=sub derp

    derp "This feature is deprecated in file '%s'", $file;

Print out a deprecation message as a warning. A message will only be
printed once for each set of arguments.

=cut

our %DERPED;
sub derp(@) {
    my @args = @_;
    my $key = to_json \@args;
    return if $DERPED{ $key };
    if ( $args[0] !~ /\.$/ ) {
        $args[0] .= '.';
    }
    warn sprintf( $args[0], @args[1..$#args] ). " See Statocles::Help::Upgrading\n";
    $DERPED{ $key } = 1;
}

=sub read_stdin

    my $test = read_stdin();

Reads the standard input. Intended to provide a point to monkey-patch
for tests.

=cut

sub read_stdin {
    if ( !-t *STDIN && !-z _ ) {
        my $content = do { local $/; <STDIN> };

        # Re-open STDIN as the TTY so that the editor (vim) can use it
        # XXX Is this also a problem on Windows?
        if ( -e '/dev/tty' ) {
            close STDIN;
            open STDIN, '/dev/tty';
        }

        return $content;
    }
}

1;
__END__

=head1 SYNOPSIS

    use Statocles::Util qw( dircopy );

    dircopy $source, $destination;

=head1 DESCRIPTION

This module contains some utility functions to help reduce non-core dependencies.

