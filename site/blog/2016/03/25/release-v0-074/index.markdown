---
tags: release
title: Release v0.074
---

Some minor bugfixes in this release:

* Time zone problems that were causing tests to fail are now fixed.
  We're now correctly using your local time zone everywhere, and not
  UTC.
* Better error messages when Pod::Weaver throws an exception. When using
  [the weave attribute in the Perldoc
  app](/pod/Statocles/App/Perldoc/#weave), you must also provide
  a `weaver.ini` config file for Pod::Weaver to use. If it's missing, we
  now throw a better error message saying what to do.

Full changelog below...

---

* [wrap all errors from Pod::Weaver with more detail](https://github.com/preaction/Statocles/commit/4b683a003610b9bddd7a9a6dbb4687837e77edef) ([#446](https://github.com/preaction/Statocles/issues/446))
* [add better error message when weaver.ini is missing](https://github.com/preaction/Statocles/commit/17549af29d575469366963547aa8a1f8c502ea62) ([#446](https://github.com/preaction/Statocles/issues/446))
* [use local time zone everywhere](https://github.com/preaction/Statocles/commit/2c52d848fd66d40b4d31261217cd5a60187c6b08) ([#474](https://github.com/preaction/Statocles/issues/474))
* [fix blog posts not appearing in certain time zones](https://github.com/preaction/Statocles/commit/ca2376877106cb38f754313f2b58389d50e72996) ([#474](https://github.com/preaction/Statocles/issues/474))
* [fix page role abstract to declare it a role](https://github.com/preaction/Statocles/commit/e944be96e45ea1b521106dcb62da2fbbc677bd48) ([#479](https://github.com/preaction/Statocles/issues/479))
