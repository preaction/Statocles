---
title: Home
---
<div id="index-banner">
<h1>Statocles <small>Static, App-capable Websites</small></h1>
</div>

Statocles is a minimal web content management system with a focus on easy editing
with any plain text editor.

## Features

* A simple format combining YAML and Markdown for editing site content.
* A [command-line application](/pod/Statocles/Command.html) for building,
  deploying, and editing the site.
* A simple daemon to display a test site before it goes live.
* A [blogging application](/pod/Statocles/App/Blog.html) with
    * RSS and Atom syndication feeds.
    * Tags to organize blog posts. Tags have their own custom feeds.
    * Post-dated blog posts to appear automatically when the date is passed.
* [Customizable themes](/pod/Statocles/Help/Theme.html) using a simple syntax
  of embedded Perl
* A clean default theme using [the Skeleton CSS library](http://getskeleton.com)
* SEO-friendly features such as [sitemaps (sitemap.xml)](http://www.sitemaps.org).

## Installing

Install the latest version of Statocles:

    curl -L https://cpanmin.us | perl - -M https://cpan.metacpan.org -n Statocles

## Getting Started

Build a basic site using [the Statocles Setup tutorial](/pod/Statocles/Help/Setup.html).

