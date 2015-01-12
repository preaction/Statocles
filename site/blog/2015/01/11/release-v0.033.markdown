---
author: preaction
last_modified: 2015-01-11 21:07:19
tags: release
title: Release v0.033
---

Just some minor bugfixes in this release: The `--date` option when making a new blog
post finally works, and when writing a new post while the daemon is running, the site
will be updated as expected.

Full changelog below.

---

* [fix unable to set date for blog post from command](https://github.com/preaction/Statocles/commit/2a82545b25faabf7b658a389116628d5fa1a673d) ([#198](https://github.com/preaction/Statocles/issues/198))
* [build a new temp site for each command test](https://github.com/preaction/Statocles/commit/c89b5b233b2db9a859ce60adf7a1d2c9616c2079)
* [remove root dotfiles and root ini files from dist](https://github.com/preaction/Statocles/commit/d7bed7836f799ddf9579a4197b2608ffbae33103)
* [switch to dzil Git::GatherDir](https://github.com/preaction/Statocles/commit/449dac496af7fb96a25b249709f73a66b96bbbb5)
* [add new blog posts to store so auto-build works](https://github.com/preaction/Statocles/commit/cf4a725cb21fee4000df58a6561dfb1fa87e27a2) ([#183](https://github.com/preaction/Statocles/issues/183), [#180](https://github.com/preaction/Statocles/issues/180))
* ["now" is easily mistaken for "not" in test diag](https://github.com/preaction/Statocles/commit/158e8fef4196c5203aae104ee873d67703e5fe0f)
