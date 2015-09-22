---
tags:
  - release
title: Release v0.055
---

We're in the [run up to v1.0, the first stable
release](https://github.com/preaction/Statocles/milestones/v1.000). As a
result, there were quite a few deprecations in this release, and a lot
of new features.

## Breaking Changes

* The [Perldoc app](/pod/Statocles/App/Perldoc) now creates folders
  instead of files for the POD. This means the link to `My::Module` will
  now be `/My/Module` and not `/My/Module.html`.

  This is being done outside a deprecation policy in the hope that
  nobody's started using the app extensively enough to be hurt. Having
  both sets of pages (.html and non-.html) was deemed too much for a
  non-stable release. If something like this happens after v1.0, we will
  build both sets of pages (with a switch to turn off the old set).

## Deprecations

* The [Static app](/pod/Statocles/App/Static) and
  [Plain app](/pod/Statocles/App/Plain) are both deprecated in favor of
  the new [Basic app](/pod/Statocles/App/Basic). The Basic app has all
  the functionality of both the Static and Plain apps.

  Using either the Static or Plain apps will give a warning. To fix this
  warning, change the app's `class` to `Statocles::App::Basic`. See
  [Statocles::Help::Upgrading](/pod/Statocles/Help/Upgrading) for
  details.

* The [File store](/pod/Statocles/Store/File) is now just
  [Statocles::Store](/pod/Statocles/Store). Likely this requires no
  changes in your config, unless you've referenced
  `Statocles::Store::File` directly (just change it to
  `Statocles::Store` to silence the deprecation warnings).

* The [Store write_document method](/pod/Statocles/Store#write_document)
  used to return the full path to the document written. This was
  confusing, as one generally does not expect a write method to return
  anything (unless it's a true/false value for success/failure). As of
  right now, you can get the document path by calling the `child()`
  method of the [Store's path attribute](/pod/Statocles/Store#path).

## New Features

* There is a new [Basic app](/pod/Statocles/App/Basic). This application
  supports Markdown files and collateral images and files. It is the
  basic functionality of all Statocles apps.

* The default themes now support Disqus. [Disqus](http://disqus.com)
  allows adding comments even to otherwise static websites. Until the
  [Dynamocles project](http://github.com/preaction/Dynamocles) allows
  for a dynamic partner to Statocles sites, Disqus is an easy way to
  provide some user engagement.

* If you want extra frontmatter document metadata, you can now create
  your own [Statocles::Document](/pod/Statocles/Document) sub-classes,
  and refer to them in your frontmatter using `class: 'My::Document'`.

  This enables you to add custom attributes and other such to your
  documents. It could also allow for non-Markdown documents, and other
  interesting things in the future.

* The site creator command (`statocles create`) now creates a
  fully-ready site with skeleton content. The configuration file it
  creates now comes with comments to make it easier to edit.

* [Plugins](/pod/Statocles/Help/Develop) can now be added to individual
  applications, because [every app now comes with a `build`
  event](/pod/Statocles/App#EVENTS). If you only want to check links on
  a single application, or if you want to modify the application's pages
  without writing an entire app subclass, this is a good way to do it.

* When writing pre-dated entries, to be posted sometime in the future,
  there is now a way to test how the site will look in the future when
  that post is deployed.

  Using the `--date` option to `statocles build`, `statocles daemon`,
  and `statocles deploy` will render the site as though it was the given
  date. See the `statocles help` command for more information.

Full changelog below...

---

* [fix cleanup warning during global destruction](https://github.com/preaction/Statocles/commit/d8692b990194d6c22bbadf39b2722ecc007d763c)
* [add disqus setup notes to Config guide](https://github.com/preaction/Statocles/commit/b25d9d2d82e0cd3fe981dadd5a592373efc42d3e) ([#109](https://github.com/preaction/Statocles/issues/109))
* [replace the Static app with the Basic app](https://github.com/preaction/Statocles/commit/a6f9ee33a7953c462748957fc95d789b6acd2d9c) ([#380](https://github.com/preaction/Statocles/issues/380))
* [rename the Plain app to the Basic app](https://github.com/preaction/Statocles/commit/02b3d3b7c0d9efbca5a848d60cf3e8b1d762423d) ([#380](https://github.com/preaction/Statocles/issues/380))
* [refactor Blog app to use Store app role](https://github.com/preaction/Statocles/commit/4504fe0d501b965da7e5ba1faeb2868523b8aaa0) ([#343](https://github.com/preaction/Statocles/issues/343))
* [allow writing most page attributes](https://github.com/preaction/Statocles/commit/db9ca5f711f76669b5a2470e8938ffcbefec0236)
* [skip hidden files and directories in the Plain app](https://github.com/preaction/Statocles/commit/6a6d21ac9acd8b7dccc27363b4e176778733bb5f)
* [add static content to Plain app](https://github.com/preaction/Statocles/commit/4a453c285020985447263b9223bc7413335a73d9) ([#343](https://github.com/preaction/Statocles/issues/343))
* [fix doc links to show module being linked to](https://github.com/preaction/Statocles/commit/4156aa3efcf4f1ba52ec2f2e9add3ff5898fd075)
* [add custom markdown object example to config guide](https://github.com/preaction/Statocles/commit/90a7b8fa2964c057b459adc29cec6ae345bf4784) ([#389](https://github.com/preaction/Statocles/issues/389))
* [add disqus blocks to the default themes](https://github.com/preaction/Statocles/commit/54a2e91f0992fad9ec6dad4b637fe9194035e68b) ([#109](https://github.com/preaction/Statocles/issues/109))
* [add store role for applications that use stores](https://github.com/preaction/Statocles/commit/402c2807e28d557ae0f2f391158b4b86bc2992db) ([#343](https://github.com/preaction/Statocles/issues/343))
* [use run_editor helper in blog and plain apps](https://github.com/preaction/Statocles/commit/1ad4d17c0a6645eeb3a74a5704de55f555dec611) ([#212](https://github.com/preaction/Statocles/issues/212))
* [add run_editor utility to invoke the user's editor](https://github.com/preaction/Statocles/commit/ae718ea603128dd4d6240eed1e1be6ddeb26b1f9) ([#212](https://github.com/preaction/Statocles/issues/212))
* [fix new-post directory getting left behind in blog](https://github.com/preaction/Statocles/commit/7cc294da73ca7cc522a3a799d1a21e1aafbc9d37) ([#295](https://github.com/preaction/Statocles/issues/295))
* [test that the interactive editor is invoked](https://github.com/preaction/Statocles/commit/99a0c283f8c381dfef79ed62b745aa31ce0629b2)
* [add class frontmatter for custom document classes](https://github.com/preaction/Statocles/commit/1b1504105ce9214e98126ba24532f3f4431e9024) ([#48](https://github.com/preaction/Statocles/issues/48))
* [add error if repository has no commits](https://github.com/preaction/Statocles/commit/8967da098d54ba872ed8a5b4b1ea7c03e63bf397) ([#386](https://github.com/preaction/Statocles/issues/386))
* [move daemon build inside the mojo app](https://github.com/preaction/Statocles/commit/b21297f6515710f70f8e6ba9520546bfc5303214)
* [add --date option to build, daemon, and deploy](https://github.com/preaction/Statocles/commit/12b51c895bad0ba44e0a8efc117e65d6e35bf7af) ([#246](https://github.com/preaction/Statocles/issues/246))
* [fix daemon shutdown and cleanup to remove cycles](https://github.com/preaction/Statocles/commit/2fa25ce4b4e818b0e8d13dfa726fd38f7f50fca6)
* [add default site title to silence warnings](https://github.com/preaction/Statocles/commit/92c674f5fd4f1e1fa6aa02f3b8054e00eb3bfa28)
* [add --message option to the deploy command](https://github.com/preaction/Statocles/commit/aa635852327be05d8ad1bef0ac328ce6080c08c5) ([#34](https://github.com/preaction/Statocles/issues/34))
* [allow plain hashrefs in test app](https://github.com/preaction/Statocles/commit/344b56b13189b61d2100c75824a177264012718d)
* [add test for git deploy message option](https://github.com/preaction/Statocles/commit/6cc0ac4d0b04e73a1169022ae0dc557fc3b1a437) ([#34](https://github.com/preaction/Statocles/issues/34))
* [fix tag links in blog feeds into full urls](https://github.com/preaction/Statocles/commit/a533a40b9a14f3c443fec146051cfa4a9a8f64eb) ([#385](https://github.com/preaction/Statocles/issues/385))
* [clean up test to remove warnings from log](https://github.com/preaction/Statocles/commit/ddd5f66e60989443c9029def761a90c0721876f4)
* [add --clean option to statocles deploy command](https://github.com/preaction/Statocles/commit/c48fb92ed3fea2ea0795ffd44ff4cf317f2956c3) ([#71](https://github.com/preaction/Statocles/issues/71))
* [add clean option to file and git deploys](https://github.com/preaction/Statocles/commit/25023190fc9bc81907c0327b5db86bc45c800c49) ([#71](https://github.com/preaction/Statocles/issues/71))
* [remove ".html" from Perldoc documentation pages](https://github.com/preaction/Statocles/commit/d85047aa3209fd4a4959d2ede56e41e614113c4a) ([#367](https://github.com/preaction/Statocles/issues/367))
* [clarify index path missing to show possible remedy](https://github.com/preaction/Statocles/commit/67f4719bc72fddd222890d02930f959ab75c8ab4) ([#363](https://github.com/preaction/Statocles/issues/363))
* [move all deprecation tests into one place](https://github.com/preaction/Statocles/commit/7144d7f7cd68f820771a3d244ccc044c72dd44b8)
* [deprecate write_document method return value](https://github.com/preaction/Statocles/commit/c09f1f5ee62591edb88852f6b3612488a71393b8) ([#382](https://github.com/preaction/Statocles/issues/382))
* [skip deprecated module in compile test](https://github.com/preaction/Statocles/commit/01e3f566c39a756f980bd2951e62e561d3592dd0)
* [remove docs implying deploys inherit from stores](https://github.com/preaction/Statocles/commit/3ddafbcb2c52b4fae16a80a6f2bd0c56ec47a675) ([#383](https://github.com/preaction/Statocles/issues/383))
* [move Statocles::Store::File to Statocles::Store](https://github.com/preaction/Statocles/commit/2ef4c8e3c3ff6e3fbd2c5c8376dcf688f32fb21d) ([#381](https://github.com/preaction/Statocles/issues/381))
* [only set version during test if no version exists](https://github.com/preaction/Statocles/commit/c01b4fd76b42b43ea0876d3148e85727ac816927)
* [fix emitter base bundle not applying](https://github.com/preaction/Statocles/commit/f35619c6ca85589f3d0168a5d732175f04660ed9)
* [add edit command to plain app](https://github.com/preaction/Statocles/commit/f7d7a8ab3555d6934799dda7ac8fb65763deb719) ([#338](https://github.com/preaction/Statocles/issues/338))
* [add date option to build blog pages from the future](https://github.com/preaction/Statocles/commit/67d8930491543177bd101ee22e0fe1c4fe3b0946) ([#246](https://github.com/preaction/Statocles/issues/246))
* [add better error message when app has no commands](https://github.com/preaction/Statocles/commit/a4e4aa5e6f198f14d96599a4df7338707e7ba050) ([#379](https://github.com/preaction/Statocles/issues/379))
* [add remove method to Store](https://github.com/preaction/Statocles/commit/3ad51d40a1313d316c70ac008c1ce367ff61a217) ([#196](https://github.com/preaction/Statocles/issues/196))
* [generate the site config from the template](https://github.com/preaction/Statocles/commit/e0cf8d6aba17a043e65e4c27393d85016134945e) ([#324](https://github.com/preaction/Statocles/issues/324))
* [add comments to the site creator config file](https://github.com/preaction/Statocles/commit/658da7977339a694116ce57b1d25f7219716d663) ([#324](https://github.com/preaction/Statocles/issues/324))
* [change title to text in site creator link](https://github.com/preaction/Statocles/commit/6d4378354c0280b3c85e5eee5b4570fa9ab87708)
* [add note about how to use default themes](https://github.com/preaction/Statocles/commit/b61f597f1bea682b75e34dbaef5d374dcad09152)
* [add skeleton site content during site creation](https://github.com/preaction/Statocles/commit/28cda3dbd4f5774be60554225372cdbeb5c5bf53) ([#362](https://github.com/preaction/Statocles/issues/362))
* [add $app and $site to all templates](https://github.com/preaction/Statocles/commit/98d6ae4f5337b693eaf310c0aa56ccfe1947f667)
* [expand document documentation to add examples](https://github.com/preaction/Statocles/commit/a73f058bc11b1355d416db6f521a81da46402d9c) ([#368](https://github.com/preaction/Statocles/issues/368))
* [fix a bunch of misspellings in the documentation](https://github.com/preaction/Statocles/commit/7eddbf5fe7895a8f527c78db93c3da5ed6c63688)
* [remove duplicate test app](https://github.com/preaction/Statocles/commit/49618494e0eb2f5f214630e94c13b314fdb9ed74) ([#319](https://github.com/preaction/Statocles/issues/319))
* [add build event to apps for plugins to edit pages](https://github.com/preaction/Statocles/commit/45578a8524ffc6dea777368e872b18ec392e4b9d) ([#276](https://github.com/preaction/Statocles/issues/276))
