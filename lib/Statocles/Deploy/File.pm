package Statocles::Deploy::File;
our $VERSION = '0.085';
# ABSTRACT: Deploy a site to a folder on the filesystem

use Statocles::Base 'Class';
with 'Statocles::Deploy';

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

    my @paths = $deploy->deploy( $from_store, %options );

Deploy the site, copying from the given L<from_store|Statocles::Store>.
Returns the paths that were deployed.

Possible options are:

=over 4

=item clean

Remove all the current contents of the deploy directory before copying the
new content.

=back

=cut

sub deploy {
    my ( $self, $from_store, %options ) = @_;

    die sprintf 'Deploy directory "%s" does not exist (did you forget to make it?)',
        $self->path
            if !$self->path->is_dir;

    if ( $options{ clean } ) {
        $_->remove_tree for $self->path->children;
    }

    $self->site->log->info( "Copying files from build dir to deploy dir" );
    my @files;
    my $iter = $from_store->find_files( include_documents => 1 );
    while ( my $path = $iter->() ) {
        # Git versions before 1.7.4.1 require a relative path to 'git add'
        push @files, $path->relative( "/" )->stringify;
        $from_store->path->child( $path )->copy( $self->path->child( $path )->touchpath );
    }

    return @files;
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

