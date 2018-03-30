package Statocles::Page::Document;
our $VERSION = '0.094';
# ABSTRACT: Render document objects into HTML

use Statocles::Base 'Class';
with 'Statocles::Page';
use Statocles::Template;
use Statocles::Store;

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

has '+title' => (
    lazy => 1,
    default => sub { $_[0]->document->title || '' },
);

=attr author

The author of the page.

=cut

around _build_author => sub {
    my ( $orig, $self ) = @_;
    return $self->document->author || $self->$orig;
};

=attr date

Get the date of this page by checking the document.

=cut

has '+date' => (
    lazy => 1,
    default => sub {
        my ( $self ) = @_;
        $self->document->date || DateTime::Moonpig->now( time_zone => 'local' );
    },
);

=attr tags

The tag links for this document. An array of L<link objects|Statocles::Link>. The
most important attributes are:

    text    - The text of the link
    href    - The page of the link

=cut

has _tags => (
    is => 'rw',
    isa => LinkArray,
    default => sub { [] },
    coerce => LinkArray->coercion,
    init_arg => 'tags',
);

sub links {
    shift->document->links( @_ );
}

sub images {
    shift->document->images( @_ );
}

=attr data

The C<data> hash for this page. Defaults to the C<data> attribute from the Document.

=cut

has '+data' => (
    lazy => 1,
    default => sub {
        my ( $self ) = @_;
        # Only allow hashref data attributes to come through.
        # Non-hashref data attributes are deprecated and will be removed
        # in v2.0. When that happens, remove this check as well
        my $data = $self->document->data;
        if ( $data && ref $data eq 'HASH' ) {
            return $data;
        }
        return {};
    },
);

=attr disable_content_template

If true, disables the processing of the content as a template. This will
improve performance if you're not using any template directives in your content.

This can be set in the document (L<Statocles::Document/disable_content_template>),
the application (L<Statocles::App/disable_content_template>), or the site
(L<Statocles::Site/disable_content_template>).

=cut

has disable_content_template => (
    is => 'ro',
    isa => Str,
    lazy => 1,
    default => sub {
        my ( $self ) = @_;
        return $self->document && $self->document->has_disable_content_template ? $self->document->disable_content_template && "document"
            : $self->app && $self->app->has_disable_content_template ? $self->app->disable_content_template && "application"
            : $self->site && $self->site->has_disable_content_template ? $self->site->disable_content_template && "site"
            : "";
    },
);

sub _render_content_template {
    my ( $self, $content, $vars ) = @_;
    if ( my $by = $self->disable_content_template ) {
        $self->site->log->debug( $self->path . ' content template processing disabled by ' . $by );
        return $content;
    }
    $self->site->log->debug( $self->path . ' processing content template ' );
    my $tmpl = $self->site->theme->build_template( $self->path, $content );
    my $doc = $self->document;
    if ( $doc->store ) {
        my $document_path = $doc->store->path->child( $doc->path )->parent;
        push @{ $tmpl->include_stores }, Statocles::Store->new( path => $document_path );
    }
    my $rendered = $tmpl->render( %$vars, $self->vars, self => $doc, page => $self );
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

around vars => sub {
    my ( $orig, $self ) = @_;
    return (
        $self->$orig,
        doc => $self->document,
    );
};

=method sections

    my @sections = $page->sections;
    my $number_of_sections = $page->sections;
    my @first_sections = $page->sections( 0, 1 );

Get a list of rendered HTML content divided into sections. The Markdown "---"
marker divides sections. In scalar context, returns the number of sections.
You can also pass the indexes of the sections you want as arguments.

For example, to loop over sections in the template:

    % for my $i ( 0..$page->sections ) {
        <%= $page->sections( $i ) %>
    % }

=cut

has _rendered_sections => (
    is => 'rw',
    isa => ArrayRef,
    predicate => '_has_rendered_sections',
);

sub sections {
    my ( $self, @indexes ) = @_;

    my @sections;
    if ( $self->_has_rendered_sections ) {
        @sections = @{ $self->_rendered_sections };
    }
    else {
        @sections =
            map { $self->markdown->markdown( $_ ) }
            map { $self->_render_content_template( $_, {} ) }
            split /\n---\n/,
            $self->document->content;

        $self->_rendered_sections( \@sections );
    }

    return @indexes ? @sections[ @indexes ] : @sections;
}

=method tags

    my @tags = $page->tags;

Get the list of tags for this page.

=cut

sub tags {
    my ( $self, $new_tags ) = @_;
    if ( $new_tags ) {
        return $self->_tags( $new_tags );
    }
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

=attr next

The path to the next document if it is part of a list.
Defaults to the L<Statocles::Document/path> from L</next_page> if it exists.

=cut

has next => (
    is => 'rw',
    lazy => 1,
    isa => PagePath|Undef,
    coerce => PagePath->coercion,
    default => sub { $_[0]->_page_path('next_page') },
);

=attr prev

The path to the previous document if it is part of a list.
Defaults to the L<Statocles::Document/path> from L</prev_page> if it exists.

=cut

has prev => (
    is => 'rw',
    lazy => 1,
    isa => PagePath|Undef,
    coerce => PagePath->coercion,
    default => sub { $_[0]->_page_path('prev_page') },
);

sub _page_path {
  my ( $self, $method ) = @_;
  if ( my $page = $self->$method() ) {
    return $page->path;
  }
  return undef;
}

=attr next_page

The L<Statocles::Page::Document> instance of the next document if it is part of a list.

=attr prev_page

The L<Statocles::Page::Document> instance of the previous document if it is part of a list.

=cut

has [qw( next_page prev_page )] => (
    is => 'rw',
    isa => InstanceOf['Statocles::Page::Document'],
);

1;
__END__

=head1 DESCRIPTION

This page class takes a single L<document|Statocles::Document> and renders it as HTML.
