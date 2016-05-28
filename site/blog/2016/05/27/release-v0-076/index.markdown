---
tags: release
title: Release v0.076
---

A couple bugfixes in this release:

* Links on the index page with full URLs are no longer rewritten
  incorrectly. This was a regression from
  [#345](https://github.com/preaction/Statocles/issues/345).
* Using `statocles deploy --clean` with a Git repository when the
  content and the deploy are on the same branch is no longer allowed.
  This protects against deleting all the source content and templates.

Full changelog below.

---

* [fix index links with full urls being rewritten](https://github.com/preaction/Statocles/commit/ef8835599641971fbe486438edb9c70444c8b079)
* [move default post info to app attribute](https://github.com/preaction/Statocles/commit/f91fae37617b17cf6d3cd05b7aa0ba47a88f35d9) ([#163](https://github.com/preaction/Statocles/issues/163))
* [fix --clean destroying all content in git repo](https://github.com/preaction/Statocles/commit/bc9d84f9ae0494ad6cd9be696dfcfe175f65bb70) ([#491](https://github.com/preaction/Statocles/issues/491))
