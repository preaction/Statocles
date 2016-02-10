---
tags: release
title: Release v0.068
---

This release fixes a missing dependency which Travis did not pick up on.
We've also (hopefully) fixed Travis, so that shouldn't happen again for
a while.

The `blog post` command also now allows you to specify `--author`,
`--tags`, `--layout`, and `--template` options to set those fields in
the resulting document.

Full changelog below...

---

* [fix travis always having certain prereqs installed](https://github.com/preaction/Statocles/commit/5bc828650d3eedffe3d5745958ac9892bbd30c7b)
* [fix use of private object data when adding links](https://github.com/preaction/Statocles/commit/4b4a6f87a3ed4e141a668392207070c585c95357) ([#449](https://github.com/preaction/Statocles/issues/449))
* [allow adding multiple links to a page at once](https://github.com/preaction/Statocles/commit/79434a8ada29efb735c064fb87df39b169dc3dbe) ([#450](https://github.com/preaction/Statocles/issues/450), [#449](https://github.com/preaction/Statocles/issues/449))
* [add missing List::UtilsBy dependency](https://github.com/preaction/Statocles/commit/5c111202e73a3aa8aec818ff1417b81790eb6c20) ([#448](https://github.com/preaction/Statocles/issues/448))
* [Add data hash to Image](https://github.com/preaction/Statocles/commit/b9e162e68aed2c71ce73767e609de67016482c12)
* [Add standard frontmatter overrides (author layout status tags template) to blog command](https://github.com/preaction/Statocles/commit/438c689135db77a1d982fc19d12bf2bb4d47577c)
