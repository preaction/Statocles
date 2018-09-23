---
title: Develop Statocles Plugins and Apps
---

Statocles is, at its heart, a content management system. As such, it has
a few places to plug in your own functionality with custom Perl code.
You can write simple plugins to respond to events during content
generation or add new functions to your site's templates. You can write
new applications to manage the content differently. You can create
custom document classes to give a content author richer data structures
for specific types of site content. And you can write custom deploy
modules to deploy your site into your production environment.

## Overview

Statocles works content through various steps. First, a document is read
from the filesystem. Then, an application adds the document to one or
more pages, attaching templates from the theme. Finally, the site
collects all the pages, writes out the rendered HTML, and deploys the
site.

### Workflow

Fundamentally, the types of entity are:
- web page: can be represented in POD, Markdown, raw HTML
- asset: (CSS, JS, image) can be part of a theme, or part of individual web page
- high-level theme: way of showing information to the world, probably a web site i.e. collection of individual web pages
- static web site: an end product, being a set of web pages viewable in a browser, typically hyperlinked to each other, and styled to taste
- template: a convenient way to process input data (e.g. as might be in a Markdown file) into output (e.g. HTML)
- processing plugin: a way to encapsulate a stage of information processing

To categorise these entities, the first four can be considered "values", and the last two as "functions" that turn values into other values.

Statocles's "workflow" of information, using only the above types of entity, is as follows:
- user creates/inserts a new web page, optionally with additional assets - currently a Markdown disk file maybe made with `statocles` command
- a high-level theme applies a high-level theme, consisting of templates, possibly with processing plugins to create a static web site
- the static web site is deployed to something end-users can see

The current implementation described below is a concrete way of dealing with these entities, and implementing this workflow.

### Documents

Documents are the content the user writes, which consists of Markdown
with a YAML metadata section on top. See [the content guide]() for
details about writing content. Documents are read by a store object,
which takes a path. Applications that use documents (most applications)
require a path in which to store their documents.

### Pages

Each page object is a single page in your site. Many pages are built
using documents, but other pages have CSS files, JavaScript files,
images, video, and other content. Applications also create special pages
like index pages, blog post lists, tag lists, and syndicated content
feeds.

The page object handles the rendering of data to HTML, if necessary. To
do this, the page makes use of templates that are chosen by the
application (or the document). For more information about templates, see
[the theme guide]().

### Apps

An application is the component that takes documents and builds pages.
This is the actual content management object in Statocles.

Each application may use documents a little differently: The Basic app
simply copies the documents into page objects, but the Blog app treats
documents as blog posts and renders index pages and feeds. A Calendar
app could treat documents as events and render monthly views and
calendar feeds. A Gallery app could build index pages from the images in
a directory structure.

### Site

The site object collects a set of applications into a site. This is the
main object in Statocles, but also the least important for content
management. When commanded, the site will collect the pages from each
app, designate a main site index page, run any desired plugins, and
deploy the site.

### Deploy

The Deploy object handles deploying the site to production. By default,
deploy plugins are provided for copying the site to another directory,
or using git to push the site to another system (for example, Github
Pages).

## Plugins

A plugin is the simplest way to add custom code to Statocles. Plugins
are [configured on the site object](../config/#Plugins) and can add
event handlers, which hook into the site build and deploy process, and
template helpers, which add new functions that templates and content can
use.

A plugin class can be any kind of class (Plain old Perl object, Moo,
Moose, etc...), but it must have a `register` method which is called on
an instance of the class. This method is where you add your event
handlers and template helpers. The basic shell of a plugin looks like
so:

    package Statocles::Plugin::SayHello;
    use Moo;
    sub register {
        my ( $self, $site ) = @_;
        ### Register event handlers and template helpers here
    }
    1;

The `register` method gets, as an argument, the current site object,
which it can hold on to if it needs to, or throw away if it wants. To
register event handlers and template helpers, see below.

### Event Handlers

An event handler allows you to respond to an event in the site build
process. This allows you to modify page content as it flows through
Statocles, or add and remove pages as you need to. Plugins also allow
you to automate sanity checks, thumbnail generation, and other things
you don't want to worry about while you're producing content. Some
examples of behavior best implemented by plugins include:

* Minifying JavaScript and CSS files and updating links to the minified
  versions
* Compiling LESS and SASS files and updating links to the compiled CSS
* Compiling ES6 JavaScript or TypeScript into ES5 JavaScript
* Creating image source sets (srcset) for responsive images
* Inlining small JavaScript and CSS files for faster loading
* Checking for broken links (the [LinkCheck plugin](/pod/Statocles/Plugin/LinkCheck/))
* Checking spelling and grammar
* Checking validity of HTML and CSS

The most-common events are located on the Site and App objects.

The Site object has these events:

* `collect_pages` - Fired after all pages have been collected. Use this to
  edit page content or add/remove pages from the site
* `build` - Fired after all the pages have been rendered and written to
  the site's build directory.

Every App object has these events:

* XXX

There may be other events available on other objects, so check the
class's documentation for more information.

Statocles uses the
[Beam::Emitter](http://metacpan.org/pod/Beam::Emitter) class to do event
handling. To register an event, use the `on( $event_name, $callback )`
method.

    sub register {
        my ( $self, $site ) = @_;
        $site->on( "build", sub { say "Hello!" } );
    }

The site's event handlers get
a [Statocles::Event::Pages](/pod/Statocles/Event/) object
containing an arrayref of the pages the site has built so far. Modifying
this arrayref or the objects inside will modify the site. For example,
XXX

XXX Add example of modifying content

When modifying content, it's usually better to change the variables and
documents that make up the content than to work with the rendered HTML.

When using event handlers, the
[Mojo::DOM](http://mojolicious.org/perldoc/Mojo/DOM) object is useful to quickly
parse HTML. Since Statocles depends on it, you can be sure it's
available for your plugin. See [the LinkCheck
plugin](/pod/Statocles/Plugin/LinkCheck/) for an example
of using Mojo::DOM.

### Template Helpers

Template helpers add new functions to templates that can be used in
content documents or themes. These functions can help with content
generation, [adding highlighting to code sections]() or generating image
thumbnails. There are a number of helpers built-in to Statocles. See
[the theme guide](../theme/#Helpers) for more information.

To make your own helper, you add a subroutine to the site's theme
object. Whatever the helper returns will be placed into the template.
For example, to say hello:

    package Statocles::Plugin::Hello;
    use Moo;

    sub register {
        my ( $self, $site ) = @_;
        $site->theme->add_helper(
            say_hello => sub {
                return "Hello, World";
            },
        );
    }

Now anyone can call our `say_hello` helper in their content document or
in their theme templates, like so:

    %%= say_hello

Helpers get two arguments by default (XXX). The first argument is the
plugin instance. The second is a hash reference of the data passed in to
the template, which contains at least the following keys:

    page: The current page object (for theme templates)
    doc: The current document object (for content documents)
    app: The current application object
    site: The current site object

So, using this we can create a helper that says the title and last
updated date of the current page:

    package Statocles::Plugin::Tagline
    use Moo;

    sub register {
        my ( $self, $site ) = @_;
        $site->theme->add_helper(
            add_tagline => \&add_tagline,
        );
    }

    sub add_tagline {
        my ( $self, $args ) = @_;
        return $args->{page}->title . " last modified " . $args->{page}->date;
    }

Finally, we can pass our own arguments to helpers. These arguments will
be passed in at the end of our helper's argument list. So, let's create
a helper that prints an unordered list.

    package Statocles::Plugin::List;
    use Moo;

    sub register {
        my ( $self, $site ) = @_;
        $site->theme->add_helper( ul => \&ul );
    }

    sub ul {
        my ( $self, $args, @items ) = @_;
        return '<ul>' . join( "", map { "<li>$_</li>" } @items ) . '</ul>';
    }

And we use our new `ul` helper by passing in the items we want to list, like so:

    %%= ul "Item one", "Item two", "Item three"

Which produces the HTML:

    <ul><li>Item one</li><li>Item two</li><li>Item three</li></ul>
