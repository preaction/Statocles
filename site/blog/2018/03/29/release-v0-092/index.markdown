---
status: published
tags:
  - release
title: Release v0.092
---

In this release:

## BREAKING CHANGES

* The API for deploy objects has changed. They now accept an arrayref of
  pages, not a store object to copy. This is an attempt to reduce the
  amount of filesystem operations Statocles needs to do during deploy
  (formerly it was once to build the site, then copy the whole site to
  the deploy).
* The `build` and `deploy` methods of the Site object have been removed.
  The code to build and deploy a site has been moved to the
  Statocles::Command::build and Statocles::Command::deploy respectively.
  Site objects now have a `pages` method to get all the pages for the
  site.

## Added

* Added new Statocles::Command system. The Statocles class is now the
  main entry point for the command-line application, which delegates to
  Statocles::Command subclasses. This makes building custom commands
  possible.

[More information about Statocles v0.092 on MetaCPAN](http://metacpan.org/release/PREACTION/Statocles-0.092)
