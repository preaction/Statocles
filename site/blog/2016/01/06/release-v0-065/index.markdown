---
tags: release
title: Release v0.065
---

A few bugfixes in this release:

* The syntax highlighter now always renders `<pre>` and `<code>` tags to
  ensure proper display. This fixes problems with the Markdown parser
  interfering, and also with whitespace not being honored in the HTML.

* The site build is now more constant, so if no content changes, no
  deploy will be performed. Previously, due to sorting issues and
  using the current date/time, a site could be built 3 times and create
  3 new deploy commits. Now, only when real, actual content changes will
  a deploy occur.

  This change required a theme change, so be sure to re-bundle your
  themes.

Full changelog below...

---

* [fix list of bundled plugins](https://github.com/preaction/Statocles/commit/803c76347b0f33cb258ada6d82aa71c655eb1996)
* [add recent features to the feature list](https://github.com/preaction/Statocles/commit/b67a5a0740f7347df6c1b3d4409c326c2d2d6593)
* [fix atom feed updated time to be more accurate](https://github.com/preaction/Statocles/commit/af9a9a15332a8eb6b58af1a9aac98ebb1be3ed08) ([#430](https://github.com/preaction/Statocles/issues/430))
* [fix list page date to be max of all pages in list](https://github.com/preaction/Statocles/commit/60770940182ab9c5a9dc3743b6fe1b16d5d7de95) ([#430](https://github.com/preaction/Statocles/issues/430))
* [allow coercing Time::Piece from date/time strings](https://github.com/preaction/Statocles/commit/54f47036df005159e7a36ecbacfd01ea76f7b7c7)
* [fix no order in sitemap causing spurious commits](https://github.com/preaction/Statocles/commit/2213dcbf3491abe2e82f6d5b69a3399c0c6c053f) ([#430](https://github.com/preaction/Statocles/issues/430))
* [update theme from statocles default](https://github.com/preaction/Statocles/commit/8e86db96abca0a61ad254775a780286497088f51)
* [fix highlight breaking with Markdown code blocks](https://github.com/preaction/Statocles/commit/a2bafe6dcae91c22af8f4846505527e96e356011) ([#427](https://github.com/preaction/Statocles/issues/427))
* [fix test not running because of misspelled module](https://github.com/preaction/Statocles/commit/d0a41923b7cac887c92430a6ff0b672c8dfda8fd)
