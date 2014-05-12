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
    default => '',
);

=attr build_store

The Statocles::Store object to use for C<build()>.

=cut

has build_store => (
    is => 'ro',
    isa => InstanceOf['Statocles::Store'],
    required => 1,
);

=attr deploy_store

The Statocles::Store object to use for C<deploy()>. Defaults to L<build_store>.

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

Write the application to the given C<store>, a Statocles::Store object

=cut

sub write {
    my ( $self, $store ) = @_;
    my $apps = $self->apps;
    my %args = (
        site => {
            title => $self->title,
        },
    );
    for my $app_name ( keys %{ $apps } ) {
        my $app = $apps->{$app_name};
        for my $page ( $app->pages ) {
            if ( $self->index eq $app_name && $page->path eq $app->index->path ) {
                # Rename the app's page so that we don't get two pages with identical
                # content
                $page = Statocles::Page::List->new(
                    %{ $page },
                    path => '/index.html',
                );
            }
            $store->write_page( $page->path, $page->render( %args ) );
        }
    }
}

1;
__END__

=head1 SYNOPSIS

    my $site = Statocles::Site->new(
        apps => {
            blog => Statocles::App::Blog->new( ... ),
        },
    );

    $site->deploy;

=head1 DESCRIPTION

A Statocles::Site is a collection of applications.

