---
tags: release
title: Release v0.064
---

Another bugfix release for the Highlight plugin's tests. Now there is a Travis
build that explicitly tests for the absense of recommended modules,
which should prevent this in the future.

Full changelog below...

---

* [use fake site for command error tests](https://github.com/preaction/Statocles/commit/8c05d2d6f091571c463f937b1a6aeba580ec2f4c) ([#426](https://github.com/preaction/Statocles/issues/426))
* [report stdout/stderr on test failure](https://github.com/preaction/Statocles/commit/de20f72fb7e9d388a43bd8b729c8288b478493db)
* [do not test Highlight plugin compile](https://github.com/preaction/Statocles/commit/a383326bc2671c2b077c899e10989c0104e6ed61)
* [only load Devel::Hide during test](https://github.com/preaction/Statocles/commit/2bce57a8eba7414041e148fd023be80148038498)
* [install Devel::Hide during travis build](https://github.com/preaction/Statocles/commit/35ff0048e3300be22dcf2ebc80b0dce8111188ba)
* [add travis build that hides optional dependencies](https://github.com/preaction/Statocles/commit/efc396a31a591c0c2fa27fe07b06dd1d7c35fd7b)
