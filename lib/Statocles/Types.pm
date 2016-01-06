package Statocles::Types;
# ABSTRACT: Type constraints and coercions for Statocles

use strict;
use warnings;
use feature qw( :5.10 );
use Type::Library -base, -declare => qw(
    Store Theme Link LinkArray LinkHash TimePiece DateStr DateTimeStr
);
use Type::Utils -all;
use Types::Standard -types;
use Time::Piece;

role_type Store, { role => "Statocles::Store" };
coerce Store, from Str, via { Statocles::Store->new( path => $_ ) };
coerce Store, from InstanceOf['Path::Tiny'], via { Statocles::Store->new( path => $_ ) };

class_type Theme, { class => "Statocles::Theme" };
coerce Theme, from Str, via { require Statocles::Theme; Statocles::Theme->new( store => $_ ) };
coerce Theme, from InstanceOf['Path::Tiny'], via { require Statocles::Theme; Statocles::Theme->new( store => $_ ) };

class_type Link, { class => "Statocles::Link" };
coerce Link, from HashRef, via { Statocles::Link->new( $_ ) };
coerce Link, from Str, via { Statocles::Link->new( href => $_ ) };

declare LinkArray, as ArrayRef[Link], coerce => 1;
coerce LinkArray, from ArrayRef[HashRef],
    via {
        [ map { Statocles::Link->new( $_ ) } @$_ ];
    };

declare LinkHash, as HashRef[LinkArray], coerce => 1;
coerce LinkHash, from HashRef[ArrayRef[HashRef]],
    via {
        my %hash = %$_;
        my $out = {
            ( map {; $_ => [ map { Statocles::Link->new( $_ ) } @{ $hash{$_} } ] } keys %hash ),
        };
        return $out;
    };

coerce LinkHash, from HashRef[HashRef],
    via {
        my %hash = %$_;
        my $out = {
            ( map {; $_ => [ Statocles::Link->new( $hash{$_} ) ] } keys %hash ),
        };
        return $out;
    };

my $DATETIME_FORMAT = '%Y-%m-%d %H:%M:%S';
my $DATE_FORMAT = '%Y-%m-%d';

class_type TimePiece, { class => 'Time::Piece' };
declare DateStr, as Str, where { m{^\d{4}-?\d{2}-?\d{2}$} };
declare DateTimeStr, as Str, where { m{^\d{4}-?\d{2}-?\d{2} \d{2}:\d{2}:\d{2}$} };
coerce TimePiece, from DateStr, via { Time::Piece->strptime( $_, $DATE_FORMAT ) };
coerce TimePiece, from DateTimeStr, via { Time::Piece->strptime( $_, $DATETIME_FORMAT ) };

# Down here to resolve circular dependencies
require Statocles::Store;
require Statocles::Link;

1;
__END__

=head1 SYNOPSIS

    use Statocles::Class;
    use Statocles::Types qw( :all );

    has store => (
        isa => Store,
        coerce => Store->coercion,
    );

    has theme => (
        isa => Theme,
        coerce => Theme->coercion,
    );

    has link => (
        isa => Link,
        coerce => Link->coercion,
    );
    has links => (
        isa => LinkArray,
        coerce => LinkArray->coercion,
    );
    has nav => (
        isa => LinkHash,
        coerce => LinkHash->coercion,
    );

    has date => (
        isa => TimePiece,
        coerce => TimePiece->coercion,
    );

=head1 DESCRIPTION

This is a L<type library|Type::Tiny::Manual::Library> for common Statocles types.

=head1 TYPES

=head2 Store

A L<Statocles::Store> object.

This can be coerced from any L<Path::Tiny> object or any String, which will be
used as the filesystem path to the store's documents (the L<path
attribute|Statocles::Store/path>). The coercion creates a
L<Statocles::Store> object.

=head2 Theme

A L<Statocles::Theme> object.

This can be coerced from any L<Path::Tiny> object or any String, which will be
used as the L<store attribute|Statocles::Theme/store> (which will then be given
to the Store's path attribute).

=head2 Link

A L<Statocles::Link> object.

This can be coerced from any HashRef.

=head2 LinkArray

An arrayref of L<Statocles::Link> objects.

This can be coerced from any ArrayRef of HashRefs.

=head2 LinkHash

A hashref of arrayrefs of L<Statocles::Link> objects. Useful for the named links like
L<site navigation|Statocles::Site/nav>.

This can be coerced from any HashRef of ArrayRef of HashRefs.

=head2 TimePiece

A L<Time::Piece> object representing a date/time. This can be coerced from a
C<YYYY-MM-DD> string or a C<YYYY-MM-DD HH:MM:SS> string.

