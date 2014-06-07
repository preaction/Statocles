package Statocles::Page::List;
# ABSTRACT: A page presenting a list of other pages

use Statocles::Class;
with 'Statocles::Page';
use List::MoreUtils qw( part );
use Statocles::Template;

=attr pages

The pages that should be shown in this list.

=cut

has pages => (
    is => 'ro',
    isa => ArrayRef[ConsumerOf['Statocles::Page']],
);

=attr next

The path to the next page in the pagination series.

=attr prev

The path to the previous page in the pagination series.

=cut

has [qw( next prev )] => (
    is => 'ro',
    isa => Path,
    coerce => Path->coercion,
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

=method paginate

Build a paginated list of Statocles::Page::List objects.

Takes a list of key-value pairs with the following keys:

    path    - An sprintf format string to build the path, like '/page-%i.html'.
              Pages are indexed started at 1.
    pages   - The arrayref of Statocles::Page::Document objects to paginate.
    after   - The number of items per page. Defaults to 5.

=cut

sub paginate {
    my ( $class, %args ) = @_;

    # Unpack the args so we can pass the rest to new()
    my $after = delete $args{after} // 5;
    my $pages = delete $args{pages};
    my $path = delete $args{path};

    my @sets = part { int( $_ / $after ) } 0..$#{$pages};
    my @retval;
    for my $i ( 0..$#sets ) {
        push @retval, $class->new(
            path => sprintf( $path, $i + 1 ),
            pages => [ @{$pages}[ @{ $sets[$i] } ] ],
            ( $i != $#sets ? ( next => sprintf( $path, $i + 2 ) ) : () ),
            ( $i ? ( prev => sprintf( $path, $i ) ) : () ),
            %args,
        );
    }

    return @retval;
}

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

