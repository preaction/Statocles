package Statocles::Page::Raw;

use Statocles::Class;
with 'Statocles::Page';

=attr content

The content of the page, already rendered to HTML.

=cut

has content => (
    is => 'ro',
    isa => Str,
    required => 1,
);

=attr last_modified

The last modified time of the page.

=cut

has last_modified => (
    is => 'ro',
    isa => InstanceOf['Time::Piece'],
);

=method vars

Get the template variables for this page.

=cut

sub vars {
    my ( $self ) = @_;
    return (
        content => $self->content,
    );
}

1;
__END__

=head1 SYNOPSIS

    my $page = Statocles::Page::Raw->new(
        path => '/path/to/page.html',
        content => '...',
    );

    my $js = Statocles::Page::Raw->new(
        path => '/js/app.js',
        content => '...',
    );

=head1 DESCRIPTION

This L<Statocles::Page> contains any content you want to put in it. This is useful
when you generate HTML (or anything else) outside of Statocles.
