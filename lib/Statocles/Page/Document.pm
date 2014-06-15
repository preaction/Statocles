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

=attr template

The L<template|Statocles::Template> to render the
L<document|Statocles::Document>.

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

=method vars

Get the template variables for this page.

=cut

sub vars {
    my ( $self ) = @_;
    return (
        content => $self->content,
        self => $self,
        doc => $self->document,
        app => $self->app,
    );
}

1;
__END__

=head1 DESCRIPTION

This page class takes a single L<document|Statocles::Document> and renders it as HTML.
