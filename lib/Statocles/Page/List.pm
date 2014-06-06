package Statocles::Page::List;
# ABSTRACT: A page presenting a list of other pages

use Statocles::Class;
with 'Statocles::Page';
use Statocles::Template;

=attr pages

The pages that should be shown in this list.

=cut

has pages => (
    is => 'ro',
    isa => ArrayRef[ConsumerOf['Statocles::Page']],
);

=attr template

The body template for this list. Should be a string or a Statocles::Template
object.

=cut

has '+template' => (
    default => sub {
        Statocles::Template->new(
            content => <<'ENDTEMPLATE'
% for my $page ( @$pages ) {
<%= $page->{published} %> <%= $page->{path} %> <%= $page->{title} %> <%= $page->{author} %> <%= $page->{content} %>
% }
ENDTEMPLATE
        );
    },
);

=method render

Render this page. Returns the full content of the page.

=cut

sub render {
    my ( $self, %args ) = @_;
    my $content = $self->template->render(
        %args,
        pages => [
            map { +{ %{ $_->document }, published => $_->published, content => $_->content, path => $_->path } }
            @{ $self->pages }
        ],
        app => $self->app,
    );
    return $self->layout->render(
        %args,
        content => $content,
        app => $self->app,
    );
}

1;
__END__

=head1 DESCRIPTION

A List page contains a set of other pages. These are frequently used for index
pages.

