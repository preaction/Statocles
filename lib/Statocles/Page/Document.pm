package Statocles::Page::Document;
# ABSTRACT: Render documents into HTML

use Statocles::Base 'Class';
with 'Statocles::Page';
use Statocles::Template;

=attr document

The L<document|Statocles::Document> this page will render.

=cut

has document => (
    is => 'ro',
    isa => InstanceOf['Statocles::Document'],
    required => 1,
);

=attr title

The title of the page.

=cut

has title => (
    is => 'ro',
    isa => Str,
    lazy => 1,
    default => sub { $_[0]->document->title },
);

=attr author

The author of the page.

=cut

has author => (
    is => 'ro',
    isa => Str,
    lazy => 1,
    default => sub { $_[0]->document->author || '' },
);

=attr date

Get the date of this page by checking the document.

=cut

has '+date' => (
    lazy => 1,
    default => sub {
        my ( $self ) = @_;
        $self->document->date || Time::Piece->new;
    },
);

=attr tags

The tag links for this document. An array of L<link objects|Statocles::Link>. The
most important attributes are:

    text    - The text of the link
    href    - The page of the link

=cut

has _tags => (
    is => 'ro',
    isa => LinkArray,
    default => sub { [] },
    coerce => LinkArray->coercion,
    init_arg => 'tags',
);

has '+_links' => (
    default => sub { $_[0]->document->links },
);

sub _render_content_template {
    my ( $self, $content, $vars ) = @_;
    my $tmpl = $self->site->theme->build_template( $self->path, $content );
    my $rendered = $tmpl->render( %$vars, $self->vars, self => $self->document );
    return $rendered;
}

=method content

    my $html = $page->content( %vars );

Generate the document HTML by processing template directives and converting
Markdown. C<vars> is a set of name-value pairs to give to the template.

=cut

sub content {
    my ( $self, %vars ) = @_;
    my $content = $self->document->content;
    my $rendered = $self->_render_content_template( $content, \%vars );
    return $self->markdown->markdown( $rendered );
}

=method vars

    my %vars = $page->vars;

Get the template variables for this page.

=cut

sub vars {
    my ( $self ) = @_;
    return (
        doc => $self->document,
    );
}

=method sections

    my @sections = $page->sections;

Get a list of rendered HTML content divided into sections. The Markdown "---"
marker divides sections.

=cut

sub sections {
    my ( $self ) = @_;
    my @sections = split /\n---\n/, $self->document->content;
    return
        map { $self->markdown->markdown( $_ ) }
        map { $self->_render_content_template( $_, {} ) }
        @sections;
}

=method tags

    my @tags = $page->tags;

Get the list of tags for this page.

=cut

sub tags {
    my ( $self ) = @_;
    return @{ $self->_tags };
}

=method template

    my $tmpl = $page->template;

The L<template object|Statocles::Template> for this page. If the document has a template,
it will be used. Otherwise, the L<template attribute|Statocles::Page/template> will
be used.

=cut

around template => sub {
    my ( $orig, $self, @args ) = @_;
    if ( $self->document->has_template ) {
        return $self->site->theme->template( @{ $self->document->template } );
    }
    return $self->$orig( @args );
};

=method layout

    my $tmpl = $page->layout;

The L<layout template object|Statocles::Template> for this page. If the document has a layout,
it will be used. Otherwise, the L<layout attribute|Statocles::Page/layout> will
be used.

=cut

around layout => sub {
    my ( $orig, $self, @args ) = @_;
    if ( $self->document->has_layout ) {
        return $self->site->theme->template( @{ $self->document->layout } );
    }
    return $self->$orig( @args );
};

1;
__END__

=head1 DESCRIPTION

This page class takes a single L<document|Statocles::Document> and renders it as HTML.
