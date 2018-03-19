---
tags: release
title: Release v0.088
---

In this release:

## Added

* Added next_page/prev_page attributes to list pages. These provide
  better access to the page data like title to make better links for
  users. The existing next/prev attributes only held paths, which made
  finding this information more difficult. Thanks
  [@jberger](http://github.com/jberger)! [[Github
  #555]](https://github.com/preaction/Statocles/issues/555)
* Allow Link trees in navigations to support multi-level navigations.
  Thanks [@jberger](http://github.com/jberger)! [[Github
  #553]](https://github.com/preaction/Statocles/issues/553)

## Fixed

* Fixed anchor-only links on the index page being rewritten to point to
  the wrong page. Thanks [@jberger](http://github.com/jberger)! [[Github
  #554]](https://github.com/preaction/Statocles/issues/554)
* Moved some common attributes into a role to fix API differences
  between Document objects and Page objects. There is a lot more cleanup
  to be done in this regard, and we'll be doing that before pushing out
  v1.00.
* Fixed problems running the user's editor when there are spaces in the
  path. Thanks [@mohawk2](http://github.com/mohawk2)! [[Github
  #557]](https://github.com/preaction/Statocles/issues/557)
* Fixed some test failures with running the user's editor on Windows
  systems. Thanks [@mohawk2](http://github.com/mohawk2)! [[Github
  #557]](https://github.com/preaction/Statocles/issues/557)
* Removed some useless editor error states that were causing spurious
  test failures for no good reason.

[More information about Statocles v0.088 on MetaCPAN](http://metacpan.org/release/PREACTION/Statocles-0.088)
