---
tags: release
title: Release v0.062
---

This release adds a [new Plugin architecture](/pod/Statocles/Plugin) and
a [new plugin for code syntax
highlighting](/pod/Statocles/Plugin/Highlight).

This release also fixes HTML escaping in the page title, so titles can
safely contain `<`, `>`, and `&` without issue.

Full changelog below...

---

* [update develop help guide for new plugin class](https://github.com/preaction/Statocles/commit/8131c4c7eaa194804d7b1dee9cdf931cf3a8208a)
* [fix site creator to use plugins not event handler](https://github.com/preaction/Statocles/commit/cc87fd28d49d91a653751e8cb4b03cc830767533)
* [make existing plugins consume new plugin role](https://github.com/preaction/Statocles/commit/fb8e940dd92fd4c7960c87bc64ac6ccb0b126c9a)
* [add plugins to main module list](https://github.com/preaction/Statocles/commit/a17ad19e75874d184d698e3a1bb48286b04280fe)
* [pass the current page into document templates](https://github.com/preaction/Statocles/commit/a8477bd74b14a4a17489efe1e03630db0a7af394)
* [add plugin docs to the help guides](https://github.com/preaction/Statocles/commit/610d6bcf2ba3db9de9724e8466711006c016a3c0)
* [add highlight plugin to statocles project site](https://github.com/preaction/Statocles/commit/954163f76ceeda57d7f8d01ae593e266d2b442d4)
* [fix highlight plugin to work with begin/end](https://github.com/preaction/Statocles/commit/6564e6c28b5a513e96fc7957af3f1741d845b7a7)
* [allow project website to be viewed on localhost](https://github.com/preaction/Statocles/commit/adbc479ad2556dd414b5176e834e21df6cff8ff2)
* [add syntax highlighting plugin](https://github.com/preaction/Statocles/commit/dd0ab354dd61db5e31f42a20cd2e6d03ab4d32d0) ([#407](https://github.com/preaction/Statocles/issues/407))
* [allow adding links to pages](https://github.com/preaction/Statocles/commit/6806efe8cf865fd78ccdd6f493ef4ed746071f69)
* [allow coercing link objects from strings](https://github.com/preaction/Statocles/commit/e51b4b9d3ae14d57fd542b721a0dd05aeb735bbf)
* [add site plugins](https://github.com/preaction/Statocles/commit/a9bd68e62cab655f7e94993c8ce3997e937eac45) ([#406](https://github.com/preaction/Statocles/issues/406))
* [add custom helpers to theme object](https://github.com/preaction/Statocles/commit/e2ce3ff2558494d9cecbd57499c568ba93e7d95a) ([#406](https://github.com/preaction/Statocles/issues/406))
* [escape document title to fix special characters](https://github.com/preaction/Statocles/commit/723f97c6751c3aa907475693b1b72fba50d65598) ([#422](https://github.com/preaction/Statocles/issues/422))
* [switch to warn that a store path doesn't exist](https://github.com/preaction/Statocles/commit/dfcbe45a2cffbf4fc36296d1b033e3428775dd12) ([#414](https://github.com/preaction/Statocles/issues/414), [#421](https://github.com/preaction/Statocles/issues/421))
* [fix doc links in default content](https://github.com/preaction/Statocles/commit/c713ab5581612f709489b0d7c2809d5de0201e19) ([#419](https://github.com/preaction/Statocles/issues/419))
* [remove unneeded reminder to update theme config](https://github.com/preaction/Statocles/commit/dae482d9ec610dcda9eae40cafabf0039c181359) ([#415](https://github.com/preaction/Statocles/issues/415))
* [add helper examples to the template documentation](https://github.com/preaction/Statocles/commit/5c296f77d50b23b4fc3dbfde843f00792e24e901)
* [add content template helper](https://github.com/preaction/Statocles/commit/e876d4a055b7b8426fbf7437b6f35e6b31d7376a) ([#416](https://github.com/preaction/Statocles/issues/416))
* [fix homepage meta data](https://github.com/preaction/Statocles/commit/2a881fe5049e0bb2ca25423c53b5dd7fa25dfa52)
