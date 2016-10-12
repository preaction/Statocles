---
tags: release
title: Release v0.078
---

## Fixed

* Multiple blog posts on the same day are now ordered by their
  `date` attribute. This makes the ordering predictable and
  changable, instead of being ordered alphabetically [Github #512].
  There will likely be some configuration additions here in the
  future to make the date formatting fit the blog's post frequency
  and groupings.

## Other

* Ignore Pod::Weaver version 4.014. This version shipped with a bug
  that causes our tests to fail, likely causes weaving in the
  Perldoc app to throw a fatal error. You should downgrade to
  Pod::Weaver 4.013 (`cpanm Pod::Weaver 4.013`) or upgrade to
  Pod::Weaver 4.015 when that is released. [Github #513]

