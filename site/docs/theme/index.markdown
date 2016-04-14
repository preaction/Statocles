---
title: Building a Statocles Theme
---

# Building a Statocles Theme

Statocles, like most content management systems, uses templates to
render structured data into HTML. In Statocles, a collection of
templates is called a theme.

A Statocles theme is a directory in your site. Inside this directory,
the theme is organized into subdirectories based on which application or
which purpose a template serves. A simple Statocles theme could contain
these directories:

* `blog`: Templates for the Blog application
* `layout`: Layout templates, wrappers for application content
* `site`: Site-wide meta-templates like `sitemap.xml` and `robots.txt`
* `css`: CSS files required by our theme

These directories can contain any kind of files, including CSS,
JavaScript, and images, but the most important files they contain are
Statocles templates, which end in a `.ep` file extention.

## Embedded Perl

The `.ep` stands for "Embedded Perl", and is the template syntax used by
[the Mojolicious web application framework](http://mojolicious.org).
This syntax is similar in concept to Ruby's "Embedded Ruby" (`.erb`):

* `<%%` and `%>` denote sections of Perl code
* `<%%= ... %>` writes the result of the `...` expression
* `%` on the beginning of a line means the rest of the line is Perl code

XXX Add some examples

The rest of this guide will walk through creating a theme from scratch
using Statocles's template syntax.  The result of this guide is the
`tutorial` theme, bundled with Statocles.

## Create a Blog Post Template

The first template we will create is the easiest: Individual blog posts.
This template will show the full text of our blog post, along with the
list of tags linked to the tag pages.

To start creating our new theme, create a `theme` directory. Inside
that, create a `blog` directory.

Inside the `blog` directory, create a file called `post.html.ep`. This
is the default name for the blog post template.

Each template has its own set of variables inside. These variables are
documented in the application class. [Read the Blog app
documentation](/pod/Statocles/App/Blog). By default, all templates have
access to the current page object (`$page`), the current application
object (`$app`), and the current site object (`$site`).

Templates also have access to "helpers", which are functions that can
insert content, render Markdown, and include other files into the
current template. Custom helpers can be added to a Statocles site
through plugins, but more on that later.

## Template Values

For our blog post template, lets start by displaying the post title in
an `<h1>` tag.  The blog post is our page object (`$page`), so to get
the title, we call the `title` method: `$page->title`. To insert the
page title, we use the `<%%= ... %>` template expression syntax, like so:

%= highlight html => begin
<h1><%%= $page->title %></h1>
% end

Before we go any further, we have a potential problem: What if our title
contains HTML characters like `<` and `>`? To quickly escape HTML from
wreaking havoc on our template, we can use `<%%== ... %>` instead:

%= highlight html => begin
<h1><%%== $page->title %></h1>
% end

Now our page title is safe from dangerous HTML characters.

### Template Conditionals

For out next piece of data, let's add the post's author. Like the title,
we can get the author by calling the `author` method, like
`$page->author`. The author field in the post is optional, so we only
want to add the tag if we know who the post's author is. For that, we
can use a Perl conditional `if` statement. Let's add our byline in an
`<aside>` tag, so people know it isn't part of the main post content.

%= highlight html => begin
%% if ( $page->author ) {
    <aside>by <%%= $page->author %></aside>
%% }
% end

So now if our post has an author, say "Hazel Murphy", our post will be
properly attributed with `<aside>by Hazel Murphy</aside>`.

### Main Content

Next, let's add the blog post body content. This time, we'll use the
`content` helper, which gives us the default content for the page. Since
this is on a line by itself, we can use the `%` line syntax, like so:

%= highlight html => begin
%%= content
% end

Just like with `<%%= ... %>` and `<%%== ... %>`, one `=` (`%=`) means
"replace me with content" and two `=` (`%==`) means "replace me with
HTML-escaped content".

### Template Loops

Finally, we need to list the tags our post has. Additionally, we need
those tags to be linked to the tag page that lists all the posts with
that tag. For this, we'll need to use Perl's for-loop syntax.

Just like the title and author, the post tags can be found in the `tags`
method. Unlike title and author, this method returns a list of
[Statocles link objects](/pod/Statocles/Link). Link objects have their
own methods for getting the link text (`text`) and URL (`href`).

Let's add our tag links in a list element. We'll give this element the
`tags` class so we can add some CSS to it later when we get to the
layout template. Inside the list, we'll loop over the tags, and create
links with the tag's URL and tag name:

%= highlight html => begin
<ul class="tags">
%% for my $tag ( $page->tags ) {
    <li>
        <a href="<%%= $tag->href %>">
            <%%= $tag->text %>
        </a>
    </li>
%% }
</ul>
% end

Notice that we can put `<%%= ... %>` anywhere we want, even inside of the
`href="..."` attribute. Just make sure to close the template tag with
`%>` before closing the attribute with quotes.

### Finished Template

Now we've got a blog post template that shows the post title, the
byline, the content, and the tags. Our finished template looks like
this:

%= highlight html => begin
<h1><%%== $page->title %></h1>

%% if ( $page->author ) {
    <aside>by <%%= $page->author %></aside>
%% }

%%= content

<ul class="tags">
%% for my $tag ( $page->tags ) {
    <li>
        <a href="<%%= $tag->href %>">
            <%%= $tag->text %>
        </a>
    </li>
%% }
</ul>
% end

Remember to save this in your theme's `blog` directory as `post.html.ep`.

## Create a Blog Index Template

Next, we need to create a template to display a list of posts, which
will become the front page of our blog (and our entire site). This list
of posts will display the post title and byline, the first section of
the post's content, and the list of tags.

XXX

Remember to save this in your theme's `blog` directory as
`index.html.ep`.

## Create a Layout Template

Finally, we should make a layout template. The layout template surrounds
every content template, like the blog post and blog index we just made.
This allows us to have site-wide navigations, headers, footers, scripts,
and themes.

Unlike the content templates, the layout template is extremely simple.
The most important additions the layout contributes is the HTML
boilerplate, like so:

%= highlight html => begin
<!DOCTYPE html>
<html>
    <head>
        <title><%= $site->title %></title>
    </head>
    <body>
        %= content
    </body>
</html>
% end

In this basic layout template, we provide the bare minimum HTML
structure: A `<head>` element that contains a `<title>`, in which we add
the site's `title` attribute, and a `<body>` element that uses the
`content` helper to print the content from the page (the blog post or
blog index).

### Document Scripts and Stylesheets

Unfortunately, this basic layout template does not enable many of the
features that our content requires. Remember from [the content
guide](), every document is allowed to add custom scripts and
stylesheets. This is done by the layout template. Every theme bundles
with Statocles has this feature, so we should add it to our theme, too.

Like the content templates, the layout template gets the current page,
the current app, and the current site as variables. The links to the
scripts and stylesheets that we want are available from the `links()`
method. This method takes an argument, which is the links key. For
stylesheets, the key is `stylesheet`, and for scripts, the key is
`script`.

Documents can have multiple links, so we need a loop. First we'll loop
over the stylesheets and add `<link/>` tags, then we'll loop over the
scripts and add `<script>` tags.

%= highlight html => begin
%# XXX
% end

### Navigations

The final thing we should add to our layout is a navigation. This is how
the site's `nav` configuration works.

XXX

## Copy templates from other themes

There are a lot of templates that make up a Statocles site. Though this
does make themes a bit more work to create, ultimately it means
flexibility to make your site look how you want it to, even in the
syndicated feed and sitemap files.

But, when we don't need to customize these files, we can just copy them
from the default theme using Statocles's `bundle theme` command. The
remaining templates we need for our site are:

* `blog/index.atom.ep` - The blog Atom feed
* `blog/index.rss.ep` - The blog RSS feed
* `site/sitemap.xml.ep` - The [sitemap file](...)
* `site/robots.txt.ep` - The [robots.txt file](...)

XXX

