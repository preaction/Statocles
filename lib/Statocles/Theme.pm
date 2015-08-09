package Statocles::Theme;
# ABSTRACT: Templates, headers, footers, and navigation

use Statocles::Base 'Class';
use File::Share qw( dist_dir );
use Scalar::Util qw( blessed );
use Statocles::Template;

=attr store

The source L<store|Statocles::Store> for this theme.

If the path begins with ::, will pull one of the Statocles default
themes from the Statocles share directory.

=cut

has store => (
    is => 'ro',
    isa => Store,
    coerce => Store->coercion,
    required => 1,
);

=attr include_stores

An array of L<stores|Statocles::Store> to look for includes. The L</store> is
added at the end of this list.

=cut

has include_stores => (
    is => 'ro',
    isa => ArrayRef[Store],
    default => sub { [] },
    coerce => sub {
        my ( $thing ) = @_;
        if ( ref $thing eq 'ARRAY' ) {
            return [ map { Store->coercion->( $_ ) } @$thing ];
        }
        return [ Store->coercion->( $thing ) ];
    },
);

=attr _templates

The cached template objects for this theme.

=cut

has _templates => (
    is => 'ro',
    isa => HashRef[InstanceOf['Statocles::Template']],
    default => sub { {} },
    lazy => 1,  # Must be lazy or the clearer won't re-init the default
    clearer => 'clear',
);

=method BUILDARGS

Handle the path :: share theme.

=cut

around BUILDARGS => sub {
    my ( $orig, $self, @args ) = @_;
    my $args = $self->$orig( @args );
    if ( $args->{store} && !ref $args->{store} && $args->{store} =~ /^::/ ) {
        my $name = substr $args->{store}, 2;
        $args->{store} = Path::Tiny->new( dist_dir( 'Statocles' ) )->child( 'theme', $name );
    }
    return $args;
};

=method read

    my $tmpl = $theme->read( $path )

Read the template for the given C<path> and create the
L<template|Statocles::Template> object.

=cut

sub read {
    my ( $self, $path ) = @_;
    $path .= '.ep';

    my $content = eval { $self->store->read_file( $path ); };
    if ( $@ ) {
        if ( blessed $@ && $@->isa( 'Path::Tiny::Error' ) && $@->{op} =~ /^open/ ) {
            die sprintf 'ERROR: Template "%s" does not exist in theme directory "%s"' . "\n",
                $path, $self->store->path;
        }
        else {
            die $@;
        }
    }

    return $self->build_template( $path, $content );
}

=method build_template

    my $tmpl = $theme->build_template( $path, $content  )

Build a new L<Statocles::Template> object with the given C<path> and C<content>.

=cut

sub build_template {
    my ( $self, $path, $content ) = @_;

    return Statocles::Template->new(
        path => $path,
        content => $content,
        include_stores => [ @{ $self->include_stores }, $self->store ],
    );
}

=method template

    my $tmpl = $theme->template( $path )
    my $tmpl = $theme->template( @path_parts )

Get the L<template|Statocles::Template> at the given C<path>, or with the
given C<path_parts>.

=cut

sub template {
    my ( $self, @path ) = @_;
    my $path = Path::Tiny->new( @path );
    return $self->_templates->{ $path } ||= $self->read( $path );
}

1;
__END__

=head1 SYNOPSIS

    # Template directory layout
    /theme/site/layout.html.ep
    /theme/site/include/layout.html.ep
    /theme/blog/index.html.ep
    /theme/blog/post.html.ep

    my $theme      = Statocles::Theme->new( store => '/theme' );
    my $layout     = $theme->template( qw( site include layout.html ) );
    my $blog_index = $theme->template( blog => 'index.html' );
    my $blog_post  = $theme->template( 'blog/post.html' );

=head1 DESCRIPTION

A Theme contains all the L<templates|Statocles::Template> that
L<applications|Statocles::App> need. This class handles finding and parsing
files into L<template objects|Statocles::Template>.

When the L</store> is read, the templates inside are organized based on
their name and their parent directory.

=head1 SEE ALSO

=over 4

=item L<Statocles::Help::Theme>

=item L<Statocles::Template>

=back
