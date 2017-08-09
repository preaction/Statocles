---
tags: release
title: Release v0.084
---

Just a small change in this release that makes it easier to add your own
behaviors to the [Statocles::Store](/pod/Statocles/Store) object.

In this release:

## Added

* The Store object now has a "files" method which gets the iterator over
  all the files in the store. This can then be easily overridden to get
  the list of files from another place: The configuration file,
  a manifest file, a database, or what-have-you. Thanks
  [@djerius](http://github.com/djerius) for the patch!
