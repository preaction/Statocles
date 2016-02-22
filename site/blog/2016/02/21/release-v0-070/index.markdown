---
tags: release
title: Release v0.070
---

Some major changes in this release:

We are now using a new date/time module,
[DateTime::Moonpig](http://metacpan.org/pod/DateTime::Moonpig). The
previous module did not support parsing dates before 1900, which means
that document metadata wouldn't be accurate. This unfortunately is
a breaking change, but a warning has been added to deal with the
one major difference between the two date/time modules. See
[Statocles::Help::Upgrading](/pod/Statocles/Help/Upgrading) for details.

All application templates can now be overridden from the site.yml file.
If you want a specific blog app to use a custom RSS feed template, you
can do so:

    blog_app:
        class: Statocles::App::Blog
        args:
            url_root: /blog
            templates:
                index.rss: custom/index.rss

These template paths are relative to your theme directory.

Full changelog below...

---

* [add site pages cache](https://github.com/preaction/Statocles/commit/c6709d60343b8ab92ef29f10b3bc83f578ec7038)
* [plugin docs including template helper example](https://github.com/preaction/Statocles/commit/742e411f79f8aefd5c8732b99a090083612df174) ([#463](https://github.com/preaction/Statocles/issues/463))
* [switch to DateTime::Moonpig for date/time functions](https://github.com/preaction/Statocles/commit/5b7e219328b8a6723c4747e9d72320d95030510e) ([#461](https://github.com/preaction/Statocles/issues/461))
* [rename moniker to template_dir and make explicit](https://github.com/preaction/Statocles/commit/f6ef92e34be4b22682c9b3eacb23eeb56c10b91e) ([#312](https://github.com/preaction/Statocles/issues/312))
* [allow templates to be overridden for each app](https://github.com/preaction/Statocles/commit/20b955a2141831a1bf592495a8648390a678ae60) ([#312](https://github.com/preaction/Statocles/issues/312))
* [Add new collect_pages event, your last chance to change the page list. Split from my original commit.](https://github.com/preaction/Statocles/commit/dcd493e84ae47c5c9a54875bf19701a6e8900781)
