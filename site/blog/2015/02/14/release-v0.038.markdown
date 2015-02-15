---
last_modified: 2015-02-14 23:53:41
tags: release
title: Release v0.038
---

With a new way to quickly build old git versions, this release fixes compatibility
with Git 1.7.

Unfortunately, we had to increase our minimum supported version of Git to
1.7.2, in order to get `git status --porcelain` and orphan branches. Neither of
these are that big of a deal-breaker, so in theory we could support some
slightly older versions of git.

Full changelog below:

---

* [fix git-rm compatibility with 1.7.2](https://github.com/preaction/Statocles/commit/1c43e3fb4f8227f9e533825034739f9c85036b01)
* [fix error adding submodule in test](https://github.com/preaction/Statocles/commit/aeafc6320d5630e3a707c883d993516c177ac8fd) ([#245](https://github.com/preaction/Statocles/issues/245))
* [upgrade git requirement to 1.7.2](https://github.com/preaction/Statocles/commit/83ce30aadec908a905efd5524c5f15acdda0ba92)
* [fix git version tests to work on Travis](https://github.com/preaction/Statocles/commit/6a2cc6a4d0611df83ca5262807a0d0930cf2f1db)
* [add extra tests for git versions](https://github.com/preaction/Statocles/commit/44fc34e31711ef98461f4349b005664a9cebd11b) ([#245](https://github.com/preaction/Statocles/issues/245))
