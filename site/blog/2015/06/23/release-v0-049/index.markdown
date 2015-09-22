---
tags:
  - release
title: Release v0.049
---

A quick couple of bugfixes to solve an ongoing problem at $work. It turns out that
using [the plain app](/pod/Statocles/App/Plain) as the index app was contingent
on the filesystem's ordering or some other unpredictable thing. Now, this is fixed,
so the plain app can be safely used as the index.

This will be fixed/changed completely to [allow any page to be the index in a future
version](https://github.com/preaction/Statocles/issues/326).

Additionally, some footer styles were added to the default theme.

Full changelog below...

---

* [add warning if app creates duplicate pages](https://github.com/preaction/Statocles/commit/ec7bd0f44322d2cf286e68633033c73c94e3afdb) ([#319](https://github.com/preaction/Statocles/issues/319), [#331](https://github.com/preaction/Statocles/issues/331))
* [fix plain app using wrong index page](https://github.com/preaction/Statocles/commit/dc45e0665309905b2202d060ab5add32f0bc147f) ([#330](https://github.com/preaction/Statocles/issues/330))
* [add footer styles to default theme](https://github.com/preaction/Statocles/commit/9c0f0ae7418fa8e3f0730bbd50a8467a4cad171a)
