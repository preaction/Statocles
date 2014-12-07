package Statocles::Page::Plain;
# ABSTRACT: A plain page (with templates)

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
    default => sub { Time::Piece->new },
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

    my $page = Statocles::Page::Plain->new(
        path => '/path/to/page.html',
        content => '...',
    );

    my $js = Statocles::Page::Plain->new(
        path => '/js/app.js',
        content => '...',
    );

=head1 DESCRIPTION

This L<Statocles::Page> contains any content you want to put in it, while still
allowing for templates and layout. This is useful when you generate HTML (or
anything else) outside of Statocles.
