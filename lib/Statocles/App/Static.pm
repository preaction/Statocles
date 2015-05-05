package Statocles::App::Static;
# ABSTRACT: Manage static files like CSS, JS, images, and other untemplated content

use Statocles::Base 'Class';
use Statocles::Page::File;
with 'Statocles::App';

=attr store

The L<store|Statocles::Store> containing this app's files. Required.

=cut

has store => (
    is => 'ro',
    isa => Store,
    required => 1,
    coerce => Store->coercion,
);

=method pages

Get the L<pages|Statocles::Page> for this app.

=cut

sub pages {
    my ( $self ) = @_;

    my @pages;
    my $iter = $self->store->find_files;
    FILE: while ( my $path = $iter->() ) {
        # Check for hidden files and folders
        next if $path->basename =~ /^[.]/;
        my $parent = $path->parent;
        while ( !$parent->is_rootdir ) {
            next FILE if $parent->basename =~ /^[.]/;
            $parent = $parent->parent;
        }

        push @pages, Statocles::Page::File->new(
            path => $path,
            file_path => $self->store->path->child( $path ),
        );
    }

    return @pages;
}

1;
__END__

=head1 DESCRIPTION

This L<Statocles::App|Statocles::App> manages static content with no processing,
perfect for images, stylesheets, scripts, or already-built HTML.
