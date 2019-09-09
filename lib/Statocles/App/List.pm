package Statocles::App::List;
our $VERSION = '0.094';
# ABSTRACT: A list of pages

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SEE ALSO

=cut

use Mojo::Base 'Mojolicious::Plugin';
use Scalar::Util qw( blessed );

has moniker => 'list';

sub _routify {
    my ( $app, $route ) = @_;
    return unless $route;
    return blessed $route ? $route : $app->routes->any( $route );
}

sub register {
    my ( $self, $app, $conf ) = @_;
    my $route = _routify( $app, $conf->{route} );
    push @{$app->renderer->classes}, __PACKAGE__;
    my $index_route = $route->get( '<page:num>' )->to(
        'yancy#list',
        page => 1,
        template => 'list',
        schema => 'pages',
        order_by => 'title',
        %$conf,
    );
    # Add the index page to the list of pages to export. The index page
    # has links to all the other pages, so that should export the entire set
    push @{ $app->export->pages }, $index_route->render({ page => 1 });
}

1;
__DATA__
@@ list.html.ep
<ul>
% for my $item ( @$items ) {
    <li><a href="<%= url_for( "/$item->{path}" ) %>"><%== $item->{title} %></a></li>
% }
</ul>

%= include 'pager'

@@ pager.html.ep
<ul class="pager">
    <li class="next">
        % if ( $page < $total_pages ) {
            <a class="button button-primary" rel="next"
                href="<%= url_for( page => $page + 1 ) %>"
            >
                &larr; <%= stash( 'label_next' ) // 'Next' %>
            </a>
        % }
        % else {
            <button disabled>
                &larr; Older
            </button>
        % }
    </li>
    <li class="prev">
        % if ( $page > 1 ) {
            <a class="button button-primary" rel="prev"
                href="<%= url_for( page => $page - 1 ) %>"
            >
                <%= stash( 'label_prev' ) // 'Previous' %> &rarr;
            </a>
        % }
        % else {
            <button disabled>
                Newer &rarr;
            </button>
        % }
    </li>
</ul>
