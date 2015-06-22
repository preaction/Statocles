---
tags:
  - release
title: Release v0.048
---

Here starts the road to v1.0! Some breaking changes in this release:

Statocles::Page::Feed is now removed. The functionality has been added to all
pages, and all the feed templates have been updated accordingly. This means you
must update your themes to grab the new feed templates.

To fix a long-standing bug with blog content not showing up correctly on the
list pages (index, tag lists), the
[Statocles::Page::ListItem](/pod/Statocles/Page/ListItem.html) class was added.
This class proxies another page and rewrites its content to survive intact
inside a list page.

Some minor things:

External perldoc links are now explicitly labelled as such with a
[FontAwesome](http://fontawesome.io) icon.

Some doc updates to start documenting the [App API](/pod/Statocles/App.html).

Full changelog below...

---

* [fix vim swap files being parsed as markdown](https://github.com/preaction/Statocles/commit/d87a00868efb382b1400f04edf6adc8c7dd019c7)
* [add ListItem page to wrap pages in a list page](https://github.com/preaction/Statocles/commit/eaa26fabcbe82845ca9246d51b92c5dc21772b60) ([#298](https://github.com/preaction/Statocles/issues/298))
* [add basename and dirname to Page objects](https://github.com/preaction/Statocles/commit/97c17e53049acdd095a4654111b09b0c875891d5)
* [fix templated content not rendered in blog list](https://github.com/preaction/Statocles/commit/4916a9cae26f488e81ac16a81576b7c5b3f4e703) ([#320](https://github.com/preaction/Statocles/issues/320))
* [remove Statocles::Page::Feed](https://github.com/preaction/Statocles/commit/014ec402ce8c2698e9aa81f846f5f75a96ae8275) ([#329](https://github.com/preaction/Statocles/issues/329))
* [allow Path::Tiny objects in link href attrs](https://github.com/preaction/Statocles/commit/eb1750d2d795d4ec4aa11de294860bac1fa9deb9)
* [fix double / when building App urls](https://github.com/preaction/Statocles/commit/b656a42d764c3ae57f25a248c3a941f5d7ca95c5)
* [make it easier to deal with one page link](https://github.com/preaction/Statocles/commit/285ca9fd02dd242a26e3a5ed0c8d37277c7b33c5)
* [add type to base Page role](https://github.com/preaction/Statocles/commit/f2512e2465c8702a68765463c144fb2b9c82bb39) ([#329](https://github.com/preaction/Statocles/issues/329))
* [add more basic docs to the app role](https://github.com/preaction/Statocles/commit/9e162173d173beb2daa9e5973f7b80da0cb79ee9)
* [link to built-in app docs in app role documentation](https://github.com/preaction/Statocles/commit/7d9c9df4ef067694aff4fd239e54c0da19264e23) ([#323](https://github.com/preaction/Statocles/issues/323))
* [remove unused import](https://github.com/preaction/Statocles/commit/c2acd231cba1d07a56dd7be42ae4ed39e4991f62) ([#328](https://github.com/preaction/Statocles/issues/328))
* [add fontawesome and icons for rel=external links](https://github.com/preaction/Statocles/commit/26d925ca40aa28e356a29cd3cc57d06e6a1d0e6d) ([#136](https://github.com/preaction/Statocles/issues/136))
* [fix schema-less URLs being rewritten by build](https://github.com/preaction/Statocles/commit/6f77015793a0bbb87b3f99fbb235a4f026039809)
* [add rel="external" to external perldoc links](https://github.com/preaction/Statocles/commit/769bc234a6b3dde1bf2e6abd1bbcd8ced6beddef) ([#136](https://github.com/preaction/Statocles/issues/136))
