package Statocles::Page::Document;
# ABSTRACT: Render documents into HTML

use Statocles::Class;
with 'Statocles::Page';
use Text::Markdown;
use Statocles::Template;

=attr published

The publish date/time of this page. A L<Time::Piece> object.

=cut

has published => (
    is => 'ro',
    isa => InstanceOf['Time::Piece'],
);

=attr document

The L<document|Statocles::Document> this page will render.

=cut

has document => (
    is => 'ro',
    isa => InstanceOf['Statocles::Document'],
);

=attr tags

The tag links for this document. An array of link hashes with the following
keys:

    title   - The title of the link
    href    - The page of the link

=cut

has tags => (
    is => 'ro',
    isa => ArrayRef[HashRef],
    default => sub { [] },
);

=method content

Generate the document HTML by converting Markdown.

=cut

sub content {
    my ( $self ) = @_;
    return $self->markdown->markdown( $self->document->content );
}

=method vars

Get the template variables for this page.

=cut

sub vars {
    my ( $self ) = @_;
    return (
        content => $self->content,
        doc => $self->document,
    );
}

=method sections

Get a list of content divided into sections. The Markdown "---" marker divides
sections.

=cut

sub sections {
    my ( $self ) = @_;
    my @sections = split /\n---\n/, $self->document->content;
    return map { $self->markdown->markdown( $_ ) } @sections;
}

1;
__END__

=head1 DESCRIPTION

This page class takes a single L<document|Statocles::Document> and renders it as HTML.
