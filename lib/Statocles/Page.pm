package Statocles::Page;
# ABSTRACT: Render documents into HTML

use Statocles::Class;
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
        die "Template is undef" unless defined $_[0];
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

A Statocles::Page takes one or more documents and renders them into one or more
HTML pages.
