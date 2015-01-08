---
author: preaction
last_modified: 2015-01-04 20:58:33
tags: release
title: Release v0.032
---

Another major breaking change in this version: Theme is now an attribute of a site,
not an app. The per-app theme was too much flexibility, and made it very difficult
to add theme collateral like scripts, stylesheets, and images.

The robots.txt is now a template, which allows you to overwrite it with new contents.
The Mac::FSEvents module, which we use to watch the filesystem on OSX, is now a
prereq for OSX users.

Finally, some tests were updated with more diagnostics information, to track down
some locale problems.

Full changelog below:

---

* [fix contributors dependency](https://github.com/preaction/Statocles/commit/923f4e6f170984431c5553124765389eea9ca6a8)
* [add template for robots.txt](https://github.com/preaction/Statocles/commit/4b640224f73ad0dda82f82c74f3603908178fed2) ([#116](https://github.com/preaction/Statocles/issues/116))
* [use site-wide theme for sitemap.xml](https://github.com/preaction/Statocles/commit/4ed2e46f4aef4b4f8ad53c10403a8006552cf46c) ([#126](https://github.com/preaction/Statocles/issues/126))
* [move theme to site, removing it from all apps](https://github.com/preaction/Statocles/commit/bbbd926d2f3bff99319595ca54146b26384df1f5) ([#126](https://github.com/preaction/Statocles/issues/126), [#175](https://github.com/preaction/Statocles/issues/175))
* [update copyright year](https://github.com/preaction/Statocles/commit/f73fa9e30be7d330d32baf3fdd7b26fd2aa432a7)
* [add contributors dzil plugin for proper attribution](https://github.com/preaction/Statocles/commit/435b9d42aba1499d3b80ef4108c31c6c1707516f)
* [also add stderr diag to bin/statocles test](https://github.com/preaction/Statocles/commit/a2ac4d21558e4d992fbc1c86707dd644d72b0571)
* [always print stderr/stdout when testing for empty](https://github.com/preaction/Statocles/commit/8ecde6f75df007a2f1f082c76ca750705e6375b3) ([#188](https://github.com/preaction/Statocles/issues/188))
* [add Mac::FSEvents to prereqs for OSX](https://github.com/preaction/Statocles/commit/276be0e71b7aa7ca21a68185f5a88dd13046c0be) ([#189](https://github.com/preaction/Statocles/issues/189))
* [prevent uninitialized warnings in locale test](https://github.com/preaction/Statocles/commit/1c452cca740f2a4b618e141663929bd725981045)
