---
tags: release
title: Release v0.042
---

A slow week, but some needed features:

The LinkCheck plugin now supports an `ignore` attribute, in case there are
links that aren't managed by Statocles (like having Github project links in a
Github user/organization site).

A new `before_build_write` event was added to the Site object, so that plugins
can edit pages after the App creates them, and even add pages to the site.

The Site object now has full control over the Markdown object that turns
Markdown into HTML, which lets you use the other attributes of
[Text::Markdown](http://metacpan.org/pod/Text::Markdown), or even use
[Text::MultiMarkdown](http://metacpan.org/pod/Text::MultiMarkdown) or any
object that exposes a `markdown` method.

Full changelog below:

---

* [add markdown attribute to the Site object](https://github.com/preaction/Statocles/commit/ab1c87ee34b55a3f411604e2eb760c39096e3864) ([#258](https://github.com/preaction/Statocles/issues/258))
* [add ignore patterns to LinkCheck plugin](https://github.com/preaction/Statocles/commit/d2d98bbd25a75866a829c5bd5010ba6aa6b4528c) ([#272](https://github.com/preaction/Statocles/issues/272))
* [add before_build_write event for site object](https://github.com/preaction/Statocles/commit/fd745999e44dae83f91072edb071d45820f46d61) ([#279](https://github.com/preaction/Statocles/issues/279))
