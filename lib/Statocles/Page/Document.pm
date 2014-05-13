package Statocles::Page::Document;
# ABSTRACT: Render documents into HTML

use Statocles::Class;
with 'Statocles::Page';
use Text::Markdown;
use Text::Template;

has document => (
    is => 'ro',
    isa => InstanceOf['Statocles::Document'],
);

has '+template' => (
    default => sub {
        Text::Template->new( TYPE => 'STRING', SOURCE => '{$content}' );
    },
);

sub content {
    my ( $self ) = @_;
    return $self->markdown->markdown( $self->document->content );
}

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
