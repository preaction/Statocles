---
tags: release
title: Release v0.044
---

A few small features, and some small breaking changes in this release.

The `read_document` and `write_document` method of
[Statocles::Store::File](/pod/Statocles/Store/File) now use
[Statocles::Document](/pod/Statocles/Document) instead of plain hashrefs.
It was weird to have one method (`read_documents` with an `s`) get document
objects, and everything else use hashes. The important
serialization/deserialization routines are in Statocles::Document, so it is
likely that more changes will happen around these APIs in the future.

Because of the above change, Stores now have a way to read a document from a string.
So, when a blog post is read from `<STDIN>`, it can contain tags, links, and other
fields, instead of just content.

Some fixes to blog slugs to remove any non-word characters, and also reduce
every replacement to a single dash (`-`), instead of having multiple dashes.
This only affects new posts, not existing posts, so if you want to fix your
current posts, you must fix them manually.

An upgrade to [Beam::Wire](http://metacpan.org/pod/Beam::Wire) now allows you
to compose roles in the Statocles configuration file, so additional behavior
can be added to existing applications. See [the Develop
Guide](/pod/Statocles/Help/Develop) for more information.

Finally, [the Blog app](/pod/Statocles/App/Blog) now has a `recent_posts()`
method that can be used in templates and markdown to display the most recent
posts in a blog.

Full changelog is below.

---

* [add recent posts method to the blog](https://github.com/preaction/Statocles/commit/614dde86658d355e355bdce55df30e79b75af0eb) ([#292](https://github.com/preaction/Statocles/issues/292))
* [read documents on STDIN when adding blog posts](https://github.com/preaction/Statocles/commit/6134683b78d5c13adfba2163358972a3a00eee9d) ([#289](https://github.com/preaction/Statocles/issues/289))
* [fix warning if tags are missing](https://github.com/preaction/Statocles/commit/421be2aa76c19cf56d358d97755296c40a5e6756)
* [change parse_document to parse_frontmatter](https://github.com/preaction/Statocles/commit/4a54056fe8f4dae260dfd277ecef0a644ca498f3)
* [add test with path field inside document](https://github.com/preaction/Statocles/commit/f563ad0114c38dd4cc7bec1da7dee3475eb4c9b4)
* [allow document objects to be written via Store](https://github.com/preaction/Statocles/commit/77a96c422b53043a8c6f207193bebeb042cc20eb)
* [change read_document to return the Document object](https://github.com/preaction/Statocles/commit/8ba720f1fecebfd38a38da8a3d2a38a119472b1f) ([#289](https://github.com/preaction/Statocles/issues/289))
* [add method to parse a document from a string](https://github.com/preaction/Statocles/commit/c3701cfe72ffd51e4143bf644d50bed4da83dd81) ([#289](https://github.com/preaction/Statocles/issues/289))
* [fix blog slugs to remove nonword characters](https://github.com/preaction/Statocles/commit/850613bbe988a2cfb5aac1815fe93475ad4b99d5) ([#290](https://github.com/preaction/Statocles/issues/290), [#291](https://github.com/preaction/Statocles/issues/291))
* [fix example plugin config for Beam::Wire changes](https://github.com/preaction/Statocles/commit/ef3dbb91add9497fc482d18083c72e4ea8919bf2)
* [describe using config to compose roles](https://github.com/preaction/Statocles/commit/668b6600480589678045745a2d30052c954fd961) ([#288](https://github.com/preaction/Statocles/issues/288))
* [add exception when index app does not exist](https://github.com/preaction/Statocles/commit/4dce03edd3a5fc947161ed3af0acc2197b5928ed) ([#287](https://github.com/preaction/Statocles/issues/287))
* [move template tests into a folder](https://github.com/preaction/Statocles/commit/899ae9c59ae988e7c78005bef59baae1f51bf485)
