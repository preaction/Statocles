package Statocles::Page;
# ABSTRACT: Render documents into HTML

use Statocles::Class;
use File::Spec::Functions qw( catfile );
use File::Basename qw( dirname );
use File::Path qw( make_path );
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

has [qw( template layout )] => (
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
    my $content = $self->template->fill_in( HASH => {
        %{$self->document},
        content => $self->content,
    } );
    return $self->layout->fill_in( HASH => {
        content => $content,
    } );
}

sub write {
    my ( $self, $root ) = @_;
    my $path = catfile( $root, $self->path );
    my $dir = dirname( $path );
    make_path( $dir, { error => \(my $errors) } );
    if ( @$errors ) {
        die "Could not make directory '$dir': @$errors";
    }
    write_file( $path, $self->render );
    return;
}

1;
__END__

=head1 DESCRIPTION

A Statocles::Page takes one or more documents and renders them into one or more
HTML pages.
