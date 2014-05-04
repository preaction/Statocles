package Statocles::Site;
# ABSTRACT: An entire, configured website

use Statocles::Class;

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
);

=attr destination

The destination of the index page.

=cut

has destination => (
    is => 'ro',
    isa => InstanceOf['Statocles::Store'],
);

=method app( name )

Get the app with the given C<name>.

=cut

sub app {
    my ( $self, $name ) = @_;
    return $self->apps->{ $name };
}

=method deploy

Write each application to its destination.

=cut

sub deploy {
    my ( $self ) = @_;
    for my $app ( values %{ $self->apps } ) {
        $app->write();
    }
    if ( $self->index ) {
        my $index = Statocles::Page::List->new(
            %{ $self->app( $self->index )->index },
            path => '/index.html',
        );
        $self->destination->write_page( $index );
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

