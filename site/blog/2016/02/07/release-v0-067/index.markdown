---
tags: release
title: Release v0.067
---

This release adds [shortcut icons to the site
object](/pod/Statocles/Site#images) and [stylesheet and script links to the
site object](/pod/Statocles/Site#links).

This release also fixes a few problems in the default theme: One where
the default theme's font is unreadable, another where nested lists get
continually smaller, and eventually unreadble.

This release fixed some unhelpful error messages, so that problems
should be more easily resolved.

Full changelog below

---

* [sort broken links in link check plugin](https://github.com/preaction/Statocles/commit/10c5d55538dcc176a483850c8f354329e69e29f6) ([#432](https://github.com/preaction/Statocles/issues/432))
* [add debug message when rendering a page](https://github.com/preaction/Statocles/commit/186df241a393314eae649e720b4c6222cc7f30a8) ([#435](https://github.com/preaction/Statocles/issues/435))
* [fix page render error when document title is undef](https://github.com/preaction/Statocles/commit/08cb238c30be2be20ce95aed24b65cb184eefb04) ([#435](https://github.com/preaction/Statocles/issues/435))
* [add test for stylesheet, script, and favicon links](https://github.com/preaction/Statocles/commit/7c2dd747dfdf3d4642a4f08bcded370f2fc0dbc7) ([#438](https://github.com/preaction/Statocles/issues/438))
* [show load error if failed to load Pod::Weaver](https://github.com/preaction/Statocles/commit/a05d56462b2e158f21366303208549ff5f319d57) ([#440](https://github.com/preaction/Statocles/issues/440))
* [fix missing attribute in site object error message](https://github.com/preaction/Statocles/commit/c154d62610d447e1ce0d2aa15ce063de8688a90b) ([#439](https://github.com/preaction/Statocles/issues/439))
* [add status attribute in preparation to its use](https://github.com/preaction/Statocles/commit/cab12a344785b6ed092c2b846ddbff891fa180d0)
* [add style and script links to site object](https://github.com/preaction/Statocles/commit/f619d08b518f4c5a549cff3982676c2eb1e91c9b) ([#442](https://github.com/preaction/Statocles/issues/442))
* [fix coersion for links in page object](https://github.com/preaction/Statocles/commit/8d612e4b5fa3746009e8b72d55ee76fddeaf3224)
* [fix nested lists getting smaller and smaller font](https://github.com/preaction/Statocles/commit/9918bff9d92e94d56238eafe81a83e141f288b04)
* [fix default font to something more readable](https://github.com/preaction/Statocles/commit/30c09bb4ce08b1f65e031d273bc8ca04da7148d0) ([#443](https://github.com/preaction/Statocles/issues/443))
* [remove static app from the config guide](https://github.com/preaction/Statocles/commit/d017abf25c46b8077217fbe3d74cb77ffa358b75)
* [add shortcut icon to default themes](https://github.com/preaction/Statocles/commit/6de618eec03a859985d6823059edbab50189b66f) ([#408](https://github.com/preaction/Statocles/issues/408))
* [add images attribute to site object](https://github.com/preaction/Statocles/commit/ba1c01fec4a68fd28cc0230b22e5758b9d7f0055) ([#408](https://github.com/preaction/Statocles/issues/408))
