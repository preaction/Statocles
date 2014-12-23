---
author: preaction
last_modified: 2014-12-22 05:11:26
tags: release
title: Release v0.029
---

This release adds support for static files to the Store and a new app for
adding static files to your site.

Since Statocles is meant to be used with a command line, you can now redirect
input into the "blog post" command. This makes it easy to write scripts that
generate markdown and use them with the blog.

The Statocles website also got a bit of a facelift, and that revealed a bunch more
bugs to fix.

There was also a lot of test cleanup in this release, to make future
development easier.

Full changelog:

---

* [release v0.029](https://github.com/preaction/Statocles/commit/f26beb18f5096acc947c6a0b5a479c8aabe718e6)
* [add new home page layout](https://github.com/preaction/Statocles/commit/54c36c3302e7941f909613afa517c1ba1dc0bef3) ([#148](https://github.com/preaction/Statocles/issues/148))
* [add head_after include for custom <head> JS and CSS](https://github.com/preaction/Statocles/commit/08d34e0a0130d702bd02542f6299f742d6e90ba7)
* [fix site altering raw file content with base URL](https://github.com/preaction/Statocles/commit/01b42cdd82def3865c25e78d605b24b089dcf93c)
* [open/write filehandles using raw bytes](https://github.com/preaction/Statocles/commit/e084118b88e3838e38d5afa027d770ab22ca9903) ([#171](https://github.com/preaction/Statocles/issues/171))
* [allow blog post content on STDIN](https://github.com/preaction/Statocles/commit/709ea186cc8fda642770cc6e69895de3a1eda390) ([#164](https://github.com/preaction/Statocles/issues/164))
* [add plain and static apps to Setup guide](https://github.com/preaction/Statocles/commit/06a7a989e09615b3ab9abd0378ad66ddb1714a79) ([#166](https://github.com/preaction/Statocles/issues/166))
* [allow for test_pages without index test](https://github.com/preaction/Statocles/commit/4b11c83535432de6e9bfda35cbc14740cfcd3bbb)
* [fix syntax error on 5.10. '...' was added in 5.12](https://github.com/preaction/Statocles/commit/65728398cbaa6b907fce031af0e8f751c9617eb3)
* [add Static app for tracking static files](https://github.com/preaction/Statocles/commit/cd9d7a4ad83e314852913ba7a2cdaa3109377b1a) ([#22](https://github.com/preaction/Statocles/issues/22))
* [make sure find_files returns absolute paths](https://github.com/preaction/Statocles/commit/eb1508af382577347e20a6e40d4f16a3084f0a99)
* [add File page to move files between stores](https://github.com/preaction/Statocles/commit/c7288a0666247ab33d84c9487d1e7e3dd52eb524)
* [add open_file and write_file for filehandles](https://github.com/preaction/Statocles/commit/b8620fd037ed439a5981788842272daf129cd36f)
* [add find_files method to Store](https://github.com/preaction/Statocles/commit/f29177ffc7614db7de56dd42b418a7f68c40c4c7)
* [add SEE ALSO about other static site tools](https://github.com/preaction/Statocles/commit/b4516136c617f58e3514ee3814704fb2a2493446) ([#68](https://github.com/preaction/Statocles/issues/68))
* [clarify setup docs about daemon command](https://github.com/preaction/Statocles/commit/a513b29b9841a35b7b4c9dea6349ed32f29afa47)
* [trap date/time parsing exceptions](https://github.com/preaction/Statocles/commit/f89234c31d5db910bdc19ce9db6696ec4c24811b)
* [move test yaml error document to a directory](https://github.com/preaction/Statocles/commit/e5ecc79d77ed255259efe6fbcd0137a13e25b6c5)
* [check that store path exists and is directory](https://github.com/preaction/Statocles/commit/46dd5dee2248c97769a62a005820bea755cece5f) ([#124](https://github.com/preaction/Statocles/issues/124))
* [make sure store is always using utf-8](https://github.com/preaction/Statocles/commit/532bf265d416b880933ab2fcc9734a9ec058d405) ([#145](https://github.com/preaction/Statocles/issues/145))
* [cleanup store tests to use files](https://github.com/preaction/Statocles/commit/4476b67a0691796c7b1f19c38821070a273f3085)
* [remove spurious test collateral](https://github.com/preaction/Statocles/commit/03b18578800d642014d115faedd55803c3471d97)
* [organize t/share directory better](https://github.com/preaction/Statocles/commit/231c371af4be11d3303ba2b2487c07920c40a7d2)
* [add script to generate release commit lists](https://github.com/preaction/Statocles/commit/5849cf5fa36bc2675745e6f3cdd3820097c1139f) ([#157](https://github.com/preaction/Statocles/issues/157))
* [cleanup blog tests](https://github.com/preaction/Statocles/commit/0cc268abcf0344ed0fb7aeca1a1cdab0751f84dd) ([#133](https://github.com/preaction/Statocles/issues/133))
* [add test_pages helper function](https://github.com/preaction/Statocles/commit/fb3017dacd0da801b80ca58a884a62f4b04add1e) ([#132](https://github.com/preaction/Statocles/issues/132))
* [add test_constructor helper function](https://github.com/preaction/Statocles/commit/0d52340dd8de23907b872f05e5ce1303adeadc78) ([#132](https://github.com/preaction/Statocles/issues/132))
* [paginated list pages should share last_modified](https://github.com/preaction/Statocles/commit/c8e2dfec0b398f4366b60b4afbc5e3630db9cc80) ([#125](https://github.com/preaction/Statocles/issues/125))
* [fix: daemon serves data with wrong charset](https://github.com/preaction/Statocles/commit/b12156913ef924afdef222161e9b5b449151d5c9) ([#162](https://github.com/preaction/Statocles/issues/162))
* [add tagline to default theme](https://github.com/preaction/Statocles/commit/6e9d7faa0927bed65acd46f9c5a28dde06083f42) ([#161](https://github.com/preaction/Statocles/issues/161))
* [clarify what each destination Store is used for](https://github.com/preaction/Statocles/commit/e0569e91dfd3790fffa5a24e577bab84096dc288)
* [build the site when daemon starts up](https://github.com/preaction/Statocles/commit/3a85938871f37961c3442d1f8d4a6a181044a089) ([#155](https://github.com/preaction/Statocles/issues/155))
* [add links to github, cpan, and irc to site](https://github.com/preaction/Statocles/commit/438b1c33ffeee4e9e37ed9e552f824ff2680c490) ([#156](https://github.com/preaction/Statocles/issues/156))
