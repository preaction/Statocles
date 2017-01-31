---
tags: release
title: Release v0.083
---

A couple additions to this release: A new `status` command, and a new
`-raw` flag to disable the template rendering when using the `include`
helper.

## Added

* The new `statocles status` command shows you a quick status of your
  site, including the last time it was deployed and what date it was
  deployed up to (if different from the last date it was deployed). We
  will be adding more things to this later, so let us know if there are
  any statistics you'd like to know about your site! Thanks
  [@perlancar](http://github.com/perlancar) [[Github
  \#516](https://github.com/preaction/Statocles/issues/516)]

* The `include` helper now accepts a `-raw` flag to disable the template
  renderer. This allows you to easily include Perl code and not have it
  mistaken for a template. Thanks justinQuiring on IRC for the bug
  report [[Github
  \#529](https://github.com/preaction/Statocles/issues/529)]
  
  This isn't the end of this: We will likely fix the heuristics to
  ignore file types (extensions) that do not look like templates. This
  will be a breaking change, sorry.
