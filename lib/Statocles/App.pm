package Statocles::App;
our $VERSION = '0.085';
# ABSTRACT: Base role for Statocles applications

use Statocles::Base 'Role', 'Emitter';
use Statocles::Link;
requires 'pages';

=attr site

The site this app is part of.

=cut

has site => (
    is => 'rw',
    isa => InstanceOf['Statocles::Site'],
);

=attr data

A hash of arbitrary data available to theme templates. This is a good place to
put extra structured data like social network links or make easy customizations
to themes like header image URLs.

=cut

has data => (
    is => 'ro',
    isa => HashRef,
    default => sub { {} },
);

=attr url_root

The URL root of this application. All pages from this app will be under this
root. Use this to ensure two apps do not try to write the same path.

=cut

has url_root => (
    is => 'ro',
    isa => Str,
    required => 1,
);

=attr templates

The templates to use for this application. A mapping of template names to
template paths (relative to the theme root directory).

Developers should get application templates using L<the C<template>
method|/template>.

=cut

has _templates => (
    is => 'ro',
    isa => HashRef,
    default => sub { {} },
    init_arg => 'templates',
);

=attr template_dir

The directory (inside the theme directory) to use for this app's templates.

=cut

has template_dir => (
    is => 'ro',
    isa => Str,
);

=method pages

    my @pages = $app->pages;

Get the pages for this app. Must return a list of L<Statocles::Page> objects.

=cut

around pages => sub {
    my ( $orig, $self, @args ) = @_;
    my @pages = $self->$orig( @args );

    # Add the url_root
    my $url_root = $self->url_root;
    for my $page ( @pages ) {
        my @url_attrs = qw( path );

        if ( $page->isa( 'Statocles::Page::List' ) ) {
            push @url_attrs, qw( next prev );
        }

        for my $attr ( @url_attrs ) {
            if ( $page->$attr && $page->$attr !~ /^$url_root/ ) {
                $page->$attr( join "/", $url_root, $page->$attr );
            }
        }
    }

    $self->emit( 'build' => class => 'Statocles::Event::Pages', pages => \@pages );

    return @pages;
};

=method url

    my $app_url = $app->url( $path );

Get a URL to a page in this application. Prepends the app's L<url_root
attribute|/url_root> if necessary. Strips "index.html" if possible.

=cut

sub url {
    my ( $self, $url ) = @_;
    my $base = $self->url_root;
    $url =~ s{/index[.]html$}{/};

    # Remove the / from both sides of the join so we don't double up
    $base =~ s{/$}{};
    $url =~ s{^/}{};

    return join "/", $base, $url;
}

=method link

    my $link = $app->link( %args )

Create a link to a page in this application. C<%args> are attributes to be
given to L<Statocles::Link> constructor. The app's L<url_root
attribute|/url_root> is prepended, if necessary.

=cut

sub link {
    my ( $self, %args ) = @_;
    my $url_root = $self->url_root;
    if ( $args{href} !~ /^$url_root/ ) {
        $args{href} = $self->url( $args{href} );
    }
    return Statocles::Link->new( %args );
}

=method template

    my $template = $app->template( $tmpl_name );

Get a L<template object|Statocles::Template> for the given template
name. The default template is determined by the app's class name and the
template name passed in.

Applications should list the templates they have and describe what L<page
class|Statocles::Page> they use.

=cut

sub template {
    my ( $self, $name ) = @_;

    # Allow the site object to set the default layout
    if ( $name eq 'layout.html' && !$self->_templates->{ $name } ) {
        return $self->site->template( $name );
    }

    my $path    = $self->_templates->{ $name }
                ? $self->_templates->{ $name }
                : join "/", $self->template_dir, $name;

    return $self->site->theme->template( $path );
}

1;
__END__

=head1 SYNOPSIS

    package MyApp;
    use Statocles::Base 'Class';
    with 'Statocles::App';

    sub pages {
        return Statocles::Page::Content->new(
            path => '/index.html',
            content => 'Hello, World',
        );
    }

=head1 DESCRIPTION

A Statocles App creates a set of L<pages|Statocles::Pages> that can then be
written to the filesystem (or served directly, if desired).

Pages can be created from L<documents|Statocles::Documents> stored in a
L<store|Statocles::Store> (see L<Statocles::Page::Document>), files stored in a
store (see L<Statocles::Page::File>), lists of content (see
L<Statocles::Page::List>), or anything at all (see
L<Statocles::Page::Content>).

=head1 EVENTS

All apps by default expose the following events:

=head2 build

This event is fired after the app pages have been prepares and are ready to
be rendered. This event allows for modifying the pages before they are rendered.

The event will be a
L<Statocles::Event::Pages|Statocles::Event/Statocles::Event::Pages> object
containing all the pages prepared by the app.

=head1 INCLUDED APPS

These applications are included with the core Statocles distribution.

=over 4

=item L<Statocles::App::Blog>

=item L<Statocles::App::Basic>

=item L<Statocles::App::Static>

=item L<Statocles::App::Perldoc>

=back

=head1 SEE ALSO

=over 4

=item L<Statocles::Store>

=item L<Statocles::Page>

=back

