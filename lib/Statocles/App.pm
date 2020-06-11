package Statocles::App;
our $VERSION = '2.000';

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SEE ALSO

=cut

use Mojo::Base 'Mojolicious::Plugin';
use Scalar::Util qw( blessed );

has moniker => '';
has categories => sub { [] };

sub register {
    my ( $self, $app, $conf ) = @_;
    push @{$app->renderer->classes}, __PACKAGE__;
    my $route = $app->routes->any( $conf->{route} );
    my $filter = delete $conf->{filter} // {};
    my $order_by = delete $conf->{order_by} // 'path';
    my $index_route = $route->get( '<page:num>' )->to(
        'yancy#list',
        page => 1,
        template => 'list',
        schema => 'pages',
        filter => $filter,
        order_by => $order_by,
        %$conf,
    );
    # Add the index page to the list of pages to export. The index page
    # has links to feeds, all the blog posts, and all the other pages, so that
    # should export the entire blog.
    push @{ $app->export->pages }, $index_route->render({ page => 1 });

    if ( !exists $conf->{categories} ) {
        # The default categories are one for each tag
        # XXX: This is not updated when content is edited, but neither
        # are templates so maybe Morbo is the solution here...
        my %tags;
        for my $item ( $app->yancy->list( pages => $filter ) ) {
            for my $tag ( @{ $item->{tags} // [] } ) {
                $tags{ $tag }++;
            }
        }
        for my $tag ( sort keys %tags ) {
            push @{ $conf->{categories} }, {
                title => $tag,
                route => join( '/', 'tag', $tag ),
                filter => {
                    tags => {
                        -has => $tag,
                    },
                },
            };
        }
    }
    for my $category ( @{ $conf->{categories} // [] } ) {
        my $category_route = ref $category->{route} ? $category->{route}
            : $route->get( ( $category->{route} // $category->{title} ) . '/<page:num>' )->to(
                'yancy#list',
                page => 1,
                template => 'list',
                schema => 'pages',
                filter => {
                    %$filter,
                    %{ $category->{filter} },
                },
                order_by => $order_by,
                %$conf,
            );
        push @{ $app->export->pages }, $category_route->render({ page => 1 });
        push @{ $self->categories }, {
            %$category,
            route => $category_route,
        };
    }
}

sub category_links {
    my ( $self ) = @_;
    return map +{ %$_, href => $_->{route}->render({ page => 1 }) }, @{ $self->categories };
}

1;
__DATA__
@@ list.rss.ep
%# RSS requires date/time in the 'C' locale as per RFC822. strftime() is one of
%# the few things that actually cares about locale.
% use POSIX qw( locale_h );
% my $current_locale = setlocale( LC_TIME );
% setlocale( LC_TIME, 'C' );
<?xml version="1.0"?>
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
    <channel>
        <title><%= config->{title} %></title>
        <link><%= url_for( format => 'html' )->to_abs %></link>
        <atom:link href="<%= url_for()->to_abs %>" rel="self" type="application/rss+xml" />
        <description>Blog feed of <%= config->{title} %></description>
        <generator>Statocles <%= $Statocles::VERSION %></generator>
        % for my $item ( @$items ) {
        <item>
            <title><%== $item->{title} %></title>
            <link><%= url_for( "/$item->{path}" )->to_abs %></link>
            <guid><%= url_for( "/$item->{path}" )->to_abs %></guid>
            <description><![CDATA[
                % my $sections = sectionize( $item->{html} );
                %== $sections->[0]
                % if ( @$sections > 1 ) {
                <p><a href="<%= url_for( "/$item->{path}" )->to_abs %>#section-2">Continue reading...</a></p>
                % }
            ]]></description>
            <pubDate>
                <%= strftime('%a, %d %b %Y %H:%M:%S +0000', $item->{date}) %>
            </pubDate>
        </item>
        % }
    </channel>
</rss>
% setlocale( LC_TIME, $current_locale );

@@ list.atom.ep
<?xml version="1.0"?>
<feed xmlns="http://www.w3.org/2005/Atom">
    <id><%= url_for()->to_abs %></id>
    <title><%= config->{title} %></title>
    <updated><%= strftime('%Y-%m-%dT%H:%M:%SZ') %></updated>
    <link rel="self" href="<%= url_for( format => 'html' )->to_abs %>"/>
    <link rel="alternate" href="<%= url_for()->to_abs %>"/>
    % if ( my $author = config->{author} ) {
    <author>
        % for my $key ( keys %$author ) {
            <%= tag $key => begin %><%= $author->{ $key } %><% end %>
        % }
    </author>
    % }
    <generator version="<%= $Statocles::VERSION %>">Statocles</generator>

    % for my $item ( @$items ) {
    <entry>
        <id><%= url_for( $item->{path} )->to_abs %></id>
        <title><%== $item->{title} %></title>
        % if ( my $author = $item->{author} ) {
        <author>
            % for my $key ( keys %$author ) {
                <%= tag $key => begin %><%= $author->{ $key } %><% end %>
            % }
        </author>
        % }
        <link rel="alternate" href="<%= url_for( "/$item->{path}" )->to_abs %>" />
        <content type="html"><![CDATA[
            % my $sections = sectionize( $item->{html} );
            %== $sections->[0]
            % if ( @$sections > 1 ) {
            <p><a href="<%= url_for( "/$item->{path}" )->to_abs %>#section-2">Continue reading...</a></p>
            % }
        ]]></content>
        <updated><%= strftime('%Y-%m-%dT%H:%M:%SZ', $item->{date}) %></updated>
    </entry>
    % }
</feed>

@@ _item-caption.html.ep
% if ( $item->{tags} ) {
<p class="tags">Tags:
    % for my $tag ( @{$item->{tags}} ) {
        <a href="<%= url_for( join ("/", $config->{apps}{blog}{route}, "tag/$tag") =~ s{//}{/}r) %>" rel="tag"><%== $tag %></a>
    % }
</p>
% }
% if ( $item->{date} ) {
<aside>
    <time datetime="<%= strftime('%Y-%m-%d', $item->{date} ) %>">
        Posted on <%= strftime('%Y-%m-%d', $item->{date} ) %>
    </time>
</aside>
% }
% if ( $item->{author} ) {
<aside>
    %= content author => begin
    <span class="author">by <%= $item->{author} %></span>
    % end
</aside>
% }
% if ( $disqus ) {
    <a data-disqus-identifier="<%= url_for( "/$item->{path}" ) %>" href="<%= url_for( "/$item->{path}" ) %>#disqus_thread">0 comments</a>
% }
