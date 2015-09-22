---
last_modified: 2015-02-11 00:30:04
tags: release
title: Release v0.036
---

A couple fixes and a couple breaking changes in this release:

The biggest fix is that now we check for ignored files or submodule files before
trying to deploy to a Git repository. This should fix a lot of issues with deploying.

All pages now have a `last_modified` field, which has an appropriate default.
Also, all the default includes are now templates, so you can use template
variables inside them.  This breaks all existing themes, so make sure to
re-bundle your theme with `statocles bundle theme`.

Some getting started information was added to [the Theme
guide](/pod/Statocles/Help/Theme). In short, the best way to make your own
theme is to start from one of the existing themes.

Finally, the static app now works correctly when it is not at the root of the site.

Full changelog below.

---

* [do not check include hooks in theme sanity test](https://github.com/preaction/Statocles/commit/b5410e60c2b6990260e508e9aef173c4420a069a)
* [fix empty template includes warning about undef](https://github.com/preaction/Statocles/commit/a8cf9455e6f1a58e69f8602374e23647ec316179)
* [make all default includes into templates](https://github.com/preaction/Statocles/commit/835b71d9a8375c3e7921af77cca69fc4faf0f72e)
* [add getting started help to the theme guide](https://github.com/preaction/Statocles/commit/314c5ab6cc86e19b67b11864969773b0328dbad5)
* [change page published to last_modified](https://github.com/preaction/Statocles/commit/5d5457c328b36658128d7c11bc70fab509583c57) ([#130](https://github.com/preaction/Statocles/issues/130))
* [fix static app doesn't work with a url root](https://github.com/preaction/Statocles/commit/8cf6dfe7e4d19e3c6cdc39d7454fccdb94435f23) ([#227](https://github.com/preaction/Statocles/issues/227))
* [do not deploy ignored files or submodule files](https://github.com/preaction/Statocles/commit/16c9e50b3ef8eef5fbe0f258c2870553f612ee74) ([#229](https://github.com/preaction/Statocles/issues/229), [#181](https://github.com/preaction/Statocles/issues/181))
