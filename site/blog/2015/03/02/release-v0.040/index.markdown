---
last_modified: 2015-03-02 00:05:10
tags: release
title: Release v0.040
---

The biggest new thing in this release is the new [LinkCheck
plugin](/pod/Statocles/Plugin/LinkCheck.html) that checks all the pages for
broken links and images. This introduces a new event-handling API into
Statocles, which will be called Plugins. See [the developer
docs](/pod/Statocles/Help/Develop.html) for more information on plugins.

A bunch of bug fixes for the `create` command. It now actually works, instead
of creating an unusable `site.yml` file.

The default build directory is now `.statocles/build` instead of `.statocles-build`.
It is anticipated we might use the `.statocles` directory for some additional
site metadata.

With [Mojolicious](http://mojolicio.us) 6.0 release, there were a few breaking
changes that we needed to fix in Statocles. We now require 6.0.

Full changelog below:

---

* [fix linkcheck synopsis for new wire config syntax](https://github.com/preaction/Statocles/commit/dc60ccf4bbb1dcba1100c5ba9e1c1b6c4a304b4d)
* [add documentation for events and plugins](https://github.com/preaction/Statocles/commit/349c0020ddb49f1e2ebb48ccf1cf6af703e1b485)
* [add linkcheck plugin to Statocles website](https://github.com/preaction/Statocles/commit/de42da3051ae7e150e1781ae484645958d834a77)
* [add LinkCheck plugin to the default site creator](https://github.com/preaction/Statocles/commit/55d26d3b0da71836dcbcce73fee769b4d067a3e4) ([#78](https://github.com/preaction/Statocles/issues/78))
* [add LinkCheck plugin to check links and images](https://github.com/preaction/Statocles/commit/ed3ae8bcc3dba987740bd2d62fb26bfc7871709d) ([#78](https://github.com/preaction/Statocles/issues/78))
* [add build event hook to site](https://github.com/preaction/Statocles/commit/473566b53e54cec1e406afe862b46df5fcf67e66) ([#78](https://github.com/preaction/Statocles/issues/78))
* [remove unnecessary includes in tests](https://github.com/preaction/Statocles/commit/4e24f06cdc883490fa1696394e53207bb57ba2bd)
* [add '.statocles' to gitignore automatically](https://github.com/preaction/Statocles/commit/71ae827e21ac2b1fb8b9b367a5be34f3c4356e7c) ([#265](https://github.com/preaction/Statocles/issues/265))
* [fix blog with no pages doesn't build](https://github.com/preaction/Statocles/commit/14adfea03e1dda33dfdcc66c9bbbe6950a79a9d2) ([#144](https://github.com/preaction/Statocles/issues/144))
* [init the git repo when creating a git-based site](https://github.com/preaction/Statocles/commit/66156f37512a7f1e0027e377679e6940797b185e) ([#270](https://github.com/preaction/Statocles/issues/270))
* [upgrade to Mojolicious 6.0](https://github.com/preaction/Statocles/commit/e36ddd82f5a8771a07cae2050dd2eef90f099cac)
* [add note about base_url to deploy guide](https://github.com/preaction/Statocles/commit/90b959a61d7e7bc9a1ccf32f8ec70678f00a3878)
* [set a sane default base url](https://github.com/preaction/Statocles/commit/eb3f7b5b3bb1824973f0580144e7614c4661dd8a) ([#263](https://github.com/preaction/Statocles/issues/263))
* [fix base_url of / breaks links](https://github.com/preaction/Statocles/commit/4e415647f05aba43e8f8474c4561c6b5c8ef502f) ([#264](https://github.com/preaction/Statocles/issues/264))
* [create the app store directories in create command](https://github.com/preaction/Statocles/commit/1fe322c1529cd7873b1b74386f94e5c216eec074) ([#262](https://github.com/preaction/Statocles/issues/262))
* [fix create command creates wrong apps](https://github.com/preaction/Statocles/commit/b5a2962e1aa09bea3f89a29d3a7ba502989b1e15) ([#261](https://github.com/preaction/Statocles/issues/261))
* [move default build dir to .statocles/build](https://github.com/preaction/Statocles/commit/280440344bd23160a8dd896994bba1c9672ea246) ([#266](https://github.com/preaction/Statocles/issues/266))
* [fix unknown command gives strange error](https://github.com/preaction/Statocles/commit/db07fa612690d155938b7cf99c6a537bbf4fc6e9) ([#267](https://github.com/preaction/Statocles/issues/267))
* [remove all files from build dir before building](https://github.com/preaction/Statocles/commit/011250435a6c515c2d8018e6f52c56be283bf4a9) ([#252](https://github.com/preaction/Statocles/issues/252))
