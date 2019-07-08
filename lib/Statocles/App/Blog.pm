package Statocles::App::Blog;
our $VERSION = '0.094';
# ABSTRACT: A blog application

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SEE ALSO

=cut

use Mojo::Base 'Mojolicious::Plugin';
use Scalar::Util qw( blessed );

has moniker => 'blog';

sub _routify {
    my ( $app, $route ) = @_;
    return unless $route;
    return blessed $route ? $route : $app->routes->any( $route );
}

sub register {
    my ( $self, $app, $conf ) = @_;
    my $route = _routify( $app, delete $conf->{route} // $conf->{base_url} );
    my $filter = delete $conf->{filter};
    push @{$app->renderer->classes}, __PACKAGE__;
    $route->get( '<page:num>' )->to(
        'yancy#list',
        page => 1,
        template => 'blog',
        schema => 'pages',
        filter => { %{ $filter // {} }, date => { '!=' => undef } },
        order_by => { -desc => 'date' },
        %$conf,
    );
    # Add the index page to the list of pages to export. The index page
    # has links to all the blog posts and all the other pages, so that
    # should export the entire blog.
    push @{ $app->export->pages }, $route; # First page has links to other pages
}

1;
__DATA__
@@ blog.html.ep
% for my $item ( @$items ) {
<article>
    <header>
        <h1><a href="<%= url_for( $item->{path} ) %>"><%== $item->{title} %></a></h1>

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
            <a data-disqus-identifier="<%= url_for( $item->{path} ) %>" href="<%= url_for( $item->{path} ) %>#disqus_thread">0 comments</a>
            % }
        </aside>
    </header>

    % my $sections = sectionize( $item->{html} );
    <section>
        %== $sections->[ 0 ]
    </section>

    % if ( @$sections > 1 ) {
    <p><a href="<%= url_for( $item->{path} ) %>#section-2">Continue reading...</a></p>
    % }

</article>
% }

<ul class="pager">
    <li class="prev">
        % if ( $page < $total_pages ) {
            <a class="button button-primary" rel="prev"
                href="<%= url_for( page => $page + 1 ) %>"
            >
                &larr; Older
            </a>
        % }
        % else {
            <button disabled>
                &larr; Older
            </button>
        % }
    </li>
    <li class="next">
        % if ( $page > 1 ) {
            <a class="button button-primary" rel="next"
                href="<%= url_for( page => $page - 1 ) %>"
            >
                Newer &rarr;
            </a>
        % }
        % else {
            <button disabled>
                Newer &rarr;
            </button>
        % }
    </li>
</ul>

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
            <link><%= url_for( $item->{path} )->to_abs %></link>
            <guid><%= url_for( $item->{path} )->to_abs %></guid>
            <description><![CDATA[
                % my $sections = sectionize( $item->{html} );
                %== $sections->[0]
                % if ( @$sections > 1 ) {
                <p><a href="<%= url_for( $item->{path} )->to_abs %>#section-2">Continue reading...</a></p>
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
        <link rel="alternate" href="<%= url_for( $item->{path} )->to_abs %>" />
        <content type="html"><![CDATA[
            % my $sections = sectionize( $item->{html} );
            %== $sections->[0]
            % if ( @$sections > 1 ) {
            <p><a href="<%= url_for( $item->{path} )->to_abs %>#section-2">Continue reading...</a></p>
            % }
        ]]></content>
        <updated><%= strftime('%Y-%m-%dT%H:%M:%SZ', $item->{date}) %></updated>
    </entry>
    % }
</feed>
