package Statocles::Page::Plain;
our $VERSION = '0.098';
# ABSTRACT: A plain page (with templates)

use Statocles::Base 'Class';
with 'Statocles::Page';

=attr content

The content of the page, already rendered to HTML.

=cut

has _content => (
    is => 'ro',
    isa => Str,
    required => 1,
    init_arg => 'content',
);

=method content

    my $html = $page->content;

Get the content for this page.

=cut

sub content {
    return $_[0]->_content;
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
