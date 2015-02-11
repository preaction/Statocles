package Statocles::Page::File;
# ABSTRACT: A page wrapping a file (handle)

use Statocles::Base 'Class';
with 'Statocles::Page';

=attr fh

The file handle containing the contents of the page. Required.

=cut

has fh => (
    is => 'ro',
    isa => FileHandle,
    required => 1,
);

=method vars

Dies. This page has no templates and no template variables.

=cut

# XXX: This may have to be implemented in the future, to allow for some useful edge
# cases.
sub vars { die "Unimplemented" }

=method render

Return

=cut

sub render {
    my ( $self ) = @_;
    return $self->fh;
}

1;
__END__

=head1 SYNOPSIS

    open my $fh, '<', '/path/to/file.txt';

    my $page = Statocles::Page::File->new(
        path => '/path/to/page.txt',
        fh => $fh,
    );

=head1 DESCRIPTION

This L<Statocles::Page> wraps a file handle in order to move files from one
L<store|Statocles::Store> to another.
