---
tags: release
title: Release v0.071
---

A few minor changes in this release:

* The version of [the Beam::Wire dependency injection and configuration
  module](http://metacpan.org/pod/Beam::Wire) we depend on has now
  increased to 1.018 to fix multiple bugs, and also add some useful
  features that will likely be integrated into Statocles's config file
  soon.
* Better error messages when document data is invalid. Now, if you give
  the wrong data type in a document's frontmatter, the error message
  will describe the problem, and which document is broken.
* Speed up index tag sorting. The [Blog's index_tags
  feature](/pod/Statocles/App/Blog/#index_tags) is now 30% faster,
  resulting in a minor overall performance boost.

Full changelog below...

---

* [upgrade Beam::Wire dependency to fix bug](https://github.com/preaction/Statocles/commit/1f410a54ec22bbe72b9b1ca311dde4ba5d3ab710)
* [upgrade Beam::Wire dependency](https://github.com/preaction/Statocles/commit/aff28ddff83918282605843cd04189274ebd8468)
* [fix line reporting for code coverage](https://github.com/preaction/Statocles/commit/7b89026ce920eb25aed3633488c7075863908fab) ([#455](https://github.com/preaction/Statocles/issues/455))
* [speed up index tag sorting by 30%](https://github.com/preaction/Statocles/commit/484cf173d4e0c3f65bb743922f780e7de9d83594)
* [add better error message for document type checks](https://github.com/preaction/Statocles/commit/7bc707f4ef521c18311a716be763f8762ac760a9)
* [make document parse errors more uniform](https://github.com/preaction/Statocles/commit/2900008fbc1e66a6345c7b884c17fdac554b825c)
* [give better error message with invalid date](https://github.com/preaction/Statocles/commit/62f20237d3607aa40ae9390b0e38199401833b12) ([#466](https://github.com/preaction/Statocles/issues/466))
* [update Beam::Wire to fix bug in YAML::XS](https://github.com/preaction/Statocles/commit/e808da7197bca0bc1e146a1fcbe7e81e81eb7216) ([#58](https://github.com/preaction/Statocles/issues/58))
