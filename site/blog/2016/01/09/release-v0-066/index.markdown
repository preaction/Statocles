---
tags: release
title: Release v0.066
---

More fixes for the Highlight plugin, which includes some new features:

* Documents can now properly include files in their directory. So,
  a blog post can `include "example_code.pl"` to show an example,
  without needing to copy/paste the code.

* List pages (the blog index page for example) now combine the scripts
  and stylesheets of their child pages. This makes sure that
  highlighting works correctly on the index page.

Special thanks to [Kent Fredric](http://kentfredric.github.io)
([kentfredric on github](https://github.com/kentfredric), [KENTNL on
cpan](https://metacpan.org/author/KENTNL)) for finding all the bugs in
the highlighter!

Full changelog below...

---

* [fix duplicate links showing up in pages](https://github.com/preaction/Statocles/commit/ac4dda90ed0949dde6c435321ed346b41f858bff) ([#429](https://github.com/preaction/Statocles/issues/429))
* [add uniq_by util to filter items based on a sub](https://github.com/preaction/Statocles/commit/aa57f8909454a31422e64cb545e7b80c105a262d)
* [add child page scripts and styles to the list page](https://github.com/preaction/Statocles/commit/348f419ce3f20e50bbcea96c9249654c3cbf05f3) ([#429](https://github.com/preaction/Statocles/issues/429))
* [fix bad =back in main module documentation](https://github.com/preaction/Statocles/commit/a141554743fa448b30575aaf3bbd755884a707c5)
* [add better error message when include not found](https://github.com/preaction/Statocles/commit/f12c3c0434f144ee09c0dcfda2a819600baad2a4) ([#428](https://github.com/preaction/Statocles/issues/428))
* [add parent dir to includes when rendering document](https://github.com/preaction/Statocles/commit/f9286e730accafc5fa3da0fe74ac589ddf9ba27b) ([#428](https://github.com/preaction/Statocles/issues/428))
* [add store object to the document as its read](https://github.com/preaction/Statocles/commit/14e897e146b06565a77028a1fe1e11b3b4ebfcea) ([#428](https://github.com/preaction/Statocles/issues/428))
* [refactor store document test](https://github.com/preaction/Statocles/commit/b551387d2fd0fca57990f2d9a12f8c349b4ac3e5)
* [add include_stores to template for added includes](https://github.com/preaction/Statocles/commit/961f53b176f8f89c9f9b10cafd79600e86e38a80) ([#428](https://github.com/preaction/Statocles/issues/428))
* [add links to default template helpers](https://github.com/preaction/Statocles/commit/7fd4f26e0230167f8c6de0798fd7fc7f776cc4f9) ([#428](https://github.com/preaction/Statocles/issues/428))
* [fix too much space on the top of highlight blocks](https://github.com/preaction/Statocles/commit/adad407c89eb51540d97b3a65612acfb51e1e84d) ([#431](https://github.com/preaction/Statocles/issues/431))
