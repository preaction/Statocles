---
tags: release
title: Release v0.075
---

It's been a while, but we have a bunch of changes, and the start of some
new documentation.

Some deprecations this time, in the continuing run-up to v1.0:

* Document data attributes now must be hashes. This makes all the data
  attributes (document, page, site, application) consistent and easier
  to manage.
* The default layout is now `layout/default.html.ep`, not
  `site/layout.html.ep`. Now that layouts are bundling multiple themes,
  having a specific directory is better.

The new features include:

* Content sections. Templates and documents can now define content that
  can be used later in the layout. This allows applications with tags or
  feeds, for example, to add content to the layout header, sidebar, or
  footer.
* The `bundle theme` command now allows you to specify which files you
  want to bundle. This makes it easy to copy only certain things from
  the default theme. This is helpful for the templates that don't change
  much, like the feed templates, robots.txt, and sitemap.xml templates.
* The [site object](/pod/Statocles/Site) now has a [`templates`
  attribute](/pod/Statocles/Site/#templates) which allows you to
  override the site's default layout, `sitemap.xml`, and `robots.txt`.
* The [document page `sections` method](/pod/Statocles/Page/Document/#sections)
  now allows for indexes as arguments. This makes it easier to use
  document sections in template.

And some bugfixes:

* The [LinkCheck plugin](/pod/Statocles/Plugin/LinkCheck) now correctly
  handles relative links to parent directories (`..`).
* The LinkCheck plugin now warns about links with empty `href`
  attributes. This is technically legal, but is more likely a problem of
  not filling in the URL.
* The index page now properly handles relative links. Previously,
  relative links on an index page would be broken when the index gets
  moved to `/index.html`.

Finally, some new documentation is in development, starting with [a new
theme guide](/docs/theme). Please try it out and let us know if anything
isn't clear by [submitting a Github
ticket](http://github.com/preaction/Statocles/issues) or [telling us on
IRC](https://chat.mibbit.com/?channel=%23statocles&server=irc.perl.org)

Full changelog below.

---

* [allow indexes to the sections method](https://github.com/preaction/Statocles/commit/cf229ca5b990470a3794b28722515f56a4a7741e) ([#490](https://github.com/preaction/Statocles/issues/490))
* [move date parsing into document class](https://github.com/preaction/Statocles/commit/dfb1ef49a19e95341b0e2c26d1164667e97cd2f7) ([#392](https://github.com/preaction/Statocles/issues/392))
* [fix relative links on index page getting broken](https://github.com/preaction/Statocles/commit/4a31bed1e7ff7876a14d0c9397f889f95ee390ed) ([#345](https://github.com/preaction/Statocles/issues/345))
* [add tests for relative links on index page](https://github.com/preaction/Statocles/commit/ffa5a099cd3f37da22e1e48cf259cd37e3438d48) ([#345](https://github.com/preaction/Statocles/issues/345))
* [move default layout to layout directory](https://github.com/preaction/Statocles/commit/c6f690f6aa5688e943923b2037793e61405cae13) ([#486](https://github.com/preaction/Statocles/issues/486))
* [allow overriding the layout for the entire site](https://github.com/preaction/Statocles/commit/5db1737fb0193c8e681ca7a57135b925e39390bd) ([#312](https://github.com/preaction/Statocles/issues/312))
* [allow template overrides in the site object](https://github.com/preaction/Statocles/commit/92421b88e271cdda2695167c45d3e89a8a31614a) ([#312](https://github.com/preaction/Statocles/issues/312))
* [ignore hidden files in theme test](https://github.com/preaction/Statocles/commit/3efa057c215e63e01461ec9ee8373a62527c4c8b)
* [show the page list when count is wrong in tests](https://github.com/preaction/Statocles/commit/706c6cc3fdc6092fdecfba57ec0729139ead69e0)
* [warn about links with empty href destination](https://github.com/preaction/Statocles/commit/8fa1abde36cad5dabf0a5b30ff169f4f123ce2fb) ([#492](https://github.com/preaction/Statocles/issues/492))
* [fix linkcheck plugin marking all ".." as broken](https://github.com/preaction/Statocles/commit/ce0728dc40c69688d081bc337878336582ed116a) ([#488](https://github.com/preaction/Statocles/issues/488))
* [pass-through the document data attr to the page](https://github.com/preaction/Statocles/commit/a371e764baa13d6e5ac1ed7de16d87ffe6516747)
* [bundle theme to site theme directory only](https://github.com/preaction/Statocles/commit/3d74a5d70911cb659785e96a98df86aa77902f49)
* [allow bundling of specific files from a theme](https://github.com/preaction/Statocles/commit/66120dfbcf7b870d77b42a75bdeaf24cb6d83130)
* [deprecate document data attrs that are not hashes](https://github.com/preaction/Statocles/commit/dc7d8e8b43cb7aa76454969f0762a543828e0b1d) ([#417](https://github.com/preaction/Statocles/issues/417))
* [move content sections to page object](https://github.com/preaction/Statocles/commit/29e2c92746e1ef293df13231b8742e7bf88bacea)
* [add full-width layout template to remove sidebar](https://github.com/preaction/Statocles/commit/103cca972c751dcede6499dbb15280a385170467)
* [move sidebar to layout](https://github.com/preaction/Statocles/commit/38b19c1a92250c1fa7600c8c85b907d9796a7911)
* [add content sections to template helper](https://github.com/preaction/Statocles/commit/04f20a08a20273224445dfb9cb0670aebc110348) ([#416](https://github.com/preaction/Statocles/issues/416))
