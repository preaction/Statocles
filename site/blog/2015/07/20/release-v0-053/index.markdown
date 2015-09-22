---
tags:
  - release
title: Release v0.053
---

A bunch of documentation fixes this week, including some additions to
[the content guide](/pod/Statocles/Help/Content) to help users get
acclimated to managing content.

A couple bugfixes as well: Full URLs in blog posts are no longer broken
on the main page, and some tests that could have prevented installation
have been fixed (thanks to [Joel
Berger](http://metacpan.org/author/JBERGER) for both of these).

Full changelog below...

---

* [expand the document documentation a bit more](https://github.com/preaction/Statocles/commit/2ddcc6b91a4bbd18e183603265aa99285c43e88b)
* [link to frontmatter options in the content guide](https://github.com/preaction/Statocles/commit/d9935f03c997afe8d935992cd44dd3e2c02daca3)
* [add more examples of plain pages to content guide](https://github.com/preaction/Statocles/commit/977b62cbf919a8336642b62be812b7ca2cd550ee) ([#364](https://github.com/preaction/Statocles/issues/364))
* [add meta generator information to default themes](https://github.com/preaction/Statocles/commit/61dad19d39eb3902cedccf717bf8713221d1650a) ([#365](https://github.com/preaction/Statocles/issues/365))
* [fix mojo ioloop tests when testing file events](https://github.com/preaction/Statocles/commit/d7e6459fd03ad355f1f8cf5eb4fbe6dc8fde9939) ([#353](https://github.com/preaction/Statocles/issues/353))
* [move method signature inside documentation body](https://github.com/preaction/Statocles/commit/c954f65f2b4ec00bf8cc3d5ae98ce58bba900ff6) ([#351](https://github.com/preaction/Statocles/issues/351))
* [set '/' as the default site index](https://github.com/preaction/Statocles/commit/c41e23348b6114589c2ce7d9155383acff184027) ([#354](https://github.com/preaction/Statocles/issues/354))
* [silence log warnings from tests](https://github.com/preaction/Statocles/commit/15f001ff0a7e9c3d840fd1ade7f89adbcb2cc750) ([#358](https://github.com/preaction/Statocles/issues/358))
* [add upgrading and policy modules to help index](https://github.com/preaction/Statocles/commit/aab007b1eab2a948152559ae16116714a9e8713f) ([#356](https://github.com/preaction/Statocles/issues/356))
* [make -v with no arguments show version information](https://github.com/preaction/Statocles/commit/4251d3bf9aacb1f86202c0ea32d89946725041f4) ([#357](https://github.com/preaction/Statocles/issues/357))
* [fix full urls falsely rewritten on list pages](https://github.com/preaction/Statocles/commit/f78b04d328f89483e3fcd81c487053ef084d5142) ([#355](https://github.com/preaction/Statocles/issues/355))
