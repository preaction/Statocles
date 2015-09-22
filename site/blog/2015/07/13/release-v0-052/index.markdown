---
tags:
  - release
title: Release v0.052
---

In the run up to v1.000, we've added a [deprecation policy](/pod/Statocles/Help/Policy).

Our first deprecation: The site's "index" property should now be a full path to
a page, and not the name of an app. This lets you choose any page at all to be
the site index, and removes some of the magic around choosing an index page
that caused quite a few bugs. See [the upgrading
guide](/pod/Statocles/Help/Upgrading) for tips on how to fix the
deprecation warnings.

A couple bugfixes this release as well:

* The Bootstrap theme now correctly loads jQuery before the Bootstrap javascript
* A site can be built and tested without being able to deploy (if your deploy system
  is different from your development system).

Full changelog below...

---

* [enhance the docs about the site index property](https://github.com/preaction/Statocles/commit/03e5f6f13e19ef8054a7dc0dd8c219f9a027644e)
* [add deprecation policy and upgrading guide](https://github.com/preaction/Statocles/commit/a4b8dc92dbdaf5a820c587d047f14c8e3e3c2923) ([#346](https://github.com/preaction/Statocles/issues/346))
* [allow site to be built with no deploy dir](https://github.com/preaction/Statocles/commit/7f3a5fc2fdb8589b0ef5ff4aa9b3bb50b89b65fc) ([#348](https://github.com/preaction/Statocles/issues/348))
* [add core prereq for Pod::Simple](https://github.com/preaction/Statocles/commit/2482b25b4d9deef0c447325a6523dd7ae80ebd3e) ([#349](https://github.com/preaction/Statocles/issues/349))
* [fix bootstrap theme missing jquery](https://github.com/preaction/Statocles/commit/268685c34771eb148b637c603329aca0b7a3369f) ([#350](https://github.com/preaction/Statocles/issues/350))
* [use page path for site index, not apps](https://github.com/preaction/Statocles/commit/cf0d3ebb59d3583e68840c5918d4e5f28f8d0813) ([#326](https://github.com/preaction/Statocles/issues/326))
