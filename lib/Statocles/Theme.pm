package Statocles::Theme;
# ABSTRACT: Templates, headers, footers, and navigation

use Statocles::Base 'Class';
use File::Share qw( dist_dir );
use Scalar::Util qw( blessed );

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

=attr _templates

The cached template objects for this theme.

=cut

has _templates => (
    is => 'ro',
    isa => HashRef[HashRef[InstanceOf['Statocles::Template']]],
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

=method read( $section => $name )

Read the template for the given C<section> and C<name> and create the
L<template|Statocles::Template> object.

=cut

sub read {
    my ( $self, $app, $template ) = @_;
    $template .= '.ep';
    my $path = Path::Tiny->new( $app, $template );

    my $content = eval { $self->store->read_file( $path ); };
    if ( $@ ) {
        if ( blessed $@ && $@->isa( 'Path::Tiny::Error' ) && $@->{op} =~ /^open/ ) {
            die sprintf 'ERROR: Template "%s/%s" does not exist in theme directory "%s"' . "\n",
                $app, $template, $self->store->path;
        }
        else {
            die $@;
        }
    }

    return $self->build_template( $path, $content );
}

=method build_template( $path, $content  )

Build a new L<Statocles::Template> object with the given C<path> and C<content>.

=cut

sub build_template {
    my ( $self, $path, $content ) = @_;

    return Statocles::Template->new(
        path => $path,
        content => $content,
        store => $self->store,
    );
}

=method template( $section => $name )

Get the L<template|Statocles::Template> from the given C<section> with the
given C<name>.

=cut

sub template {
    my ( $self, $app, $template ) = @_;
    return $self->_templates->{ $app }{ $template } ||= $self->read( $app, $template );
}

1;
__END__

=head1 SYNOPSIS

    # Template directory layout
    /theme/site/layout.html.ep
    /theme/blog/index.html.ep
    /theme/blog/post.html.ep

    my $theme      = Statocles::Theme->new( store => '/theme' );
    my $layout     = $theme->template( site => 'layout.html' );
    my $blog_index = $theme->template( blog => 'index.html' );
    my $blog_post  = $theme->template( blog => 'post.html' );

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
