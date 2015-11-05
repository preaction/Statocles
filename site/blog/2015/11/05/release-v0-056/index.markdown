---
tags: release
title: Release v0.056
---

Some minor features and bugfixes in this release:

* Themes will no longer deploy their template files with the rest of the
  site. This protects your templates from being read or stolen.

* The [Blog application tag descriptions (`tag_text`)](/pod/Statocles/App/Blog#tag_text)
  is now processed as Markdown, so your tag pages can have links,
  headers, and other stuff.

* There is a [new guide to resolving error
  messages](/pod/Statocles/Help/Error). It's only got some
  config-related errors right now, but it will grow as time goes on.

* Related to that, configuration errors are now detected and possible
  resolutions suggested. A new version of
  [Beam::Wire](https://metacpan.org/pod/Beam::Wire) makes it easier to
  detect when the config file has a problem with parsing.

* Finally, links to internal parts of Perldoc files (like
  `L<My::Module/SECTION>` are now fixed.

Full changelog below...

---

* [fix inner links do not work in perldoc app](https://github.com/preaction/Statocles/commit/4ab13e626460b36b68ba0746d2c9f234117e1bc3) ([#366](https://github.com/preaction/Statocles/issues/366))
* [add better error messages for bad config files](https://github.com/preaction/Statocles/commit/8264adbadc26ebe6ca51fea7306055bf167273d2) ([#394](https://github.com/preaction/Statocles/issues/394))
* [add guide to help resolve error messages](https://github.com/preaction/Statocles/commit/69cecc44b91fb116656da42cce1f45454b68c615) ([#394](https://github.com/preaction/Statocles/issues/394))
* [update Pod::Simple required version](https://github.com/preaction/Statocles/commit/ac20fc271e065d2f31eb7064792d02e26bca4c7e) ([#349](https://github.com/preaction/Statocles/issues/349))
* [fix problem with overriding Moo role attributes](https://github.com/preaction/Statocles/commit/0dea9e34239989884f94382d0d2dd3c2abc07207)
* [do not deploy template files with the site](https://github.com/preaction/Statocles/commit/06cb9fe0c033ba3be1c743601d3084cb09254d01) ([#399](https://github.com/preaction/Statocles/issues/399))
* [make Theme into an App](https://github.com/preaction/Statocles/commit/2c8d3d465f3e144a7b94236327a4cad0aa854e08) ([#399](https://github.com/preaction/Statocles/issues/399))
* [move theme test to appropriate directory](https://github.com/preaction/Statocles/commit/629457d50fe932f2865f82ee45b1b30858887bdd)
* [add config examples for all blog attributes](https://github.com/preaction/Statocles/commit/e9f15c9cd82b9953bab46e2b93df07ff406110f5) ([#396](https://github.com/preaction/Statocles/issues/396))
* [process Blog tag text as Markdown](https://github.com/preaction/Statocles/commit/9ba3046cb5e9ce0113174c9858ef8508a6c07408) ([#397](https://github.com/preaction/Statocles/issues/397))
* [add markdown template helper](https://github.com/preaction/Statocles/commit/1e635e65609aaa0b1c66775486146ed6161c3591) ([#258](https://github.com/preaction/Statocles/issues/258))
* [mark plain/static apps as deprecated](https://github.com/preaction/Statocles/commit/0b542ad3660590d76e948b7bf822297652e07afd) ([#395](https://github.com/preaction/Statocles/issues/395))
