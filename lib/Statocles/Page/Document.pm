package Statocles::Page::Document;
# ABSTRACT: Render documents into HTML

use Statocles::Class;
with 'Statocles::Page';
use Text::Markdown;
use Statocles::Template;

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
        Statocles::Template->new( content => '<%= $content %>' );
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
    my $content = $self->template->render(
        %args,
        %{$self->document},
        content => $self->content,
        path => $self->path,
    );
    return $self->layout->render(
        %args,
        content => $content,
        path => $self->path,
    );
}

1;
__END__

=head1 DESCRIPTION

This page class takes a single document and renders it as HTML.
