package Statocles::Site;
# ABSTRACT: An entire, configured website

use Statocles::Class;

=attr title

The site title, used in templates.

=cut

has title => (
    is => 'ro',
    isa => Str,
);

=attr base_url

The base URL of the site, including protocol and domain. Used mostly for feeds.

=cut

has base_url => (
    is => 'ro',
    isa => Str,
);

=attr apps

The applications in this site. Each application has a name
that can be used later.

=cut

has apps => (
    is => 'ro',
    isa => HashRef[InstanceOf['Statocles::App']],
);

=attr index

The application to use as the site index. The application's individual index()
method will be called to get the index page.

=cut

has index => (
    is => 'ro',
    isa => Str,
    default => sub { '' },
);

=attr nav

Named navigation lists. A hash of arrays of hashes with the following keys:

    title - The title of the link
    href - The href of the link

The most likely name for your navigation will be C<main>. Navigation names
are defined by your L<theme|Statocles::Theme>. For example:

    {
        main => [
            {
                title => 'Blog',
                href => '/blog/index.html',
            },
            {
                title => 'Contact',
                href => '/contact.html',
            },
        ],
    }

=cut

has nav => (
    is => 'ro',
    isa => HashRef[ArrayRef[HashRef[Str]]],
    default => sub { {} },
);

=attr build_store

The L<store|Statocles::Store> object to use for C<build()>.

=cut

has build_store => (
    is => 'ro',
    isa => InstanceOf['Statocles::Store'],
    required => 1,
);

=attr deploy_store

The L<store|Statocles::Store> object to use for C<deploy()>. Defaults to L<build_store>.

=cut

has deploy_store => (
    is => 'ro',
    isa => InstanceOf['Statocles::Store'],
    lazy => 1,
    default => sub { $_[0]->build_store },
);

=method app( name )

Get the app with the given C<name>.

=cut

sub app {
    my ( $self, $name ) = @_;
    return $self->apps->{ $name };
}

=method build

Build the site in its build location

=cut

sub build {
    my ( $self ) = @_;
    $self->write( $self->build_store );
}

=method deploy

Write each application to its destination.

=cut

sub deploy {
    my ( $self ) = @_;
    $self->write( $self->deploy_store );
}

=method write( store )

Write the application to the given L<store|Statocles::Store>.

=cut

sub write {
    my ( $self, $store ) = @_;
    my $apps = $self->apps;
    my %args = (
        site => $self,
    );
    for my $app_name ( keys %{ $apps } ) {
        my $app = $apps->{$app_name};

        my $index_path;
        if ( $self->index eq $app_name ) {
            $index_path = ($app->index)[0]->path;
        }

        for my $page ( $app->pages ) {
            if ( $index_path && $page->path eq $index_path ) {
                # Rename the app's page so that we don't get two pages with identical
                # content
                $page->path( '/index.html' );
            }
            $store->write_page( $page->path, $page->render( %args ) );
        }
    }
}

=method url( path )

Get the full URL to the given path by prepending the C<base_url>.

=cut

sub url {
    my ( $self, $path ) = @_;
    my $base = $self->base_url;
    $base =~ s{/$}{};
    $path =~ s{^/}{};
    return join "/", $base, $path;
}

1;
__END__

=head1 SYNOPSIS

    my $site = Statocles::Site->new(
        title => 'My Site',
        nav => [
            { title => 'Home', href => '/' },
            { title => 'Blog', href => '/blog' },
        ],
        apps => {
            blog => Statocles::App::Blog->new( ... ),
        },
    );

    $site->deploy;

=head1 DESCRIPTION

A Statocles::Site is a collection of L<applications|Statocles::App>.

