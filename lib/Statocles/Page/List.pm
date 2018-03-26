package Statocles::Page::List;
our $VERSION = '0.090';
# ABSTRACT: A page presenting a list of other pages

use Statocles::Base 'Class';
with 'Statocles::Page';
use List::Util qw( reduce );
use Statocles::Template;
use Statocles::Page::ListItem;
use Statocles::Util qw( uniq_by );

=attr pages

The pages that should be shown in this list.

=cut

has _pages => (
    is => 'ro',
    isa => ArrayRef[ConsumerOf['Statocles::Page']],
    init_arg => 'pages',
);

sub pages {
    my ( $self ) = @_;

    my %rewrite;
    if ( $self->type eq 'application/rss+xml' || $self->type eq 'application/atom+xml' ) {
        %rewrite = ( rewrite_mode => 'full' );
    }

    my @pages;
    for my $page ( @{ $self->_pages } ) {
        # Always re-wrap the page, even if it's already wrapped,
        # to change the rewrite_mode
        push @pages, Statocles::Page::ListItem->new(
            %rewrite,
            page => $page->isa( 'Statocles::Page::ListItem' ) ? $page->page : $page,
        );
    }

    return \@pages;
}

=attr next

The path to the next page in the pagination series.

=attr prev

The path to the previous page in the pagination series.

=cut

has [qw( next prev )] => (
    is => 'rw',
    isa => PagePath,
    coerce => PagePath->coercion,
);

=attr date

Get the date of this list. By default, this is the latest date of the first
page in the list of pages.

=cut

has '+date' => (
    lazy => 1,
    default => sub {
        my ( $self ) = @_;
        my $date = reduce { $a->epoch gt $b->epoch ? $a : $b }
                    map { $_->date }
                    @{ $self->pages };
        return $date;
    },
);

=attr search_change_frequency

Override the default L<search_change_frequency|Statocles::Page/search_change_frequency>
to C<daily>, because these pages aggregate other pages.

=cut

has '+search_change_frequency' => (
    default => sub { 'daily' },
);

=attr search_priority

Override the default L<search_priority|Statocles::Page/search_priority> to reduce
the rank of list pages to C<0.3>.

It is more important for users to get to the full page than
to get to this list page, which may contain truncated content, and whose relevant
content may appear 3-4 items down the page.

=cut

has '+search_priority' => (
    default => sub { 0.3 },
);

=method paginate

    my @pages = Statocles::Page::List->paginate( %args );

Build a paginated list of L<Statocles::Page::List> objects.

Takes a list of key-value pairs with the following keys:

    path    - An sprintf format string to build the path, like '/page-%i.html'.
              Pages are indexed started at 1.
    index   - The special, unique path for the first page. Optional.
    pages   - The arrayref of Statocles::Page::Document objects to paginate.
    after   - The number of items per page. Defaults to 5.

Return a list of Statocles::Page::List objects in numerical order, the index
page first (if any).

=cut

sub paginate {
    my ( $class, %args ) = @_;

    # Unpack the args so we can pass the rest to new()
    my $after = delete $args{after} // 5;
    my $pages = delete $args{pages};
    my $path_format = delete $args{path};
    my $index = delete $args{index};

    # The date is the max of all input pages, since input pages get moved between
    # all the list pages
    my $date = reduce { $a->epoch gt $b->epoch ? $a : $b }
                map { $_->date }
                @$pages;

    my @sets;
    for my $i ( 0..$#{$pages} ) {
        push @{ $sets[ int( $i / $after ) ] }, $pages->[ $i ];
    }

    my @retval;
    for my $i ( 0..$#sets ) {
        my $path = $index && $i == 0 ? $index : sprintf( $path_format, $i + 1 );
        my $prev = $index && $i == 1 ? $index : sprintf( $path_format, $i );
        my $next = $i != $#sets ? sprintf( $path_format, $i + 2 ) : '';

        # Remove index.html from link URLs
        s{/index[.]html$}{/} for ( $prev, $next );

        push @retval, $class->new(
            path => $path,
            pages => $sets[$i],
            ( $next ? ( next => $next ) : () ),
            ( $i > 0 ? ( prev => $prev ) : () ),
            date => $date,
            %args,
        );
    }

    return @retval;
}

=method vars

    my %vars = $page->vars;

Get the template variables for this page.

=cut

around vars => sub {
    my ( $orig, $self ) = @_;
    return (
        $self->$orig,
        pages => $self->pages,
    );
};

=method links

    my @links = $page->links( $key );

Get the given set of links for this page. See L<the links
attribute|Statocles::Page/links> for some commonly-used keys.

For List pages, C<stylesheet> and C<script> links are also collected
from the L<inner pages|/pages>, to ensure that content in those pages
works correctly.

=cut

around links => sub {
    my ( $orig, $self, @args ) = @_;

    if ( @args > 1 || $args[0] !~ /^(?:stylesheet|script)$/ ) {
        return $self->$orig( @args );
    }

    my @links;
    for my $page ( @{ $self->pages } ) {
        push @links, $page->links( @args );
    }
    push @links, $self->$orig( @args );
    return uniq_by { $_->href } @links;
};

1;
__END__

=head1 DESCRIPTION

A List page contains a set of other pages. These are frequently used for index
pages.

