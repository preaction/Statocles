---
tags: release
title: Release v0.072
---

A lot of little fixes in this release, mostly to the Statocles project
build/release process. But one important one: The version of
[Path::Tiny](http://metacpan.org/pod/Path::Tiny) we rely on is now
updated to fix an issue with relative paths.

Also, the Statocles::Test module is mostly deprecated so that you don't
need to have test modules installed on your machine for runtime
purposes. This makes it easier to move Statocles around.

Full changelog below.

---

* [Add META.json to release](https://github.com/preaction/Statocles/commit/edf215f87385e7e0bbc9fa2d865a0304824bb096)
* [deprecate Statocles::Test::test_pages](https://github.com/preaction/Statocles/commit/6bcd6abbeab7a07db944fa6343a5e74a6c07e045)
* [copy test_pages from Statocles::Test to t/lib/My/Test.pm](https://github.com/preaction/Statocles/commit/87330af32929d8aca4b69bc8bdfd0c2ecf7d62d0)
* [Deprecate Statocles::Test::test_constructor](https://github.com/preaction/Statocles/commit/e583675a820cd548f2b6997a2647509939485efd)
* [Copy test_constructor to lib/My/Test.pm](https://github.com/preaction/Statocles/commit/f2c8980a3edb55ac6aaaf5bf873db31785d5b2fa)
* [Reimplement test_constructor in TB Calls preparing for deprecation](https://github.com/preaction/Statocles/commit/0634d47c91b328ffe3dd69996fe46a7a2b063b9c)
* [Rewrite test_pages in Test::Builder calls preparing for deprecation](https://github.com/preaction/Statocles/commit/b313018a6863bc9e406ca0f296b6b14084731e49)
* [Rewrite tests to use Test::Lib + My::Test](https://github.com/preaction/Statocles/commit/9fa4ea7cc91b2ae0f699dfa62a4922f96175228c)
* [Add a library "My/Test" in t/lib that replaces Statocles::Base 'Test'](https://github.com/preaction/Statocles/commit/b5da3fdf0309ec48f3250f3f39888e6c3fd32f54)
* [Deprecate Statocles::Base 'Test'](https://github.com/preaction/Statocles/commit/d19361eaebff355667635bb41c865109ab4cd365)
* [update Path::Tiny version](https://github.com/preaction/Statocles/commit/46c6a7c77f2790bb0524b23012d296e319eb0059) ([#476](https://github.com/preaction/Statocles/issues/476))
* [Inject README.mdkn exclusively in the source tree](https://github.com/preaction/Statocles/commit/453f7e5bacf326858c6a2a330e0aed0e3d2a9a5b)
* [Replace ReadmeMarkdownFromPod with ReadmeAnyFromPod](https://github.com/preaction/Statocles/commit/36b113babc3deb5a5854cf89071fda08eaa31098)
* [Munge README.mkdn in SRC after copying, instead of in CPAN before copying](https://github.com/preaction/Statocles/commit/3850953e7733357e8fd556d98c599956baa44913)
* [Replace ReadmeFromPod With Readme::Brief](https://github.com/preaction/Statocles/commit/2538c2e6cbe07f2be136999fa72653f70819b70a)
* [Remove instructions to copy CPAN/README to SRC/README](https://github.com/preaction/Statocles/commit/8647facf7fdef6c4193b29f0d7a7764d536ca812)
* [Remove DZP:Readme from basic bundle](https://github.com/preaction/Statocles/commit/ead8cca5868467b8a58aec8e5c3924a52e4594fd)
* [Add -SingleEncoding to weaver.ini](https://github.com/preaction/Statocles/commit/7d61f77a12acae326514e4224cd5341298b23f03)
