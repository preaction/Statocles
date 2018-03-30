package Statocles::Deploy::File;
our $VERSION = '0.094';
# ABSTRACT: Deploy a site to a folder on the filesystem

use Statocles::Base 'Class';
with 'Statocles::Deploy';
use Statocles::Util qw( dircopy );

=attr path

The path to deploy to.

=cut

has path => (
    is => 'ro',
    isa => Path,
    coerce => Path->coercion,
    default => sub { Path::Tiny->new( '.' ) },
);

=method deploy

    my @paths = $deploy->deploy( $source_path, %options );

Deploy the site, copying from the given source path.

Possible options are:

=over 4

=item clean

Remove all the current contents of the deploy directory before copying the
new content.

=back

=cut

sub deploy {
    my ( $self, $source_path, %options ) = @_;

    die sprintf 'Deploy directory "%s" does not exist (did you forget to make it?)',
        $self->path
            if !$self->path->is_dir;

    if ( $options{ clean } ) {
        $_->remove_tree for $self->path->children;
    }

    my $src = Path->coercion->( $source_path );
    dircopy $src, $self->path;
}

1;
__END__

=head1 DESCRIPTION

This class allows a site to be deployed to a folder on the filesystem.

This class consumes L<Statocles::Deploy|Statocles::Deploy>.

=head1 SEE ALSO

=over 4

=item L<Statocles::Deploy>

=back

