---
title: Gallery
data:
    sites:
        - name: Chicago.PM
          url: http://chicago.pm.org
          source: http://github.com/ChicagoPM/ChicagoPM.github.io
          description: Website for the Chicago Perl Mongers
          images:
            - chicagopm-main.jpg
            - chicagopm-inner.jpg
        - name: Indie Palate
          url: http://indiepalate.com
          source: http://github.com/preaction/www.indiepalate.com
          description: Cooking / recipe blog
          images:
            - indiepalate.jpg
---

# Gallery

Here are some sites that use Statocles. Want to add yours? [Tell us about
it](http://github.com/preaction/Statocles/issues) or [send a pull
request](http://github.com/preaction/Statocles).

% for my $site ( @{ $self->data->{sites} } ) {

<h2 style="border-bottom: 1px solid #444"><%= $site->{name} %></h2>
<div class="row">
    <div class="four columns">
        <p><%= $site->{description} %></p>
        <ul class="bare">
            <li><a href="<%= $site->{url} %>">Site</a></li>
            <li><a href="<%= $site->{source} %>">Source</a></li>
        </ul>
    </div>
    % for my $img ( @{ $site->{images} } ) {
    <div class="four columns">
        <a href="<%= $site->{url} %>">
            <img style="max-width: 100%; border: 2px solid;" src="<%= $img %>"
                alt="screenshot of <%= $site->{name} %>"
            />
        </a>
    </div>
    % }
</div>

% }
