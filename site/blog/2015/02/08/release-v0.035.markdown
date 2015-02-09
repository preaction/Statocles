---
tags: release
title: Release v0.035
---

Almost ready for the beta announcement now! Only [a few issues remain before we
can announce beta](https://github.com/preaction/Statocles/milestones/beta).

Content is now always processed through the template parser. This lets us have
includes in the content, so we can have widget templates or plugins that generate
related posts for example. This is a new feature, so I'm excited to see what can
be done with it.

There was some cleanup on the URLs we generate: Directories are being preferred
to files, so that the URLs are a bit easier to read. `/blog/page-2.html` is now
`/blog/page/2`, and `/blog/tag/mytag/page-2.html` is now
`/blog/tag/mytag/page/2`

A new help file was added, [all about deploying
Statocles](/pod/Statocles/Help/Deploy.html). As part of that, a lot of defaults were
updated to be more intuitive: The build directory gets automatically created, and the
default build directory is set to `.statocles-build`.

A bunch of things were fixed for Windows development, along with a nasty
platform difference in `strftime()`.

The `bundle theme` command is now actually useful and allows you to specify
where you want the theme to be copied. So now, if you want to customize the
default theme, you can `statocles bundle theme default mytheme` to copy the
default theme to the `mytheme` directory.

Full changelog below

---

* [update Mojolicious to 5.57 for improved map()](https://github.com/preaction/Statocles/commit/7914da68a0fa459f579f92bdc0cd734e78427bb8)
* [make `bundle theme` copy to given directory](https://github.com/preaction/Statocles/commit/8bfdb3303610d7f20ba4de004c6cc9b01c6ade4a) ([#204](https://github.com/preaction/Statocles/issues/204))
* [fix extra blank line in robots.txt test](https://github.com/preaction/Statocles/commit/d360f60855d70e75de9a26e847cf3de887878a55)
* [ignore vim swap files on windows](https://github.com/preaction/Statocles/commit/99f22208d6f4a2618e08a1c370f5da77701f1f07)
* [fix strftime for Windows](https://github.com/preaction/Statocles/commit/2b18785227261446bd42bbf860038db3383f87a6) ([#185](https://github.com/preaction/Statocles/issues/185))
* [fix test reading files without utf-8 flag](https://github.com/preaction/Statocles/commit/856dab4dde08a3d4d3bc5bccecc5aa33cdddf95b)
* [redo the setup help for new defaults](https://github.com/preaction/Statocles/commit/2d5dcb363a90d5686736cd96ea54449dbc0bce07) ([#231](https://github.com/preaction/Statocles/issues/231))
* [make blog pagination use directories](https://github.com/preaction/Statocles/commit/d689f0b8fb3a9cd7e940d2be62cf0e6c227cb3ef) ([#240](https://github.com/preaction/Statocles/issues/240))
* [allow list pages to consist of directories](https://github.com/preaction/Statocles/commit/6e10fb0798784e4a5d289ff47b54e340c52a7cca) ([#240](https://github.com/preaction/Statocles/issues/240))
* [automatically remove "index.html" from URLs](https://github.com/preaction/Statocles/commit/69c02e13ae5114589bc7c70e7c4b72d8017fa036) ([#165](https://github.com/preaction/Statocles/issues/165))
* [update Beam::Wire to fix warning on perl 5.20](https://github.com/preaction/Statocles/commit/b31d9a2dfc47cefdff14733f3c365a47e2b9e3da) ([#190](https://github.com/preaction/Statocles/issues/190))
* [process document content as a template](https://github.com/preaction/Statocles/commit/5833756f9374c6edeebbf2b0497ce4dab3373f7b) ([#213](https://github.com/preaction/Statocles/issues/213))
* [allow arguments to included templates](https://github.com/preaction/Statocles/commit/22883c4384fc32c95016302f2c81657f029e348c)
* [add a theme method to build template from string](https://github.com/preaction/Statocles/commit/98e88f85c0943043e7499abadaa8159280b6f8eb) ([#213](https://github.com/preaction/Statocles/issues/213))
* [do not watch built-in theme dirs for changes](https://github.com/preaction/Statocles/commit/56bbac55fce2fbb00803c5741ca686a16b5cc375) ([#182](https://github.com/preaction/Statocles/issues/182))
* [add deploy help documentation](https://github.com/preaction/Statocles/commit/8586a527a57654e9ead7dd8c8a265dd4edcf36d7) ([#211](https://github.com/preaction/Statocles/issues/211))
* [add remote attr to git deploy](https://github.com/preaction/Statocles/commit/7b1219746450cff080ff928871c7ba854d97d6f4) ([#236](https://github.com/preaction/Statocles/issues/236))
* [test that git deploy's path has a default](https://github.com/preaction/Statocles/commit/d353fca53df9846593d9955e7f9628c72f1b8dd0)
* [set a default build dir and auto-create it](https://github.com/preaction/Statocles/commit/0d9b5b5a05c1cfcbe517bd4f4ed3d2670d67966b) ([#233](https://github.com/preaction/Statocles/issues/233), [#234](https://github.com/preaction/Statocles/issues/234))
* [make site theme default to bundled default theme](https://github.com/preaction/Statocles/commit/1bf5f448db1c9ed22c405f890f633fb8bca96fb8) ([#235](https://github.com/preaction/Statocles/issues/235))
* [make file deploy default to the current directory](https://github.com/preaction/Statocles/commit/d357bd03948f0edd4bcca2ef9853fb9f6be6626c) ([#237](https://github.com/preaction/Statocles/issues/237))
* [Merge pull request #232 from vlet/master](https://github.com/preaction/Statocles/commit/0327f5d2aa6a62a98f9a4fed5ad0d47712980dae)
* [fix categories in atom feed](https://github.com/preaction/Statocles/commit/5c295a3e34898745bbb6e2c5019b102d31cf3184)
* [fix default theme list bullets on a separate line](https://github.com/preaction/Statocles/commit/42883c3fb85e809e1b78f35ed522d711c18b7489)
* [fix static app builds hidden directories like .git](https://github.com/preaction/Statocles/commit/c6e84f34b316dc685b81f155d9b7f41b7d0de624)
* [show an error if no theme name given to bundle](https://github.com/preaction/Statocles/commit/9fcd3d67249b769434c2efeb76be01ef81f216c1) ([#203](https://github.com/preaction/Statocles/issues/203))
* [allow pod from things without .pm, .pl, or .pod](https://github.com/preaction/Statocles/commit/f71814711efdfded9065838d92536af9fab1c272) ([#206](https://github.com/preaction/Statocles/issues/206))
* [add missing DESCRIPTION to some modules](https://github.com/preaction/Statocles/commit/304dabe75d21132717f8ec414e6333cbae52fa1d)
