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

Statocles works content through various steps. First, a document is read from
the filesystem. Then, an application adds the document to one or more pages,
attaching templates from the theme. Finally, the site collects all the pages,
writes out the rendered HTML, and deploys the site.

### Documents

Documents are the content the user writes, which consists of Markdown with a
YAML metadata section on top. See [the content guide]() for details about
writing content. Documents are read by a store object, which takes a path.
Applications that use documents (most applications) require a path in which to
store their documents.

### Pages

Each page object is a single page in your site. Many pages are built using
documents, but other pages have CSS files, JavaScript files, images, video, and
other content. Applications also create special pages like index pages, blog
post lists, tag lists, and syndicated content feeds.

The page object handles the rendering of data to HTML, if necessary. To do
this, the page makes use of templates that are chosen by the application (or
the document). For more information about templates, see [the theme guide]().

### Apps

An application is the component that takes documents and builds pages. This is
the actual content management object in Statocles.

Each application may use documents a little differently: The Basic app simply
copies the documents into page objects, but the Blog app treats documents as
blog posts and renders index pages and feeds. A Calendar app could treat
documents as events and render monthly views and calendar feeds. A Gallery app
could build index pages from the images in a directory structure.

### Site

The site object collects a set of applications into a site. This is the main
object in Statocles, but also the least important for content management. When
commanded, the site will collect the pages from each app, designate a main site
index page, run any desired plugins, and deploy the site.

### Deploy

## Plugins

## Apps

## Deploy

## Documents
