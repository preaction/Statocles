---
author: preaction
last_modified: 2014-12-08 22:22:46
tags: release
title: Release v0.027
---
This release fixes some issues that would prevent Statocles from installing. I may have
finally fixed [the Win32 test failure that has been plaguing me!](https://github.com/preaction/Statocles/issues/110)

Full changelog:

---

* [try to fix bundle failure on Win32](https://github.com/preaction/Statocles/commit/00ec3ff70bc197bce3be289514ac952f5b0b29a7) ([#110](https://github.com/preaction/Statocles/issues/110))
* [bump required Mojolicious to 5.41](https://github.com/preaction/Statocles/commit/5ee43d1a72d30d9f9bad8f5621aaf1519536f26d)
* [only ignore Statocles bundles in the root directory](https://github.com/preaction/Statocles/commit/9afa82798b3119b50720a61b71a91664ce78cfb3)
* [die if there's a git error](https://github.com/preaction/Statocles/commit/ca2dd7a3e5396af1c9db9078f291c3fffc92489b)
