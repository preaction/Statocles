---
tags: release
title: Release v0.041
---

A slight breaking change in this release: The "last modified" date is no longer being
used in the blog. Instead, the date shown is only the slug date, which makes the date
more accurate when pre-dating posts.

The `last_modified` attribute is now simply called `date`, which makes it a bit more
general-purpose. This means that you'll need to re-bundle your templates.

A change to [Beam::Wire](http://metacpan.org/pod/Beam::Wire) means a change to Statocles
config files: `$method` in the event handlers is now `$sub`, so if you have configured
the LinkCheck plugin, you'll get a deprecation warning from Beam::Wire.

The site creator now allows you to set the `base_url`, since that's required for
Statocles to work properly. It also, if given a site as an argument, creates the
site's directory.

Full changelog below:

---

* [change $method in event handler to $sub](https://github.com/preaction/Statocles/commit/d1a0e7c4be60176a1b11aba02a2dd283f6aa0b9b)
* [set the base url using the site creator](https://github.com/preaction/Statocles/commit/2678b9fda35dfddc6c0ba89bc30eea42cc7747c8) ([#268](https://github.com/preaction/Statocles/issues/268), [#269](https://github.com/preaction/Statocles/issues/269))
* [remove date from the default blog post](https://github.com/preaction/Statocles/commit/8b2c0174a340eb6b6349c0e95da66cf31dd16ec4) ([#273](https://github.com/preaction/Statocles/issues/273))
* [change last_modified to "date"](https://github.com/preaction/Statocles/commit/086cf753471e0d8cfd8656413cae0755c8814fc4) ([#273](https://github.com/preaction/Statocles/issues/273))
* [fix error when site object has a bad reference](https://github.com/preaction/Statocles/commit/52b8dc7c8b04cad64217428b2a9599904715a069) ([#275](https://github.com/preaction/Statocles/issues/275))
* [mention the "create" command where appropriate](https://github.com/preaction/Statocles/commit/8314c003f2eaeed64db3115cf52121baa3d756af) ([#274](https://github.com/preaction/Statocles/issues/274))
