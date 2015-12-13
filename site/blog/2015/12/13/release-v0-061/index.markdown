---
tags: release
title: Release v0.061
---

This release [adds `images`, a way to link images to
documents](/pod/Statocles/Document/#images). These images can then be
used by templates to display header images, thumbnails, shortcut icons, and
other things.

This release also adds some more logging to the deploy process. You can
show logging information by using the `-v` option on the command line.

Full changelog is below.

---

* [fix deploy staying on branch when nothing to do](https://github.com/preaction/Statocles/commit/606ec5be9ab8a9a9c2b354274374644caddb1635)
* [add a testable log object to the test sites](https://github.com/preaction/Statocles/commit/575f4b41b257160c217137fff8c4acc52a91e43d)
* [add logging to deploys](https://github.com/preaction/Statocles/commit/35fb1b13c0fcd7d1b1500a96705c03fa3c4dc996)
* [add site object to deploy objects](https://github.com/preaction/Statocles/commit/9c1a287fc5ec3b5c6800e1a529cbefa473674244)
* [fix git version parsing when version isn't last](https://github.com/preaction/Statocles/commit/a643ea68491c7fffe56aeb815bdd4b607fb367ca)
* [speed up deploy by using copy method](https://github.com/preaction/Statocles/commit/3fea4585dfaaddfa0604fff009e6081eeb5556b1)
* [add help section to main web page](https://github.com/preaction/Statocles/commit/13672b693cc8bd49308ee3990f8672933e50744f)
* [add images to page objects](https://github.com/preaction/Statocles/commit/1dbbc4efa57c7a717327467d4ab8e98463165958) ([#409](https://github.com/preaction/Statocles/issues/409))
* [add images attribute to documents](https://github.com/preaction/Statocles/commit/ab78ba6055afda7a1e972cae37ff2c1a1877ce3d) ([#409](https://github.com/preaction/Statocles/issues/409))
* [add image class to hold refs to images](https://github.com/preaction/Statocles/commit/2d81fd52ac124fb7daa5b3a1275df9fb1b50ded8) ([#409](https://github.com/preaction/Statocles/issues/409))
* [set a default empty title to stop undef warnings](https://github.com/preaction/Statocles/commit/6cb8fce2dd4eb0c47d71cccb27c3b35f762f4b4f)
* [add module name to page title in perldoc app](https://github.com/preaction/Statocles/commit/6c4851f78750611ad093d23475e6b6b509350011) ([#411](https://github.com/preaction/Statocles/issues/411))
* [check for version of HTML::Lint::Pluggable in test](https://github.com/preaction/Statocles/commit/7a4bf776edaad2279dd097e00142ab3cdde3de64) ([#410](https://github.com/preaction/Statocles/issues/410))
