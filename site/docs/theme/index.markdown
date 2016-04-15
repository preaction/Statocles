---
title: Building a Statocles Theme
---

# Building a Statocles Theme

Statocles, like most content management systems, uses templates to
render the structured data of a [Statocles Document](../content) into
HTML. In Statocles, a collection of templates is called a theme.

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

The rest of this guide will walk through creating a theme from scratch
using Statocles's template syntax. The result of this guide is the
`tutorial` theme, bundled with Statocles.

## Create a Blog Post Template

The first template we will create is the easiest: Individual blog posts.
This template will show the full text of our blog post, along with the
list of tags linked to the tag pages.

To start creating our new theme, create a `theme` directory. Inside
that, create a `blog` directory. Inside the `blog` directory, create
a file called `post.html.ep`. This is the default name for the blog post
template.

Each template has its own set of variables inside. These variables are
documented in the application class. [Read the Blog app
documentation](/pod/Statocles/App/Blog). By default, all templates have
access to the current page object (`$page`), the current application
object (`$app`), and the current site object (`$site`).

Templates also have access to "helpers", which are functions that can
insert content, render Markdown, and include other files into the
current template. Custom helpers can be added to a Statocles site
through plugins ([see the development guide for more information on
custom helpers](../develop/)).

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
        <title><%%== $page->title %> - <%%== $site->title %></title>
    </head>
    <body>
        %%= content
    </body>
</html>
% end

In this basic layout template, we provide the bare minimum HTML
structure: A `DOCTYPE` and `<html>` element, a `<head>` element that
contains a `<title>`, in which we add the page's `title` attribute and
the site's `title` attribute (HTML escaped of course), and a `<body>`
element that uses the `content` helper to print the main page content
(the blog post or blog index).

### Document Scripts and Stylesheets

Unfortunately, this basic layout template does not enable many of the
features that our content requires. Remember from [the content
guide](../content/), every document is allowed to add custom scripts and
stylesheets. This feature is implemented by the layout template. Every
theme bundles with Statocles has this feature, so we should add it to
our theme, too.

Like the content templates, the layout template gets the current page,
the current app, and the current site as variables. The links to the
scripts and stylesheets that we want are available from the `links()`
method. This method takes an argument, which is the links key. For
stylesheets, the key is `stylesheet`, and for scripts, the key is
`script`. The method then returns a list of [link
objects](/pod/Statocles/Link) which have methods to get the link URL
(`href`) and link text (`text`).

Documents can have multiple links, so we need a loop. First we'll loop
over the stylesheets and add `<link/>` tags, then we'll loop over the
scripts and add `<script>` tags.

%= highlight html => begin
    <head>
        <title><%%== $page->title %> - <%%== $site->title %></title>
        %% for my $link ( $page->links( 'stylesheet' ) ) {
            <link href="<%%= $link->href %>" rel="stylesheet" />
        %% }
        %% for my $link ( $page->links( 'script' ) ) {
            <script src="<%%= $link->href %>"></script>
        %% }
    </head>
% end

Now when users add custom scripts and stylesheets to their documents,
they will be added to the `<head>` element.

### Navigations

The final thing we should add to our layout is a navigation. This is how
the site's `nav` configuration works. See [the config guide](../config/)
for information on `nav`.

Like the page object's `links()` method, the site object has a `nav()`
method which gets the named nav and returns a list of [link
objects](/pod/Statocles/Link) which have methods to get the link URL
(`href`) and link text (`text`).

Let's allow users to create a nav called `main`, which we will display
at the very top of the page. To do this, we call the `nav()` method with
the name of the nav we want to get: `main`. We then loop over the links
and create our list.

%= highlight html => begin
<nav>
    <ul>
        %% for my $link ( $site->nav( 'main' ) ) {
            <li>
                <a href="<%%= $link->href %>">
                    <%%= $link->text %>
                </a>
            </li>
        %% }
    </ul>
</nav>
% end

If we want to make the main nav optional, we can enclose our `<ul>` in
a conditional (`if ( $site->nav( 'main' ) ) {`).

Our final layout template looks like this:

%= highlight html => begin
<!DOCTYPE html>
<html>
    <head>
        <title><%%== $page->title %> - <%%== $site->title %></title>
        %% for my $link ( $page->links( 'stylesheet' ) ) {
            <link href="<%%= $link->href %>" rel="stylesheet" />
        %% }
        %% for my $link ( $page->links( 'script' ) ) {
            <script src="<%%= $link->href %>"></script>
        %% }
    </head>
    <body>
        <nav>
            <ul>
                %% for my $link ( $site->nav( 'main' ) ) {
                    <li>
                        <a href="<%%= $link->href %>">
                            <%%= $link->text %>
                        </a>
                    </li>
                %% }
            </ul>
        </nav>
        %%= content
    </body>
</html>
% end

But we have one more thing we need to do before our site is ready.

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

Rather than walk through writing all these templates, let's simply copy
them from the Statocles default theme. To do this, we run the following
commands:

    statocles bundle theme default blog/index.atom.ep blog/index.rss.ep
    statocles bundle theme default site/sitemap.xml.ep site/robots.txt.ep

This will copy the specified files from the `default` theme to our theme
directory.

Now we have everything we need to build our site. Use the `statocles
build` command to test your site, which will be written to the
`.statocles/build` directory. Or use the `statocles daemon` command to
view your site in your web browser.

# Data Attributes

XXX

# Template Helpers

Template helpers are a pluggable bit of code that add some power to your
content. Statocles comes with a few built-in helpers, listed below.
Additional helpers can come from plugins. See [the development
guide](../develop/) for more information about building custom helpers.

## Includes

The `include` helper allows you to include another template into this
template. This can be useful when there are sections of template that
need to be duplicated in multiple places, or when you want to provide
a way for users of your theme to customize parts of it.

The `include` helper takes the file to include as an argument. In
templates, include paths are relative to the theme root directory.

For example, let's create an include that contains a standard
disclaimer. We'll put this include in the `include/disclaimer.html.ep`
file:

%= highlight html => begin
<aside><strong>Disclaimer:</strong> This blog is written by a trained
professional. Viewer discretion is advised.</aside>
% end

Now we can include this file in any template we wish, or, as mentioned
in [the content guide](../content/#Includes), any document we wish, like
so:

%= highlight html => begin
%%= include 'include/disclaimer.html.ep'
% end

### Include Parameters

The included template has access to all the template variables and
helpers of the parent template, like `$page`, `$app`, and `$site`, so we
could create an include that explains how to cite our page in academic
papers (like Wikipedia):

%= highlight html => begin
<p>To cite this article: <code>
    <%= $site->url( $page->path ) %>;
    <%= $page->author %>;
    <%= $page->date %>
</code></p>
% end

In addition to the variables from the parent template, we can pass
extra variables in the `include` helper. These variables override those
from the parent template.

So, we can create an image template that displays an image along with
a caption and a custom background color.

First, we create our include. Let's call it `include/image-bg.html.ep`.
Inside this template, we'll use the `$color` variable to control the
background color and have a default background color to `lightblue`. We'll
use the `$image_src` variable for the image's URL, and the `$caption`
variable for the image caption:

%= highlight html => begin
<div style="background-color: <%%= $color || 'lightblue' %>">
    <img src="<%%= $image_src %>" />
    <p><%%= $caption %></p>
</div>
% end

Now we can pass in this data using the `include` helper:

%= highlight html => begin
<%%= include 'include/image-bg.html.ep',
        image_src => '/images/logo-1984.jpg',
        caption => 'Our logo in the year 1984',
        color => 'grey',
%>
% end

The final rendered HTML will look like:

%= highlight html => begin
<div style="background-color: grey">
    <img src="/images/logo-1984.jpg" />
    <p>Our logo in the year 1984</p>
</div>
% end

### Default Includes

The default Statocles themes come with the following default includes
which you can customize:

* `site/head_after.html.ep`
    * This include comes immediately before the closing `</head>` tag
      and allows additional scripts and stylesheets.
* `site/navbar_extra.html.ep`
    * This include is inside the header navigation bar, and allows for
      custom icons and links.
* `site/header_after.html.ep`
    * This include comes immediately after the page header, which
      includes the main navigation.
* `site/sidebar_before.html.ep`
    * This include is at the top of the sidebar.
* `site/footer.html.ep`
    * This include is located in the page footer.

These files are not overwritten when using `statocles bundle theme`, so
it is safe to edit these files.

## Markdown

The `markdown` helper allows you to render Markdown into HTML from
inside the template. The `markdown` helper takes a single argument, the
Markdown to render, and returns the rendered HTML, like so:

%= highlight html => begin
%%= markdown begin
* This list will be turned to HTML
* Because of the `markdown` helper
%% end
% end

This is very useful when it comes to data attributes. For example, we
can add a "byline" to our document that we can then display when
appropriate.

We add our byline in the document header under the `data` attribute:

%= highlight yaml => begin
---
data:
    byline: |-
        [Author Writerson](http://example.com)
        ([email](mailto:writerson@example.com)
        [twitter](http://twitter.com/authorwriter))
% end

And then we can render the byline Markdown in our template:

%= highlight html => begin
%%= markdown $page->data->{byline};
% end

## Highlight

The `highlight` helper adds syntax highlighting for code and
configuration blocks. This helper uses the optional
[Syntax::Highlight module from
CPAN](http://metacpan.org/pod/Syntax::Highlight). See [the Install guide
for instructions on installing optional dependencies](../install/).

XXX

# Content Sections

Content sections are an advanced feature of Statocles that allows
special content to be passed up through the templates that make up
a single page. For example, the document content can include some
content that will be then be used by the page template or layout
template. This makes it easier to do things like adding sections to the
layout sidebar or footer, but only on specific pages.

XXX

The default Statocles themes include content sections for `tags` and
`feeds` which allow the Blog app to list all of its tags and feeds,
respectively.

# See Also

* [The Install guide](../install)
* [The Config guide](../config)
* [The Content guide](../content)
* [The Develop guide](../develop)

