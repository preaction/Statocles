package Statocles::Page::List;
# ABSTRACT: A page presenting a list of other pages

use Statocles::Class;
use Text::Template;

=attr path

The path for this page.

=cut

has path => (
    is => 'ro',
    isa => Str,
    required => 1,
);

=attr pages

The pages that should be shown in this list.

=cut

has pages => (
    is => 'ro',
    isa => ArrayRef[InstanceOf['Statocles::Page']],
);

my $coerce_template = sub {
    die "Template is undef" unless defined $_[0];
    return !ref $_[0] 
        ? Text::Template->new( TYPE => 'STRING', SOURCE => $_[0] )
        : $_[0]
        ;
};

=attr template

The body template for this list. Should be a string or a Text::Template
object.

=cut

has template => (
    is => 'ro',
    isa => InstanceOf['Text::Template'],
    default => sub {
        Text::Template->new(
            TYPE => 'STRING',
            SOURCE => '{
                join "\n", map {
                    join( " ", $_->{title}, $_->{author}, $_->{content} )
                } @pages
            }',
        );
    },
    coerce => $coerce_template,
);

=attr layout

The layout template for this list. Should be a string or a Text::Template
object.

=cut

has layout => (
    is => 'ro',
    isa => InstanceOf['Text::Template'],
    default => sub {
        Text::Template->new( TYPE => 'STRING', SOURCE => '{$content}' );
    },
    coerce => $coerce_template,
);

=method render

Render this page. Returns the full content of the page.

=cut

sub render {
    my ( $self ) = @_;
    my $content = $self->template->fill_in( HASH => {
        pages => [
            map { +{ %{ $_->document }, content => $_->content } }
            @{ $self->pages }
        ],
    } ) or die "Could not fill in template: $Text::Template::ERROR";
    return $self->layout->fill_in( HASH => {
        content => $content,
    } ) or die "Could not fill in layout: $Text::Template::ERROR";
}

1;
__END__

=head1 DESCRIPTION

A List page contains a set of other pages. These are frequently used for index
pages.

