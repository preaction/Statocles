package Statocles::App::Blog;
our $VERSION = '0.094';
# ABSTRACT: A blog application

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SEE ALSO

=cut

use Mojo::Base 'Mojolicious::Plugin';
use Scalar::Util qw( blessed );
use Statocles::App::List; # Contains default pager template

has moniker => 'blog';
has categories => sub { [] };

sub _routify {
    my ( $app, $route ) = @_;
    return unless $route;
    return blessed $route ? $route : $app->routes->any( $route );
}

sub register {
    my ( $self, $app, $conf ) = @_;
    my $route = _routify( $app, delete $conf->{route} // $conf->{base_url} );
    my $filter = { %{ delete $conf->{filter} // {} }, date => { '!=' => undef } };
    push @{$app->renderer->classes}, __PACKAGE__, 'Statocles::App::List';
    my $index_route = $route->get( '<page:num>' )->to(
        'yancy#list',
        page => 1,
        template => 'blog',
        schema => 'pages',
        filter => $filter,
        order_by => { -desc => 'date' },
        %$conf,
    );
    # Add the index page to the list of pages to export. The index page
    # has links to all the blog posts and all the other pages, so that
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
                template => 'blog',
                schema => 'pages',
                filter => {
                    %$filter,
                    %{ $category->{filter} },
                },
                order_by => { -desc => 'date' },
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
@@ blog.html.ep
% content_for head => begin
    <link rel="alternate" type="application/rss+xml" href="<%= url_for( page => 1, format => 'rss' ) %>"/>
    <link rel="alternate" type="application/atom+xml" href="<%= url_for( page => 1, format => 'atom' ) %>"/>
% end
% for my $item ( @$items ) {
<article>
    <header>
        <h1><a href="<%= url_for( "/$item->{path}" ) %>"><%== $item->{title} %></a></h1>

        <aside>
            <time datetime="<%= strftime('%Y-%m-%d', $item->{date}) %>">
                Posted on <%= strftime('%Y-%m-%d', $item->{date}) %>
            </time>
            % if ( $item->{author} ) {
                <span class="author">
                    by <%= $item->{author} %>
                </span>
            % }
            % if ( config->{data}{disqus}{shortname} ) {
            <a data-disqus-identifier="<%= url_for( $item->{path} ) %>" href="<%= url_for( "/$item->{path}" ) %>#disqus_thread">0 comments</a>
            % }
        </aside>
    </header>

    % my $sections = sectionize( $item->{html} );
    <section>
        %== $sections->[ 0 ]
    </section>

    % if ( @$sections > 1 ) {
    <p><a href="<%= url_for( "/$item->{path}" ) %>#section-2">Continue reading...</a></p>
    % }

</article>
% }

%= include 'pager', label_prev => 'Newer', label_next => 'Older'

% if ( config->{data}{disqus}{shortname} ) {
<script type="text/javascript">
    var disqus_shortname = '<%= config->{data}{disqus}{shortname} %>';
    (function () {
        var s = document.createElement('script'); s.async = true;
        s.type = 'text/javascript';
        s.src = '//' + disqus_shortname + '.disqus.com/count.js';
        (document.getElementsByTagName('HEAD')[0] || document.getElementsByTagName('BODY')[0]).appendChild(s);
    }());
</script>
% }

@@ blog.rss.ep
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

@@ blog.atom.ep
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
