package Statocles::Page::Document;
# ABSTRACT: Render documents into HTML

use Statocles::Class;
with 'Statocles::Page';
use Text::Markdown;
use Text::Template;

=attr document

The document this page will render.

=cut

has document => (
    is => 'ro',
    isa => InstanceOf['Statocles::Document'],
);

=attr template

The template to render the document.

=cut

has '+template' => (
    default => sub {
        Text::Template->new( TYPE => 'STRING', SOURCE => '{$content}' );
    },
);

=method content

Generate the document HTML by converting Markdown.

=cut

sub content {
    my ( $self ) = @_;
    return $self->markdown->markdown( $self->document->content );
}

=method render

Render the page, using the C<template> and wrapping with the C<layout>.

=cut

sub render {
    my ( $self, %args ) = @_;
    my $content = $self->template->fill_in( HASH => {
        %args,
        %{$self->document},
        content => $self->content,
    } ) || die "Could not fill in template: $Text::Template::ERROR";
    return $self->layout->fill_in( HASH => {
        %args,
        content => $content,
    } ) || die "Could not fill in layout: $Text::Template::ERROR";
}

1;
__END__

=head1 DESCRIPTION

This page class takes a single document and renders it as HTML.
