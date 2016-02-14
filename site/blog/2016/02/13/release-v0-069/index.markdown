---
tags: release
title: Release v0.069
---

A couple minor bugfixes today: 2 rare bugs that could cause test
failures and prevent Statocles from installing, and now the default site
layout explicitly adds a charset meta tag, since Statocles writes all
its HTML as UTF-8.

Full changelog below...

---

* [remove useless test line](https://github.com/preaction/Statocles/commit/c401c96f3f83ba12b559a0d779c2aeb6f8e7a4e8)
* [fix store warning when given no content](https://github.com/preaction/Statocles/commit/59c60d0573d3ddd51e01b2ad730663141b1d1d00)
* [fix yaml remedy checks for YAML::Syck](https://github.com/preaction/Statocles/commit/3957843809943e92fe6dba52430855a009c4ab9a) ([#460](https://github.com/preaction/Statocles/issues/460))
* [add test for template comments](https://github.com/preaction/Statocles/commit/6bdc746700164b1bf02f7bb6132f89d9fbac03e4)
* [Specify UTF-8 encoding in site layout](https://github.com/preaction/Statocles/commit/4d5ed6ab363e0fb16f7880ce66b63af72003ac3d)
