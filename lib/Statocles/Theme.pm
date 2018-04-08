package Statocles::Theme;
our $VERSION = '0.094';
# ABSTRACT: Templates, headers, footers, and navigation

use Statocles::Base 'Class';
use File::Share qw( dist_dir );
use Scalar::Util qw( blessed );
use Statocles::Template;
with 'Statocles::Role::App::Store';

=attr url_root

The root URL for this application. Defaults to C</theme>.

=cut

has '+url_root' => ( default => sub { '/theme' } );

=attr store

The source L<store|Statocles::Store> for this theme.

If the path begins with ::, will pull one of the Statocles default
themes from the Statocles share directory.

=cut

=attr include_stores

An array of L<stores|Statocles::Store> to look for includes. The L</store> is
added at the end of this list.

=cut

has include_stores => (
    is => 'ro',
    isa => ArrayRef[StoreType],
    default => sub { [] },
    coerce => sub {
        my ( $thing ) = @_;
        if ( ref $thing eq 'ARRAY' ) {
            return [ map { StoreType->coercion->( $_ ) } @$thing ];
        }
        return [ StoreType->coercion->( $thing ) ];
    },
);

=attr _templates

The cached template objects for this theme.

=cut

has '+_templates' => (
    is => 'ro',
    isa => HashRef[InstanceOf['Statocles::Template']],
    default => sub { {} },
    lazy => 1,  # Must be lazy or the clearer won't re-init the default
    clearer => '_clear_templates',
);

=attr _includes

The cached template objects for the includes.

=cut

has _includes => (
    is => 'ro',
    isa => HashRef[InstanceOf['Statocles::Template']],
    default => sub { {} },
    lazy => 1,  # Must be lazy or the clearer won't re-init the default
    clearer => '_clear_includes',
);

# The helpers added to this theme.
has _helpers => (
    is => 'ro',
    isa => HashRef[CodeRef],
    default => sub { {} },
    init_arg => 'helpers', # Allow initialization via config file
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

    my $content = eval { $self->store->path->child( $path )->slurp_utf8; };
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
        theme => $self,
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

=method include

    my $tmpl = $theme->include( $path );
    my $tmpl = $theme->include( @path_parts );

Get the desired L<template|Statocles::Template> to include based on the given
C<path> or C<path_parts>. Looks through all the
L<include_stores|/include_stores> before looking in the L<main store|/store>.

=cut

sub include {
    my ( $self, @path ) = @_;
    my $render = 1;
    if ( $path[0] eq '-raw' ) {
        # Allow raw files to not be passed through the template renderer
        # This override flag will always exist, but in the future we may
        # add better detection to possible file types to process
        $render = 0;
        shift @path;
    }
    my $path = Path::Tiny->new( @path );

    my @stores = ( @{ $self->include_stores }, $self->store );
    for my $store ( @stores ) {
        if ( $store->has_file( $path ) ) {
            if ( $render ) {
                return $self->_includes->{ $path } ||= $self->build_template(
                    $path, $store->path->child( $path )->slurp_utf8,
                );
            }
            return $store->path->child( $path )->slurp_utf8;
        }
    }

    die qq{Can not find include "$path" in include directories: }
        . join( ", ", map { sprintf q{"%s"}, $_->path } @stores )
        . "\n";
}

=method helper

    $theme->helper( $name, $sub );

Register a helper on this theme. Helpers are functions that are added to
the template to allow for additional features. Helpers are usually added
by L<Statocles plugins|Statocles::Role::Plugin>.

There are a L<default set of helpers available to all
templates|Statocles::Template/DEFAULT HELPERS> which cannot be
overridden by this method.

=cut

sub helper {
    my ( $self, $name, $sub ) = @_;
    $self->_helpers->{ $name } = $sub;
    return;
}

=method clear

    $theme->clear;

Clear out the cached templates and includes. Used by the daemon when it
detects a change to the theme files.

=cut

sub clear {
    my ( $self ) = @_;
    $self->_clear_templates;
    $self->_clear_includes;
    return;
}

=method pages

Get the extra, non-template files to deploy with the rest of the site, like CSS,
JavaScript, and images.

Templates, files that end in C<.ep>, will not be deployed with the rest of the
site.

=cut

around pages => sub {
    my ( $orig, $self, %args ) = @_;
    my @pages = $self->$orig( %args );
    return grep { $_->path !~ /[.]ep$/ } @pages;
};

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

    # Clear out cached templates and includes
    $theme->clear;

=head1 DESCRIPTION

A Theme contains all the L<templates|Statocles::Template> that
L<applications|Statocles::Role::App> need. This class handles finding and parsing
files into L<template objects|Statocles::Template>.

When the L</store> is read, the templates inside are organized based on
their name and their parent directory.

=head1 SEE ALSO

=over 4

=item L<Statocles::Help::Theme>

=item L<Statocles::Template>

=back
