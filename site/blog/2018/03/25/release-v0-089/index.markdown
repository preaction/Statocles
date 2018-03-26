---
tags: release
title: Release v0.089
---

This release should have fixed all the bugs preventing Statocles from
working on Windows, though you may need to force install some of the
prerequisites.

In this release:

## BREAKING CHANGES

* Page objects now use Mojo::Path objects to define their paths. This
  fixes problems that prevented Statocles from working on Windows.
  Thanks [@mohawk2](http://github.com/mohawk2)!
* Most Statocles::Store methods have been removed in favor of a single
  iterator that returns objects (either Statocles::Document objects for
  known Markdown files, or Statocles::File objects for all other files).
  This makes it easier to mock a Store for testing and to, in the
  future, allow for different document types.
* We've removed the ability to define the `class` metadata in documents.
  This may be replaced with a map of file extension to document class in
  a later release.

## Fixed

* Fixed multiple bugs and test failures on Windows. Thanks
  [@mohawk2](http://github.com/mohawk2)!
* Slightly improved test performance by testing page objects without
  rendering HTML

[More information about Statocles v0.089 on MetaCPAN](http://metacpan.org/release/PREACTION/Statocles-0.089)

