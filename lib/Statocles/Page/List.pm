package Statocles::Page::List;
# ABSTRACT: A page presenting a list of other pages

use Statocles::Class;
with 'Statocles::Page';
use Text::Template;

=attr pages

The pages that should be shown in this list.

=cut

has pages => (
    is => 'ro',
    isa => ArrayRef[ConsumerOf['Statocles::Page']],
);

=attr template

The body template for this list. Should be a string or a Text::Template
object.

=cut

has '+template' => (
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
);

=method render

Render this page. Returns the full content of the page.

=cut

sub render {
    my ( $self, %args ) = @_;
    my $content = $self->template->fill_in( HASH => {
        %args,
        pages => [
            map { +{ %{ $_->document }, content => $_->content } }
            @{ $self->pages }
        ],
    } ) or die "Could not fill in template: $Text::Template::ERROR";
    return $self->layout->fill_in( HASH => {
        %args,
        content => $content,
    } ) or die "Could not fill in layout: $Text::Template::ERROR";
}

1;
__END__

=head1 DESCRIPTION

A List page contains a set of other pages. These are frequently used for index
pages.

