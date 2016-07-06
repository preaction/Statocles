---
title: Managing Content
layout: layout/full-width.html
---

Statocles is a content management system. You give it content, and it manages
it by assembling a web site. This includes changing your Markdown into HTML,
adding your configured theme, running your helper functions, executing your
plugins, collecting your blog posts into lists, collecting your tags, and
building all your site's search metadata.

The purpose of Statocles and other content management systems is to automate
all the tedious tasks that can be automated so that you can simply write your
content. If you find yourself doing something repeatedly that you think should
be automated, [let us know on Github]() or [talk to us in chat]().

# Quick Start

Here's a quick introduction to managing content with Statocles. If you've used
other content management systems, start here. These topics will be covered in
greater depth in the rest of this guide.

Make sure you've [created your site using the config guide](../config) before
doing this quick start.

## Adding a new page

To add a new page to a Statocles site, we just need to create a new Markdown
file. Let's create a new page called "about.markdown", and add some information
about ourselves.

The first part of every document is a header, which is put between `---`
markers. Here is where we'll put our title and other metadata. See
[Header](#Header) below for an introduction to what other things can be put
here. For now, we'll just give our page a title:

    ---
    title: About Me
    ---

With our header done, we can add some content. Content is formatted using
Markdown, which mostly tries to do the right thing with natural text. Like many
other applications, Markdown lets us bold text using `*text*`. Let's write a
paragraph about ourselves.

    ---
    title: About Me
    ---

    A British tar is a soaring soul. As free as a mountain bird. Who
    never will fall down to a domineering frown or a dictatorial word.

To add links, Markdown has a special format: The text of the link goes
in square brackets and the URL goes in parentheses immediately after,
like `[text](url)`. We can also use `<URL>` to show the URL as
a clickable link. Let's add our e-mail address and a link to Twitter for
some contact information:

    ---
    title: About Me
    ---

    A British tar is a soaring soul. As free as a mountain bird. Who
    never will fall down to a domineering frown or a dictatorial word.

    E-mail: <doug@example.com>
    Twitter: [@preaction](http://twitter.com/preaction)

*Note*: Markdown does not treat single newlines as significant, so the
above will look like a paragraph. See [Content](#Content), below, for
more information on Markdown.

Once we save this file, it's part of our site.

## Adding a new blog post

But first, let's add a blog post announcing our new content. In addition
to simply adding Markdown files to our site, Statocles comes with
a `statocles` command to make managing content easier. These commands
will create the right directory structure, copy a document skeleton, and
open up our text editor so we can just start typing.

To create a blog post, we can run `statocles blog post`. When running
the command, we can specify the post's title, which Statocles will use
to create a blog post directory. If we have the `EDITOR` environment
variable set (a standard Unix-like environment variable), Statocles will
immediately open our text editor. If not, Statocles will create the post
and tell us where so we can open it ourselves.

So name our blog post "New About Page" and run `statocles blog post New
About Page`. Statocles will create a directory for our post using the
current date and the post title (something like
`/2016/07/02/new-about-page/index.markdown`). The blog creates entire
directories for every post so that posts can consist of multiple pages
and also contain images, scripts, and other files as needed. If we open
that file, or if Statocles opens it for us, the default blog post
skeleton will look like this:

    ---
    title: New About Page
    ---
    Markdown content goes here

Lets describe our new About page, and add a link to it.

    ---
    title: New About Page
    ---
    I've written a new [about me](/about.html) page for you to learn
    about me and get in contact!

Now we can close our editor. If Statocles opened our editor for us, it
will look at the post title and adjust the post directory if needed.

## Building the site

Now that we have some new content, and a blog post introducing that
content, let's build the site. The `statocles build` command will grab
our site content, create our HTML, and write it to the hidden
`.statocles/build` directory. The `.statocles` directory is important,
and should be mostly ignored, but you can examine `.statocles/build` to
take a look at your site.

The `build` process also runs any plugins you've configured. This can
include a broken link checker and other automated checks for a good,
valid website. Running the `build` command can be a good sanity check.
See [the config guide](../config) for how to configure automated check
plugins.

If you want to know what Statocles is doing during the build, you can
run `statocles build -v` for informational messages, and `statocles
build -vv` for debugging messages. This can be helpful if something's
wrong and you don't know what, or if you need to [ask for help on
Github]() or [ask for help in chat]().

## Testing the site

Instead of looking at the rendered HTML files, Statocles can run a small
web server to show your site locally. To view your site locally in your
web browser, use the `statocles daemon` command:

    $ statocles daemon
    Listening on http://127.0.0.1:3000

Once the daemon is running, open up your web browser to the URL, and
your site should appear. If anything looks wrong, you can quickly fix it
before deploying to production.

If you've installed the optional Mac::FSEvents module on OS X, changes
to your site will automatically be built while the daemon is running.

Like the `build` command, you can use `-v` and `-vv` to see extra
information about what the daemon is doing.

## Deploying the site

Once you've tested your site and everything looks good, you can deploy
it with the `statocles deploy` command. Running `statocles deploy` will
deploy your site with the configured deployment. See [the config
guide](../config) for more information about configuring deployment.

# Documents

The most common unit of content in Statocles is the Document. A document
is a text file consisting of an optional header of document attributes,
made of YAML, followed by the document's content, written in Markdown.

A Statocles site is made up of applications that read their documents
and produce HTML pages which can then be rendered. Statocles also allows
images, CSS, and JavaScript files to be placed anywhere.

## Header

The header is where document attributes are set. These attributes include:

* The title of the document
* The author of the document
* Tags, which are used to categorize the document
* Links to related documents
* What template the document should use
* What layout the document should use
* Additional CSS and JavaScript files this content needs
* Arbitrary data you might want to use in your theme
* Anything that isn't the document's content

These attributes are defined using YAML, which is a simple language for
organizing data into structures like lists (sequences of elements) and
dictionaries (named values). At its very basic, YAML is just a set of
`field: value` dictionary items, like so:

    ---
    title: My First Post
    author: Doug Bell
    ---

YAML always starts with `---` on a line by itself. Statocles also uses
`---` on a line by itself to denote the end of the YAML header. There is
only one YAML header per document, though some applications may use
additional YAML sections for their own purposes.

Since YAML is meant to create data structures, we can define, for
example, lists of tags. In a list, each item in the list is indented,
and begins with a "-" followed by a space.

    ---
    title: My Tagged Post
    tags:
        - post
        - tagged
        - first
    ---

And we can get more complex. For example, to define additional CSS
files, we need to create a dictionary of lists:

    ---
    title: My Styled Post
    links:
        stylesheet:
            - http://cdn.example.com/bootstrap.css
            - http://cdn.example.com/jquery-ui.css
    ---

Thankfully, this is about as complex as Statocles requires, but YAML allows
these data structures to be nested as deeply as necessary.

### Basic Attributes

Every Statocles document has some basic attributes:

<dl>
    <dt>title</dt>
    <dd>
        <p>The <code>title</code> attribute sets the document's title. This
        title will appear in the <code>&lt;title&gt;</code> tag and may
        appear automatically in the content itself (such as in the blog
        application).</p>

        <pre>---
title: What I had for lunch today
---</pre>

        <p>This is an important attribute, and should be defined in
        every document.</p>
    </dd>
    <dt>author</dt>
    <dd>
        <p>The <code>author</code> attribute defines the name of the
        author of the document. This will appear in the blog application
        as a simple byline. This attribute is optional.</p>

        <pre>---
author: Doug Bell (preaction)
---</pre>

    </dd>
    <dt>date</dt>
    <dd>
        <p>The <code>date</code> attribute lets you set the last
        modified date/time of the document in <code>YYYY-MM-DD</code> or
        <code>YYYY-MM-DD HH:MM:SS</code> format. This metadata is used
        to inform search engines of when the document last changed, for
        indexing purposes.</p>

        <pre>---
date: 2016-05-04
date: 2016-05-04 12:43:51
---</pre>

        <p><b>Note: </b> The blog application does not use this date to
        control the post order. Only the date in the post's path
        matters.</p>
    </dd>
    <!-- Document the status attribute when we start using it
    <dt>status</dt>
    <dd>
    </dd>
    -->
</dl>

### Tags

Every document can have one or more tags for categorization purposes. In
the blog app, posts are collected under tags for easy viewing. For
example, a food blog could tag recipes with their primary ingredients,
or a personal blog could be divided into sections based on different
subjects.

Tags can be added to a document with the `tags` attribute. The value
should be either a comma-separated list, or a YAML array, like so:

    ---
    title: Chicken Alfredo
    tags: chicken, cheese, pasta
    ---

    ---
    title: Chicken Alfredo
    tags:
        - chicken
        - cheese
        - pasta
    ---

Then, in the blog app, this post will appear in each of the three tags'
list view and feeds.

### Links

Links declare relationships from other URLs to this document. Using the
`links` attribute, we can add custom stylesheets and scripts to this
document, or we can define the canonical source (in case we're
aggregating or duplicating content available elsewhere on the web).

The `links` attribute contains one or more keys, which are how the links
are related, and an array of URLs or link attributes (such as `href` and
`text`). These are turned in to [Statocles link
objects](/pod/Statocles/Link), and have all the attributes that link
objects have.

For example, to declare some external stylesheets, we can use the
`stylesheet` key. In this key, we can simply define the URLs we want,
like this:

    ---
    links:
        stylesheet:
            - http://bootstrapcdn.com/3.2.1/css/bootstrap.min.css
            - http://bootstrapcdn.com/3.2.1/css/bootstrap-theme.min.css

Or we can explicitly define the link attributes:

    ---
    links:
        stylesheet:
            - href: http://bootstrapcdn.com/3.2.1/css/bootstrap.min.css
              type: text/css
              rel: stylesheet
            - href: http://bootstrapcdn.com/3.2.1/css/bootstrap-theme.min.css
              type: text/css
              rel: stylesheet

The `type` and `rel` attributes are optional here, but are shown for
demonstration.

Some links allow us to define `text` as well, like the `canonical` link,
which tells search engines to send users somewhere else when they search
for this page. In the blog app, this link text will appear and allow
users to click to view the content on the preferred site.

    ---
    links:
        canonical:
            - href: http://example.com/canonical
              text: The canonical source of this content

The default themes allow for the following link keys:

* `stylesheet` - Extra CSS files that should be added to this page
* `script` - Extra JavaScript files that should be added to this page
* `canonical` - The canonical source of this content, for search engines

### Images

Like links, the `images` attribute allows us to define related images,
such as a thumbnail or title image. Like links, images have a key which
describes how the image will be used, and either a URL or set of image
attributes (such as `src` and `title`).

For example, to add a title banner, we can use the `banner` key:

    ---
    images:
        banner:
            src: ./banner.jpg
            alt: A picture of clouds

The default themes allow for the following image keys:

* `icon` - The shortcut icon for this page

### Data Attribute

The `data` attribute is an extra place that allows you to put anything
you want. This is helpful for theme authors to add additional features,
or when using [content templates](#Content-Templates) to generate your
content.

The `data` attribute must be a hash, but you can put anything inside
that hash (arrays and more hashes are fine).

Using the data attribute, you could write a recipe's ingredients in your
data attribute, and have a template generate the right metadata. Or have
a list of people to display on the page. For examples, see the section
on [content templates](#Content-Templates), below.

The default Statocles themes do not use the `data` attribute currently,
allowing you to do as you please.

### Template / Layout

For greater flexibility, every document can declare its own custom
template or layout to override the one it would normally use. This
allows theme authors to provide multiple content templates and layouts
that can be used as needed.

The `template` key changes the content template, which is the template
that displays the content in the document. The `layout` key changes the
layout template, which handles everything surrounding the main content:
The site's header, footer, design, and other parts.

    ---
    template: blog/recipe.html
    layout: layout/full-width.html

The default Statocles themes include these optional templates you can
use:

* layout/full-width.html
    * This layout does not contain a sidebar, taking up the full width
      of the page.

## Content

The main content of the document, after the YAML header, is made of Markdown.
HTML can be painful to write, with opening tags and closing tags and formatting
tags and making tags in order and adding tags for style purposes and other
pain. Worse, it's hard to read the HTML source (and getting worse all the
time), so the only practical use one can get out of HTML is after it is
rendered in the browser.

Markdown is different. Instead of tags, Markdown uses special characters
(like `*`, `_`, `#`, `[`, `]`, `(`, and `)`) to perform formatting
tasks.  These formats include bolding, italicizing, creating headers,
lists, links, preformatted sections, quotes, and images. And, when
Markdown isn't enough, you can go back to using HTML to add `<aside>`,
`<figure>`, `<dl>`, and other tags.

### Emphasized Text

Markdown allows for easy indication of emphasized text. Text between
single asterisks `*` or underscores `_` is *emphasized* with a `<em>`
tag. Double asterisks/underscores is **strong emphasis** with
a `<strong>` tag.

### Code Text

Inline `code text` is surrounded by backticks `` ` `` and results in a `<code>`
tag.  Code text is automatically HTML escaped, so you can write raw HTML
inside backticks and it won't be processed as HTML.

You can also have code blocks which are simply indented by at least
4 spaces or 1 tab. Code blocks are surrounded by `<pre>` and `<code>`
tags.

    This is a code block, indented 4 spaces

### Headers

Headers are preceded by a number of hash `#` characters, one for each
level of heading. So, one `#` is an `<h1>`, two `##` is an `<h2>`,
three `###` is an `<h3>`, and so on up to 6.

    # Heading 1
    ## Heading 2
    ### Heading 3
    #### Heading 4
    ##### Heading 5
    ###### Heading 6

### Blockquotes

Blockquotes are paragraphs preceded by `>` characters and result in
a `<blockquote>` tag. Blockquotes can be nested, and can contain any
other Markdown content.

    > This is a blockquote across multiple lines. Each line can be
    > started with the `>` character, or you can be lazy and only start
    > the first line with a `>`.

    > > This is a nested quote, but it's short.

    > This second paragraph only has the `>` character on the first
    line, not any subsequent lines, because I'm lazy and my editor
    doesn't do it for me.

### Links

XXX

### Lists

XXX

### Images

XXX

### HTML

At any time you can use HTML if you need to have a tag that isn't
supported in Markdown, or if you need to add classes or IDs to your
content.

XXX

By default, content inside the HTML tag is not parsed as Markdown,
making it safe to use characters that would otherwise be processed. To
allow Markdown inside your HTML, use the `markdown=1` attribute:

    <p class="special" markdown=1>
    This paragraph is still parsed as Markdown, so *bold formatting*
    will still work!
    </p>

The Statocles default themes include custom formatting for the following
HTML5 tags:

* aside
* figure / figcaption

XXX

# Simple Content

How to create a new page

XXX

# Application Commands

How to create a blog post

XXX

# Images and Files

XXX

# Content Templates

XXX

# Content Sections

XXX

# See Also

* [The Install guide](../install)
* [The Config guide](../config)
* [The Theme guide](../theme)
* [The Develop guide](../develop)
