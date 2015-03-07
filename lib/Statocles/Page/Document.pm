package Statocles::Page::Document;
# ABSTRACT: Render documents into HTML

use Statocles::Base 'Class';
with 'Statocles::Page';
use Text::Markdown;
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

=method content( vars )

Generate the document HTML by processing template directives and converting
Markdown. C<vars> is a set of name-value pairs to give to the template.

=cut

sub content {
    my ( $self, %vars ) = @_;
    my $content = $self->document->content;
    my $tmpl = $self->site->theme->build_template( $self->path, $content );
    my $rendered = $tmpl->render( %vars, $self->vars );
    return $self->markdown->markdown( $rendered );
}

=method vars

Get the template variables for this page.

=cut

sub vars {
    my ( $self ) = @_;
    return (
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

=method tags()

Get the list of tags for this page.

=cut

sub tags {
    my ( $self ) = @_;
    return @{ $self->_tags };
}

1;
__END__

=head1 DESCRIPTION

This page class takes a single L<document|Statocles::Document> and renders it as HTML.
