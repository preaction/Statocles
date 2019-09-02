package Statocles::Util;
our $VERSION = '2.000';
# ABSTRACT: Various utility functions to reduce dependencies

use Exporter 'import';
use Mojo::JSON qw( to_json );
use Path::Tiny;

our @EXPORT_OK = qw(
    trim dircopy run_editor uniq_by derp read_stdin
);

#pod =sub trim
#pod
#pod     my $trimmed = trim $untrimmed;
#pod
#pod Trim the leading and trailing whitespace from the given scalar.
#pod
#pod =cut

sub trim(_) {
    return $_[0] if !$_[0];
    $_[0] =~ s/^\s+//;
    $_[0] =~ s/\s+$//;
    return $_[0];
}

#pod =sub dircopy
#pod
#pod     dircopy $source, $destination;
#pod
#pod Copy everything in $source to $destination, recursively.
#pod
#pod =cut

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

#pod =sub run_editor
#pod
#pod     my $content = run_editor( $path );
#pod
#pod Invoke the user's text editor (from the C<EDITOR> environment variable)
#pod to edit the given path. Returns the content if the editor was invoked,
#pod or C<undef> C<EDITOR> was not set. If the editor was not able to be
#pod invoked (C<EDITOR> was set but could not be run), an exception is
#pod thrown.
#pod
#pod =cut

sub run_editor {
    my ( $path ) = @_;
    return undef unless $ENV{EDITOR};
    no warnings 'exec'; # We're checking everything ourselves
    # use string "system" as env-vars need to quote to protect from spaces
    # therefore, we quote path, then append it
    system $ENV{EDITOR} . qq{ "$path"};
    if ($? != 0) {
        die sprintf qq{Editor "%s" exited with error (non-zero) status: %d\n}, $ENV{EDITOR}, $?;
    }
    return $path->slurp_utf8;
}

#pod =sub uniq_by
#pod
#pod     my @uniq_links = uniq_by { $_->href } @links;
#pod
#pod Filter a list into its unique items based on the result of the passed-in block.
#pod This lets us get unique links from their C<href> attribute.
#pod
#pod =cut

sub uniq_by(&@) {
    my ( $sub, @list ) = @_;
    my ( %found, @out );
    for my $i ( @list ) {
        local $_ = $i;
        push @out, $i if !$found{ $sub->() }++;
    }
    return @out;
}

#pod =sub derp
#pod
#pod     derp "This feature is deprecated in file '%s'", $file;
#pod
#pod Print out a deprecation message as a warning. A message will only be
#pod printed once for each set of arguments.
#pod
#pod =cut

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

#pod =sub read_stdin
#pod
#pod     my $test = read_stdin();
#pod
#pod Reads the standard input. Intended to provide a point to monkey-patch
#pod for tests.
#pod
#pod =cut

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

=pod

=encoding UTF-8

=head1 NAME

Statocles::Util - Various utility functions to reduce dependencies

=head1 VERSION

version 0.093

=head1 SYNOPSIS

    use Statocles::Util qw( dircopy );

    dircopy $source, $destination;

=head1 DESCRIPTION

This module contains some utility functions to help reduce non-core dependencies.

=head1 SUBROUTINES

=head2 trim

    my $trimmed = trim $untrimmed;

Trim the leading and trailing whitespace from the given scalar.

=head2 dircopy

    dircopy $source, $destination;

Copy everything in $source to $destination, recursively.

=head2 run_editor

    my $content = run_editor( $path );

Invoke the user's text editor (from the C<EDITOR> environment variable)
to edit the given path. Returns the content if the editor was invoked,
or C<undef> C<EDITOR> was not set. If the editor was not able to be
invoked (C<EDITOR> was set but could not be run), an exception is
thrown.

=head2 uniq_by

    my @uniq_links = uniq_by { $_->href } @links;

Filter a list into its unique items based on the result of the passed-in block.
This lets us get unique links from their C<href> attribute.

=head2 derp

    derp "This feature is deprecated in file '%s'", $file;

Print out a deprecation message as a warning. A message will only be
printed once for each set of arguments.

=head2 read_stdin

    my $test = read_stdin();

Reads the standard input. Intended to provide a point to monkey-patch
for tests.

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
