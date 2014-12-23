---
author: preaction
last_modified: 2014-12-23 06:25:02
tags: release
title: Release v0.030
---

With the push towards a useful public beta, I made some breaking changes in
this release:

* All our documents now have the file extention ".markdown" and not ".yml".
  They are not YAML files, they're Markdown files with optional YAML at the top.
* If the document has YAML, the document must start with "---".
* Plain YAML files are no longer allowed.
* The plain file store is now called Statocles::Store::File, which means your
  site's config file may need to change.

If you need to change all your files from ".yml" to ".markdown", you can use
the following:

    find site -name '*.yml' | rename -s '.yml' '.markdown'

Full changelog:

---
* [release v0.030](https://github.com/preaction/Statocles/commit/d59b333bd12df4be6fc6ade69f780ac339d95fbb)
* [cache file store's realpath to fix race condition](https://github.com/preaction/Statocles/commit/2ca6f00d30e069b0fbe5ddfeced6b7613759c851)
* [require frontmatter to begin with '---'](https://github.com/preaction/Statocles/commit/71ff0276938281180200a840cba747f54cf6400e)
* [rename statocles site documents to .markdown](https://github.com/preaction/Statocles/commit/0c392ef516374d8a2ea978d8e3be7561ecc28a1d)
* [rename documents from '.yml' to '.markdown'](https://github.com/preaction/Statocles/commit/48943a423e0c1d8240fd4c61fa8cdb4974a70469) ([#73](https://github.com/preaction/Statocles/issues/73))
* [make all file stores ignore other stores' files](https://github.com/preaction/Statocles/commit/bff432b118983ec0bf3a6c9571415c1c142b63a4) ([#172](https://github.com/preaction/Statocles/issues/172))
* [rename Store to Store::File](https://github.com/preaction/Statocles/commit/f8d351fc78fa60a71c7453d211c1271881b99291)
* [ignore hidden files in the static app](https://github.com/preaction/Statocles/commit/2faf825680dd61e0119320467457e30bde34392c) ([#174](https://github.com/preaction/Statocles/issues/174))
* [only allow html files in the sitemap.xml](https://github.com/preaction/Statocles/commit/8981211d3e3ce194350e0d431a9fde8ecd2dfad5) ([#176](https://github.com/preaction/Statocles/issues/176))
* [reset STDIN to the tty when piping in content](https://github.com/preaction/Statocles/commit/e86a5ca3f4b7412c4b78fdac27a1d6e6f0c50186)
