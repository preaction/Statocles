package Statocles::Deploy::File;
our $VERSION = '0.093';
# ABSTRACT: Deploy a site to a folder on the filesystem

use Statocles::Base 'Class';
with 'Statocles::Deploy';
use Statocles::Store;

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

    my @paths = $deploy->deploy( $pages, %options );

Deploy the site, rendering the given pages.

Possible options are:

=over 4

=item clean

Remove all the current contents of the deploy directory before copying the
new content.

=back

=cut

sub deploy {
    my ( $self, $pages, %options ) = @_;

    die sprintf 'Deploy directory "%s" does not exist (did you forget to make it?)',
        $self->path
            if !$self->path->is_dir;

    if ( $options{ clean } ) {
        $_->remove_tree for $self->path->children;
    }

    my $store = Statocles::Store->new( path => $self->path );
    $self->site->log->info( "Writing pages to deploy dir" );
    for my $page ( @$pages ) {
        my $path = $page->path;
        #; say "Path: " . $path;
        #; say "To: " . $self->path->child( $path );
        $store->write_file( $page->path, $page->has_dom ? $page->dom : $page->render );
    }
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

