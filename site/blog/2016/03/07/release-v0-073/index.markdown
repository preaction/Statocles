---
tags: release
title: Release v0.073
---

Two tiny fixes in this release:

* The [Mojolicious](http://mojolicious.org) version we depend on has
  been updated because of deprecations in version 6.54.
* We now always push the Git deploy even if there is no new commit, just
  in case we didn't get the last commits pushed. This could happen if
  a deploy was able to create a commit, but could not push for whatever
  reason (server down, conflict, or other problem).

Full changelog below.

---

* [fix Mojo::Template deprecations](https://github.com/preaction/Statocles/commit/0f2f548b99214cfdaf3295e0e588bdccca38b159)
* [always push the git deploy](https://github.com/preaction/Statocles/commit/d5ff095ae3af795c98ed6ae8db93524feb8bf0c7) ([#470](https://github.com/preaction/Statocles/issues/470))
