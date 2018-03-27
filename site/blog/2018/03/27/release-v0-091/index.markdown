---
status: published
tags:
  - release
title: Release v0.091
---

More test fixes in this release. We finally pass our Travis build tests,
and this should also fix the [CPAN Testers](http://www.cpantesters.org)
test report failures as well!

In this release:

## Fixed

* Fixed test failures when STDIN was attached to /dev/null during
  testing. Thanks [@mohawk2](http://github.com/mohawk2)!
* Fixed test failures writing to site status file before `.statocles`
  directory is created

[More information about Statocles v0.091 on
MetaCPAN](http://metacpan.org/release/PREACTION/Statocles-0.091)
