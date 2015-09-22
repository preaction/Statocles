---
tags:
  - release
title: Release v0.054
---

Some important v1.0 changes here.

* All pages now have a title, which means that we can have the page
  title in the `<title>` tag for better bookmarks
* Documents can add stylesheets and scripts, for those times when the
  content needs special design or interactivity. See [the Document
  object documentation](/pod/Statocles/Document) for more
  information.
* Template includes are now cached, which should dramatically improve
  the site build times. There is still a lot to do about performance,
  but this was a quick change.
* Templates can now be arbitrarily nested. Previously, the API only
  allowed for a single level of depth, called the "category". Now,
  templates are simply given a full path, and organization is up to the
  app developer and theme author.

Full changelog below...

---

* [move includes to theme and add caching](https://github.com/preaction/Statocles/commit/a19975ad5998435045faab2d753403d1222822e2) ([#377](https://github.com/preaction/Statocles/issues/377), [#378](https://github.com/preaction/Statocles/issues/378))
* [refer to templates by path for more flexibility](https://github.com/preaction/Statocles/commit/b43cf83e0edb2ef596688af8de6ebefb6f295c9c) ([#313](https://github.com/preaction/Statocles/issues/313))
* [add page title to <title> tag in default themes](https://github.com/preaction/Statocles/commit/848fee6650f60040ab50209c0aa5cdd35668a2dd) ([#372](https://github.com/preaction/Statocles/issues/372))
* [allow documents to add stylesheets and scripts](https://github.com/preaction/Statocles/commit/f098c2a090ff5c248978ddffcc064ebd611afc07) ([#376](https://github.com/preaction/Statocles/issues/376))
* [allow links without text](https://github.com/preaction/Statocles/commit/b27cb6a574b1185e08cf8aa7835f291a30caa492) ([#376](https://github.com/preaction/Statocles/issues/376))
* [move title attribute to page role](https://github.com/preaction/Statocles/commit/6b5935ec6557dc9230997f0a7803f60c04e6444a) ([#372](https://github.com/preaction/Statocles/issues/372))
* [fix abstracts on Statocles::Page](https://github.com/preaction/Statocles/commit/6e8953b5111ec2ddc87e064caac3f3eb4f568787) ([#370](https://github.com/preaction/Statocles/issues/370))
* [upgrade Path::Tiny to fix mkpath warning](https://github.com/preaction/Statocles/commit/5109769b42f7256f84663c5b83ed0ff51f605c42) ([#369](https://github.com/preaction/Statocles/issues/369))
