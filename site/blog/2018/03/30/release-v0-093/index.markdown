---
status: published
tags:
  - release
title: Release v0.093
---

**This release resolves a critical issue in v0.092 that prevented it
from being able to deploy sites. If you downloaded v0.092, please
upgrade to v0.093.**

In this release:

## BREAKING CHANGES

* Fixed deploy objects failing to find necessary content during deploy.
  When deploying a site, we need to copy the entire site to a temporary
  directory first, because the deploy might lose access to the templates
  and other source files (if, for example, the site is deployed to
  a different git branch). This means the deploy API has changed again
  to take a path, not a list of pages. The deploy copies all the files
  from the path and then does what it needs.

[More information about Statocles v0.093 on MetaCPAN](http://metacpan.org/release/PREACTION/Statocles-0.093)
