package Statocles::App;
# ABSTRACT: Base role for Statocles applications

use Statocles::Base 'Role';
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

=method pages()

Get the pages for this app. Must return a list of L<Statocles::Page> objects, with
the index page (the page intended to be the entry page) first.

=cut

around pages => sub {
    my ( $orig, $self, @args ) = @_;
    my @pages = $self->$orig( @args );

    # Add the url_root
    my $url_root = $self->url_root;
    for my $page ( @pages ) {
        next if $page->path =~ /^$url_root/;
        $page->path( join "/", $url_root, $page->path );
    }

    return @pages;
};

=method url( $url )

Get a URL to a page in this application. Prepends the L</url_root> if necessary. Strips
"index.html" if possible.

=cut

sub url {
    my ( $self, $url ) = @_;
    $url =~ s{/index[.]html$}{};
    return join "/", $self->url_root, $url;
}

=method link( %args )

Create a link to a page in this application. C<%args> are attributes to be given to
L<Statocles::Link> constructor.

=cut

sub link {
    my ( $self, %args ) = @_;
    my $url_root = $self->url_root;
    if ( $args{href} !~ /^$url_root/ ) {
        $args{href} = $self->url( $args{href} );
    }
    return Statocles::Link->new( %args );
}

1;
__END__

=head1 DESCRIPTION

A Statocles App turns L<documents|Statocles::Documents> into a set of
L<pages|Statocles::Pages> that can then be written to the filesystem (or served
directly, if desired).
