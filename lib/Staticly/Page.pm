package Staticly::Page;

use Staticly::Class;
use Text::Markdown;
use Text::Template;

has document => (
    is => 'ro',
    isa => InstanceOf['Staticly::Document'],
);

has markdown => (
    is => 'ro',
    isa => InstanceOf['Text::Markdown'],
    default => sub { Text::Markdown->new },
);

has template => (
    is => 'ro',
    isa => InstanceOf['Text::Template'],
    default => sub {
        Text::Template->new( TYPE => 'STRING', SOURCE => '{$content}' );
    },
    coerce => sub {
        return !ref $_[0] 
            ? Text::Template->new( TYPE => 'STRING', SOURCE => $_[0] )
            : $_[0]
            ;
    },
);

sub content {
    my ( $self ) = @_;
    return $self->markdown->markdown( $self->document->content );
}

sub render {
    my ( $self ) = @_;
    return $self->template->fill_in( HASH => {
        %{$self->document},
        content => $self->content,
    } );
}

1;
