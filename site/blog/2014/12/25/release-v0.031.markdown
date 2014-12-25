---
author: preaction
last_modified: 2014-12-25 08:12:10
tags: release
title: Release v0.031
---

[CPAN Testers](http://cpantesters.org) (the best part of CPAN) revealed a bunch
of bugs causing test failures that would prevent Statocles from being
installed. This has demonstrated the value of writing robust test suites.
Before we can announce a beta, we need to make sure that Statocles can be
installed on most of the platforms that people use.

This release fixes most of the problems that CPAN Testers have revealed.

Full changelog below:

---

* [fix test failure because config not found](https://github.com/preaction/Statocles/commit/1d3db19809d4cbd27ed8cbe8709118c5118d4c1c)
* [fix daemon continually rebuilding the site](https://github.com/preaction/Statocles/commit/6756a44f4079e8b8b3d000df36bcfe8dac513013) ([#172](https://github.com/preaction/Statocles/issues/172))
* [fix tags list not appearing on blog list pages](https://github.com/preaction/Statocles/commit/fcdd2d85f4fb79c0becbc23f10351dd6e8222a51) ([#184](https://github.com/preaction/Statocles/issues/184))
* [give better error when site object not found](https://github.com/preaction/Statocles/commit/a92f02cf668779eef05504c937bf61b34bbed461)
* [give better error when config file not found](https://github.com/preaction/Statocles/commit/737501197f3c237cc7a86675cdbb426e20136c2a) ([#38](https://github.com/preaction/Statocles/issues/38), [#179](https://github.com/preaction/Statocles/issues/179))
* [remove tests that could redefine subs](https://github.com/preaction/Statocles/commit/6235ad543c8d60177a72681e22b2ecddbff92e93) ([#186](https://github.com/preaction/Statocles/issues/186))
* [fix setlocale test may fail and return current locale](https://github.com/preaction/Statocles/commit/3434173dd71c65da423be079a0f0bce474d36f24)
* [remove test for switching STDIN back to our tty](https://github.com/preaction/Statocles/commit/be20281ae4d4373b0bb3ef4b6f6c06ccf4193d32) ([#187](https://github.com/preaction/Statocles/issues/187))
* [fix RSS pubDate incorrectly using locale setting](https://github.com/preaction/Statocles/commit/8ad90ceeeb131b70c4f76fd447155d80b277888b) ([#185](https://github.com/preaction/Statocles/issues/185))
* [add link to home page in main documentation](https://github.com/preaction/Statocles/commit/e0ed3095c496f66273836eb3b9add53b92f91875)
