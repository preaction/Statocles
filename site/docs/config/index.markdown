---
title: Statocles Config
---

This guide will walk you through configuring a Statocles site. Statocles is
configured with a YAML configuration file, usually called `site.yml`. This file
configures one or more sites, each with their own names, URLs, applications,
themes, and deployment targets.

# Site Create Command

To make configuring a site easier, Statocles comes with a `statocles create`
command, which will walk you through setting up a simple site. To use the
`create` command, open a terminal and run `statocles create <site>` where
`<site>` is the domain name of the site you want to create (say,
`www.example.com`). Statocles will create a directory for your site, ask you
some questions about the site you're trying to create, and then create the site
config for you and populate it with some initial content.

Once the create command is complete, see the rest of this guide for more
customization options, or [the content guide](../content) for how to get
started editing your site's content.

# Site From Scratch

If you want to forgo the site creator, you can create a site config from
scratch with a text editor. Create a directory for your site, say
`www.example.com`. In this directory, create a file called `site.yml`. This
will be our configuration file, and is the default configuration file name for
Statocles.

## YAML

Statocles configuration files are written in YAML, a human-readable language
for both simple and complex data structures.

The most common construct in the configuration YAML file is a "dictionary" or
"hash". This is made up of names (keys) that refer to values. The key and the
value are separated by a colon, like so:

    name: Doug Bell
    email: doug@example.com

So here we define a dictionary that has two keys. The "name" key is set to
"Doug Bell" and the "email" key is set to "doug@example.com".

Dictionaries can be nested. That is, the value of a dictionary key can be
another dictionary. YAML uses indentation to build nested data structures, like
so.

    author:
        name: Doug Bell
        email: doug@example.com
    status: draft

This dictionary also has two keys, but this time, the "author" key has a value
that contains another dictionary, and this inner dictionary has our name and
e-mail address.

Invalid indentation is a common problem in YAML files, so Statocles tries to
detect the errors coming from the YAML parser to advise you about what could be
wrong.

In addition to dictionaries, YAML also supports lists (or arrays), which are
sequences of values. To define a list, we use a dash "-" followed by a space.

    - http://example.com/bootstrap.css
    - http://example.com/style.css

Here we defined a list with two elements, URLs to some CSS files we're going to
use.

Like dictionaries, lists can contain other lists. On top of that, lists can
contain dictionaries and dictionaries can contain lists.

    links:
        stylesheet:
            - /bootstrap.css
            - /style.css
            - href: print.css
              media: print

Here we have a dictionary with a single key "links" that contains a dictionary
with a single key "stylesheet" that contains a list of three items. The first
two items in the list are simple strings, and the third is a dictionary with
two keys (href and media) with string values.

There are some other YAML constructs that will be useful when writing Statocles
config files:

Strings can wrap to the next line as long as the indentation is right.
Additionally, you can use `-|` or `-<` to explicitly say you're doing a
multiline string.

You can make single-line lists using `[ ... ]` and single-line dictionaries
using `{ ... }`.

For more info on YAML, see <http://yaml.org>


## The Config File

The Statocles configuration file consists of a collection of objects, each with
a given name. The main site object has the name `site`. A blog application
could have the name `blog`.

Each object has its own set of configuration, which is detailed below, but
every object looks approximately the same: A YAML dictionary, with a special
key `$class` which denotes what type of object it is. These classes will be
explained below, but an example `site` object could look like this:

	site:
		$class: Statocles::Site
		title: My Blog
		base_url: http://example.com

This block of configuration creates an object named "site". This object has a
class of "Statocles::Site", which makes it our main site object. Then we give
it a title of "My Blog" and a base URL of "http://example.com".

<aside>
For Developers, this configuration file uses [the Beam::Wire
module](http://metacpan.org/pod/Beam::Wire). Anything Beam::Wire is capable of
can be done in Statocles to customize how your site is generated.
</aside>

## Site Basics

The `site` object is the main object which represents our entire site. This
object contains all the site-wide information, applications, and theme. The
simplest informational attributes that the site object contains are also some
of the most important: The title, and the site's base URL.

### Title

	site:
		$class: Statocles::Site
		title: My Site Title

The site `title` attribute will appear in every page's `<title>` tag, and can
be used in other places as well.

### Base URL

	site:
		$class: Statocles::Site
		base_url: http://example.com/mysite

The `base_url` attribute will help Statocles create full URLs when it needs to,
usually when building feed files. The base URL must contain a domain
(`http://example.com`), and may contain a path (`/mysite`) if your site does
not have complete control of the domain. Statocles will use the base URL path
to rewrite all the URLs in the site, so you can move your site to different
places just by changing the base URL.

## Basic content

Most of a site's content will come from the Markdown, HTML, image, CSS,
JavaScript, and other files you put in your site's directory. This content is
handled by the "Basic" app. Applications are covered in detail later, but for
the sake of this section: An application uses the content you write to create
the site's pages. The Basic app simply reads all the content it can find and
copies it into the site, additionally converting Markdown into HTML.

To add an application to our site, we need to create a new object. Each object
needs a name (we'll call this one "basic_app") and a class (the Basic app class
is "Statocles::App::Basic"). 

The basic app also needs a directory for its files. Since we want our site to
pick up any file from anywhere in our site directory, we'll set our directory
to ".", which is the current directory, the same directory our config file is
in, and the root directory of our site. This directory is also known as the
application's "store", the storage location for all the app's content. 

Finally, the basic app needs a base URL. Since our app's content is coming from
the root of our site, we probably want our app's base URL to be the root of our
site, "/". This base URL will be added to the content's path, and then the
site's base URL will be added to that to create the full URL to the content.

	basic_app:
		$class: Statocles::App::Basic
		store: "."
		base_url: "/"

Once we have our basic_app object, we need to add it to our site object. The
site object has an `apps` attribute that contains a mapping of apps to names.
These names are used when accessing the app from the command-line (app commands
are covered in [the content guide](../content)). Each app must have a unique
name. For consistency, we'll give our basic app the name "basic". Inside the
site apps attribute, we give a reference to our `basic_app` object using the
`$ref` directive.

	site:
		$class: Statocles::Site
		apps:
			basic:
				$ref: basic_app

With `$ref`, we can separate our objects so that they're easier to read and
configure. We'll be using this a lot.

Now we have a site that can change basic Markdown into HTML, and will copy any
existing HTML, images, CSS, and JavaScript into our site.

## Simple Blog

The Blog application does some extra things, different from the Basic app: In
addition to copying images, HTML, CSS, and JavaScript files, it also creates a
list of your blog posts, RSS and Atom feeds for your blog, and a set of tag
pages and feeds to organize your blog posts into categories. The blog app also
enforces some requirements for your posts: They must all be organized in
directories like `/YYYY/MM/DD/post-title`, with the year, month, and day of the
post appearing in the path. This allows the blog to organize your posts by
date, so the most recent posts are shown first.

To add a blog app to our site, we must create another object. Similar to how we
named the basic app before, we'll call this object `blog_app`. The class of the
blog app must be `Statocles::App::Blog`, and like the basic app, we require a
"store" for the content of our blog (we'll use "blog", but "\_posts" is another
possibility), and a base URL for our blog (we'll use "/blog").

	blog_app:
		$class: Statocles::App::Blog
		store: "blog"
		base_url: "/blog"

This will get us a basic blog app with all of its default features. In-depth
coverage of other blog features continues below.

Now that we have the object, we add it to our site's `apps` attribute using the
`$ref` directive like before. This time, we'll give our blog app the name
"blog". 

	site:
		$class: Statocles::Site
		apps:
			basic:
				$ref: basic_app
			blog:
				$ref: blog_app

Now our site has a blog. New blog posts can be easily added using the
`statocles blog post` application command, covered in [the content
guide](../content).


## Index Page

Now that we've got some applications, we need to choose what our index page
will be. The index page is the main home page of the site. The site `index`
attribute allows us to set a path. The page located at this path will be used
as our index page. As Statocles builds the site, the path of the index page
will be changed to the site root, and every link to our index page will be
fixed to link to the site root.

For example, if we want to use our blog app as our home page, we could set our
`index` attribute to the blog app's `base_url`:

	site:
		$class: Statocles::Site
		index: /blog

If instead we want to use a regular page whose content lives in
`home.markdown`, we could set our `index` attribute to `/home.html`, which is
the page that will be created by our `home.markdown` file.

If our blog has a tag called "robots", we could choose to use that tag as an
index page by setting the `index` attribute to `/blog/tag/robots`. The final
`/index.html` is optional.

## Theme

Now we need a theme. The theme is a collection of templates, CSS, JavaScript,
and images which control how our site looks. Full details on what a theme is
and how to customize your theme are available in [the theme guide](../theme).

For now, we'll use the default theme that comes with Statocles. The default
theme is a minimal, basic blue theme using [the Skeleton CSS
library](http://getskeleton.com) with some Statocles widgets and modifications.

We add our theme to our site object using the site object's `theme` attribute:

	site:
		$class: Statocles::Site
		theme: '::default'

The default themes that come with Statocles are:

* ::default
	* A simple, minimal theme using the Skeleton CSS library
* ::bootstrap
	* A simple theme using the Bootstrap CSS library

The leading `::` is special and means to use a default theme. If you want to
use a custom theme, you can simply use the theme's path, like so:

	site:
		$class: Statocles::Site
		theme: 'site/theme'

All the themes that come with Statocles have the same set of optional features
which are enabled by data attributes on the site object (covered below).
Customizing your theme is handled in [the theme guide](../theme).

## Deploy

Finally, we should have a way to deploy our site. You can skip this if you're
just trying Statocles out, but the `create` command builds a deploy, so we will
here as well.

Like an application, a deploy is an object. So let's create an object named
`deploy`. Like applications, there are different kinds of deploy objects we can
create. The File deploy simply copies our site to another directory on the same
machine, and the Git deploy uses a Git repository to deploy our site (like
[Github Pages](http://pages.github.com)).

For now, let's create a File deploy.

XXX

More details on deploys are below.

## Complete Minimal Site

Here's the complete, minimal site configuration file we created above. Feel
free to copy this and edit it for your own use.

	site:
		$class: Statocles::Site
		title: My Blog
		base_url: http://example.com
		theme: '::default'
		index: /blog
		apps:
			basic:
				$ref: basic_app
			blog:
				$ref: blog_app
		deploy: site_deploy

	basic_app:
		$class: Statocles::App::Basic
		store: "."
		base_url: "/"

	blog_app:
		$class: Statocles::App::Blog
		store: "blog"
		base_url: "/blog"

# Site Object

Above, we created a complete, but minimal site object. Let's go back and
see how to customize our site further.

The site object is the main part of our configuration. As such, the site
configuration effects the entire site. There are a lot of options
available, but not all will apply, so don't worry. If you don't
understand something, feel free to [ask us about it in IRC]().

## Basic Attributes

## Navigation

## Links

## Images

## Templates

## Data Attributes

### Disqus

### Google Analytics

# Applications

## Common Attributes

## Basic App

### Templates

## Blog App

### Templates

## Perldoc App

### Templates

# Plugins

# Deploy
