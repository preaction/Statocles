---
title: Managing Content
---

# Managing Content

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

You can see the list of attributes you can set on a document in [the
Statocles::Document documentation]().

## Content

The main content of the document, after the YAML header, is made of Markdown.
HTML can be painful to write, with opening tags and closing tags and formatting
tags and making tags in order and adding tags for style purposes and other
pain. Worse, it's hard to read the HTML source (and getting worse all the
time), so the only practical use one can get out of HTML is after it is
rendered in the browser.

Markdown is different. Instead of tags, Markdown uses special characters (like
`*`, `_`, `#`, `[`, `]`, `(`, and `)`) to perform formatting tasks. For
example:

* `*word*` means bold (`<b>word</b>`)
* `_word_` means underline (`<u>word</u>`)
* `[text](http://example.com)` creates a link (`<a href="http://example.com">text</a>`)
* `*` followed by a space on the beginning of a line starts an unordered list (`<ul>`)
* `#` is a first-level heading (`<h1>`), `##` is a second-level heading (`<h2>`), `###` is a third-level heading (`<h3>`), etc...

The full rules of Markdown formatting can be found on John Gruber's website.

XXX

## Content Sections

XXX


