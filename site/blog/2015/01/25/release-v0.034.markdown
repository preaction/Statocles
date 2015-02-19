---
last_modified: 2015-01-25 00:19:48
tags: release
title: Release v0.034
---

Lots of breaking changes in this release, in our ramp-up to the [beta
announcement](https://github.com/preaction/Statocles/milestones/beta).

The biggest change in this release is the new [Deploy object](/pod/Statocles/Deploy.html).
The deploy object handles deploying the site to a folder or a Git repository. Future
possibilities include rsync or FTP, or any command at all.

*NOTE:* This change breaks your site.yml file, so please read [the config help
file](/pod/Statocles/Help/Config.html) to fix it.

Some major theme changes were also added, and a new default theme (using [the
Skeleton CSS library](http://getskeleton.com)) was added, removing the need for
Bootstrap (too big) from a CDN.

The theme is now always deployed with the site, always taking the `/theme` URL
path. This allows you to add extra files, CSS, JavaScript, and otherwise, to your
theme.

The template variables were cleaned up to remove a lot of hashrefs and arrayrefs in favor
of methods and objects, giving us some type checking and cleaner template code.

There are now generic `data` attributes on the Site and App objects so you can add
any random data you want that can then be used in the templates. Expect upcoming
themes to make good use of this feature!

Full changelog continues below.

---

* [add dzil plugin for prereqs and compile tests](https://github.com/preaction/Statocles/commit/704df95465b847d3b5e88e0927421213ac333b99) ([#224](https://github.com/preaction/Statocles/issues/224))
* [add features and install instructions on home page](https://github.com/preaction/Statocles/commit/e1f18b0a1812f2b0796675293d215336b7ac7c08) ([#150](https://github.com/preaction/Statocles/issues/150))
* [update Statocles site for new default theme](https://github.com/preaction/Statocles/commit/a7755bddeaeb70f0c49d0ead818e8610044f49e1)
* [update Statocles site for new Git deploy](https://github.com/preaction/Statocles/commit/164d4f82a2860d981916b4018220a62c244d28ed)
* [remove deploy path from the daemon](https://github.com/preaction/Statocles/commit/1ebed7ede020e169dad1c68b04f364d24600ddcc)
* [do not try to find the t directory from lib](https://github.com/preaction/Statocles/commit/30416350f08772a5d02d75f4eddf4743a6508035)
* [remove circular dependency creating infinite loop](https://github.com/preaction/Statocles/commit/475a775a40b51b8878ec9e3df3988866cc195675)
* [add see also sections for theme help](https://github.com/preaction/Statocles/commit/3cdc5fd83beb5c6e926fe09142a1aabb922b190b)
* [add theme help file](https://github.com/preaction/Statocles/commit/63b2772f9a2da9087f0727de06e57b7bc3e5e0af) ([#108](https://github.com/preaction/Statocles/issues/108))
* [explicitly require ".ep" when including templates](https://github.com/preaction/Statocles/commit/f652aca56c575ca816c3670de87ca5fa92bd413e)
* [add deploy object to site](https://github.com/preaction/Statocles/commit/676e6269dcd3a077d7fba93017d1aba6eb7419e2) ([#63](https://github.com/preaction/Statocles/issues/63))
* [make sure to create the directory before deploying](https://github.com/preaction/Statocles/commit/11a0ad6c81afa9fbe497a13370338be50c58f6f4)
* [reduce duplication between Git and File deploy](https://github.com/preaction/Statocles/commit/4c354a2f51441be8e3c52578855fde0fa00cc7c3)
* [add a file deploy for deploying to the filesystem](https://github.com/preaction/Statocles/commit/99d7b8767cc085e0e6f9259aeb88b4ce9ee1ffa8)
* [add deploy class to deploy a site](https://github.com/preaction/Statocles/commit/94b76b51b0b139be9efcb1d651c3bdc2128d51d9) ([#63](https://github.com/preaction/Statocles/issues/63))
* [add base_url to Store for per-deploy base URLs](https://github.com/preaction/Statocles/commit/d29dc192db587420a3abef94a58dc7cf9e4c2396) ([#117](https://github.com/preaction/Statocles/issues/117))
* [make author optional](https://github.com/preaction/Statocles/commit/f65b17adca3f429b7fda0f606d1eddf6ee945c14) ([#197](https://github.com/preaction/Statocles/issues/197))
* [rename "crosspost" to "alternate"](https://github.com/preaction/Statocles/commit/7886f23fbe0fe12b57c263ca348dc6d94f462ecf) ([#221](https://github.com/preaction/Statocles/issues/221))
* [remove all uses of document in templates](https://github.com/preaction/Statocles/commit/7b647f2a086a1075cefa10c26b9188375ddea68c) ([#220](https://github.com/preaction/Statocles/issues/220))
* [change tags to Link objects](https://github.com/preaction/Statocles/commit/059d0d6341082c37ae91c1c284d5e376c53b00dc)
* [change page links and tags into Link objects](https://github.com/preaction/Statocles/commit/9b31948dc56777d965c68f212756f0a6f639b717)
* [fix coercion for links array](https://github.com/preaction/Statocles/commit/cc48c289b17179453d08ac2da3e84318fc796edd)
* [allow single link to be normalized into an array](https://github.com/preaction/Statocles/commit/ff8be49812cae651334678ccb0d5b874aeca88a0)
* [add nav method to get site nav links](https://github.com/preaction/Statocles/commit/9bb5f84495f4227f50fcf45e1b3abeb1aa0285a0) ([#97](https://github.com/preaction/Statocles/issues/97))
* [add Link object to represent <a> and <link> tags](https://github.com/preaction/Statocles/commit/12cc843912a269f86ec5e550048547a4987fb7dc) ([#98](https://github.com/preaction/Statocles/issues/98))
* [add missing sidebar example code](https://github.com/preaction/Statocles/commit/c5edad3b98e033886a2d5e7858ad6b5400ba7dbe)
* [add some padding around floated images](https://github.com/preaction/Statocles/commit/33c001f6073d09c3e4c874f50b50e7fee9765c3d)
* [fix sidebar different from blog list to blog post](https://github.com/preaction/Statocles/commit/db9d384bd3169be4fa3c0a5f060978a21d7eb345)
* [rearrange style guide to organize by usage](https://github.com/preaction/Statocles/commit/cf75f66fdb66e0b18a599605373acd84c33393d1)
* [add new default theme based on skeleton.css](https://github.com/preaction/Statocles/commit/b85d8ff1e35a345b9adfa1b409f41a88cddf7122) ([#175](https://github.com/preaction/Statocles/issues/175))
* [add data attribute to site and app](https://github.com/preaction/Statocles/commit/c3a30d3e994aacafd33a5f1209a2f10c4bb369d2) ([#209](https://github.com/preaction/Statocles/issues/209))
* [fix deploy test to test deploy directory](https://github.com/preaction/Statocles/commit/3b8ee13928e5da03390e2bb22ed3333cf54f9f07)
* [add theme to deployed site at /theme](https://github.com/preaction/Statocles/commit/9e5fd0a2e4842ce5e080a49d198ede04be2ffbdc) ([#193](https://github.com/preaction/Statocles/issues/193))
* [add better error message when template not found](https://github.com/preaction/Statocles/commit/8699a338c2b4a66c141511150047575ba38ef40b) ([#205](https://github.com/preaction/Statocles/issues/205))
* [ensure index app generates a page](https://github.com/preaction/Statocles/commit/eaabd47e849ad69dd5419ea4d177fcc991852133) ([#202](https://github.com/preaction/Statocles/issues/202))
* [create orphan branch when deploying](https://github.com/preaction/Statocles/commit/18a805032423bd9cea0c20e6906c53459e5485e0) ([#207](https://github.com/preaction/Statocles/issues/207))
