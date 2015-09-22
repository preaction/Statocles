---
tags:
  - release
title: Release v0.046
---

A few new features and a bunch of bugfixes in this release.

Page objects now have a generic "data" attribute. This allows adding miscellaneous
extra information to the Page, which is then available to the template.

Using this, the [Perldoc app](/pod/Statocles/App/Perldoc) now has a crumbtrail
and a link to the module source, and the [blog app](/pod/Statocles/App/Blog) can
now have introductory text for the tags that show up on the tag page.

There were some changes to the default theme to make extending it a bit easier.

* The navbar has a default background color, so putting a background color on
  body is less surprising.
* The grid columns are centered in their margin, so adding a background color
  to the columns looks better.

Finally, a [document](/pod/Statocles/Document) is now allowed to override its
template and layout. The [document page](/pod/Statocles/Page/Document) uses
the document template to override the template provided by the app.

Because of this, we can now allow extra pages in blog posts. Just put the extra page
inside the blog post's directory.

Full changelog below...

---

* [add module crumbtrail to perldoc app](https://github.com/preaction/Statocles/commit/53390e46cf1f78c80397c5537dd4ddacddee8cb7)
* [add link to module source in perldoc app](https://github.com/preaction/Statocles/commit/74fffb6e45f8e822eb45922c1b03e471a1bc3a90) ([#282](https://github.com/preaction/Statocles/issues/282))
* [fix link check showing schema-less urls as broken](https://github.com/preaction/Statocles/commit/cd8c18d92ed4dc231cd2e28e6b3f3de5552e7119) ([#310](https://github.com/preaction/Statocles/issues/310))
* [allow additional markdown pages in blog posts](https://github.com/preaction/Statocles/commit/0ca82131dfc9a76da5894b6ea24a560fdbc97e18) ([#308](https://github.com/preaction/Statocles/issues/308))
* [use document templates to override page templates](https://github.com/preaction/Statocles/commit/303c0a796193848dbb7bf8019ed770b9ac1eb4a4) ([#40](https://github.com/preaction/Statocles/issues/40))
* [add template and layout fields to documents](https://github.com/preaction/Statocles/commit/2b2fbf129f3124b6644d57dd93e82c33313a9ef4) ([#40](https://github.com/preaction/Statocles/issues/40))
* [add tag_text property to blog app](https://github.com/preaction/Statocles/commit/e23be13f39bf9d2d50d537a78075d80bb3c43050) ([#258](https://github.com/preaction/Statocles/issues/258), [#257](https://github.com/preaction/Statocles/issues/257))
* [remove ModuleBuild to prevent toolchain confusion](https://github.com/preaction/Statocles/commit/7aee8f70ca3efb08fc5b187ba0f0500de7813c0c)
* [add .bare class to remove bullets from lists](https://github.com/preaction/Statocles/commit/fe9bd8c38af55bbf2fcdfa0c99475a52c5adbcc8)
* [add data attribute to pages](https://github.com/preaction/Statocles/commit/c5683b560ee5b2d83fb62ced8d036cb01f16efaf) ([#271](https://github.com/preaction/Statocles/issues/271))
* [add a default background color to navbar](https://github.com/preaction/Statocles/commit/0e038a19710c0f42377dfc4929209ae16b6bc822)
* [adjust grid spacing to center columns](https://github.com/preaction/Statocles/commit/8fa054383f1db767c4a80fa2700b1d436e81e687)
* [use file_path attribute when copying files in apps](https://github.com/preaction/Statocles/commit/bf91cb67b693650313d5cc4d06ff4c6e769af7eb) ([#226](https://github.com/preaction/Statocles/issues/226))
* [use raw bytes when opening file pages](https://github.com/preaction/Statocles/commit/a7856d676ee33ea7b2c6f3c2181bbaa3249b0895)
* [allow using file path when copying files](https://github.com/preaction/Statocles/commit/01a37f01d2d314488f47ae24fb0217a8c1c0a67a) ([#226](https://github.com/preaction/Statocles/issues/226))
* [ensure all directory URLs end with a /](https://github.com/preaction/Statocles/commit/096e8f94994020c8a9f8aeb385bb996bb19f328f) ([#299](https://github.com/preaction/Statocles/issues/299))
* [redirect to directory/ in daemon](https://github.com/preaction/Statocles/commit/85809ee620f86cc4591383d25885164d59404428) ([#300](https://github.com/preaction/Statocles/issues/300))
