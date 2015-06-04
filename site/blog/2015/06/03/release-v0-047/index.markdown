---
tags:
  - release
title: Release v0.047
---

A bunch of bugfixes in this release, including one that could have prevented
users from upgrading from previous versions due to a test failure.

Most importantly, pagination in the blog is working again.

Some additions to the [Content help guide](/pod/Statocles/Help/Content.html)
about a the new features over the last few releases, and one new feature adding
a `data` attribute to [Statocles::Document](/pod/Statocles/Document.html),
which allows for fun things when generating content.

Finally, some of our dependencies have been removed, since their functionality
overlapped with other dependencies (or turned out to be very easy to implement
ourselves).

Full changelog below

---

* [add blank link to allow for $VERSION](https://github.com/preaction/Statocles/commit/b44291d8f7f183ea260918a48a6967d99362d2d3)
* [move to documented Role::Tiny API](https://github.com/preaction/Statocles/commit/b51da241f5b269e6b9b26cf2ff4ee65c65e28cbe)
* [upgrade Import::Base to fix test failures](https://github.com/preaction/Statocles/commit/e7754597acc7a960dcd7e9665115c2df2523aaed)
* [add some interesting methods to the Theme guide](https://github.com/preaction/Statocles/commit/5f5e6a491386c6b6e9fa37ec219c0b78ca54d024) ([#311](https://github.com/preaction/Statocles/issues/311))
* [add content sections to content guide](https://github.com/preaction/Statocles/commit/912f713754187873ac96a0918c0f2e80f098acf2) ([#311](https://github.com/preaction/Statocles/issues/311))
* [fix links to template objects in Theme guide](https://github.com/preaction/Statocles/commit/2cdb8b28ccdb2dded79d7d4299d26ad326d51cd7)
* [add more documentation about writing content](https://github.com/preaction/Statocles/commit/1ce3f3f549d3e276ad02a04cbd69d7d1fcacb064)
* [remove dependency on List::MoreUtils](https://github.com/preaction/Statocles/commit/bcd239d1267807cacb1a2b6a18329fdc2533bf25) ([#255](https://github.com/preaction/Statocles/issues/255))
* [remove dependency on File::Copy::Recursive](https://github.com/preaction/Statocles/commit/4de80a234713752e5e4cea7d6372a8c4ad803b8e) ([#255](https://github.com/preaction/Statocles/issues/255))
* [fix links to the index app should be the site root](https://github.com/preaction/Statocles/commit/ff5346b5a58524544f3f6315b277a7a1f820b6eb) ([#305](https://github.com/preaction/Statocles/issues/305))
* [fix pagination in the blog](https://github.com/preaction/Statocles/commit/03ce696cf0fbc322ee2740d97ef6bacd668818ab) ([#304](https://github.com/preaction/Statocles/issues/304))
* [add data attribute to documents](https://github.com/preaction/Statocles/commit/ed66e3bac94a47ef2f1941d56aad9e4b99140be9) ([#99](https://github.com/preaction/Statocles/issues/99))
