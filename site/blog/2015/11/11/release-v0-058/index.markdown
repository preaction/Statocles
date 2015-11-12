---
tags: release
title: Release v0.058
---

This release fixes a major regression from v0.056: The extra theme files
were not being correctly rendered, instead being replaced with
`Statocles::Page::File=HASH(...)`.

We also fixed another regression: The site `create` command has been
broken for an unknown amount of time, dying with an error message `Can't
locate object method "new" via package "Statocles::Template"`.

In better news: A [new HTML linter
plugin](/pod/Statocles/Plugin/HTMLLint) is available if you want some
basic checks to ensure your HTML is correct before you deploy your site.
This isn't using the [W3C](http://w3.org) validators (that's a future
plugin), but it can do quick checks for well-formedness.

Full changelog below...

---

* [correctly render theme include files](https://github.com/preaction/Statocles/commit/fb192c8e6d0b937db4bc47cfbaa763772c706395) ([#399](https://github.com/preaction/Statocles/issues/399), [#402](https://github.com/preaction/Statocles/issues/402))
* [fix "Can't locate method new" error in create](https://github.com/preaction/Statocles/commit/8ae3ebfd86ff001819c34ec6491915490470353c) ([#403](https://github.com/preaction/Statocles/issues/403))
* [do not load site class for every test](https://github.com/preaction/Statocles/commit/489a60cadda0753cfa22a927beb9ddfa8fc4359c) ([#403](https://github.com/preaction/Statocles/issues/403))
* [add html lint plugin](https://github.com/preaction/Statocles/commit/2cad95146189e8e9acc8071d05606d49e934cea8) ([#401](https://github.com/preaction/Statocles/issues/401))
