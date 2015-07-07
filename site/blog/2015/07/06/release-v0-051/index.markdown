---
tags:
  - release
title: Release v0.051
---

The Bootstrap theme is back as an option! Use `::bootstrap` as your theme to get it!

A breaking change: The [Store's find_files method](/pod/Statocles/Store/File.html#find_files)
now skips paths that look like documents by default. If you need to old behavior,
pass in `include_documents => 1` to the method.

That change was made to support ".md" as a document file extension. Previously, only
".markdown" was supported. This is a work-in-progress, so if there are any bugs,
[file a bug report](http://github.com/preaction/Statocles/issues).

Full changelog below...

---

* [make find_files skip documents by default](https://github.com/preaction/Statocles/commit/9a1691fc30d153f6b571b89b6df35e1762e96451) ([#332](https://github.com/preaction/Statocles/issues/332))
* [add method to check if a path is a document](https://github.com/preaction/Statocles/commit/14deef0bf1ebbcb74c4d0ced76f78ea40fb5c109) ([#332](https://github.com/preaction/Statocles/issues/332))
* [allow "md" and other extensions for markdown files](https://github.com/preaction/Statocles/commit/e6314ba56aed6eda02286aa2943e4158f0b4035f) ([#332](https://github.com/preaction/Statocles/issues/332))
* [fix test to detect bad body links in perldoc app](https://github.com/preaction/Statocles/commit/ad025e80713fa937a389bb1294152b33632a3fe7) ([#342](https://github.com/preaction/Statocles/issues/342))
* [fix links to index module in perldoc app](https://github.com/preaction/Statocles/commit/65f818c821a7a71d808c8ba6cb1969422e7e7b80) ([#342](https://github.com/preaction/Statocles/issues/342))
* [do not add static HTML when markdown files exist](https://github.com/preaction/Statocles/commit/0047778be7ded228d40881122c1eb57dd3f85ff5) ([#339](https://github.com/preaction/Statocles/issues/339))
* [fix scheme detection in LinkCheck plugin](https://github.com/preaction/Statocles/commit/4905e41ab029eeacf714a3a1d77a7c3653869e4a) ([#340](https://github.com/preaction/Statocles/issues/340))
* [mention the File deploy in the guides](https://github.com/preaction/Statocles/commit/1983ea50127c3e0f238df26cda75182216748fd3) ([#341](https://github.com/preaction/Statocles/issues/341))
* [make default theme closer to bootstrap theme](https://github.com/preaction/Statocles/commit/0e74aa5a9f980c1a21f472f45cd120c4833f19de)
* [add bootstrap theme back as an option](https://github.com/preaction/Statocles/commit/9e259e6ebb448d13ffb300319b7af02530163e5f) ([#314](https://github.com/preaction/Statocles/issues/314))
