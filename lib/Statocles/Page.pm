package Statocles::Page;

use Statocles::Class;
use File::Spec::Functions qw( catfile );
use File::Slurp qw( write_file );
use Text::Markdown;
use Text::Template;

has document => (
    is => 'ro',
    isa => InstanceOf['Statocles::Document'],
);

has path => (
    is => 'ro',
    isa => Str,
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

sub write {
    my ( $self, $root ) = @_;
    my $path = catfile( $root, $self->path );
    write_file( $path, $self->render );
    return;
}

1;
