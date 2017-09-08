---
tags: release
title: Release v0.085
---

In this release:

* Added the "dom" attribute to Statocles::Page. This caches the parsed
  HTML for the multiple transformations that must be performed.
  Hopefully this will speed up performance a little bit.

* Added JSON frontmatter support. Now if the first character of
  a document is a `{`, the frontmatter will be treated as JSON. JSON can
  be a single line (the `}` end bracket must be at the end of the line)
  or multiple lines (the `}` end bracket must be on a line by itself).

[More information about Statocles v0.085 on MetaCPAN](http://metacpan.org/release/PREACTION/Statocles-0.085)
