---
tags:
  - release
title: Release v0.045
---

A couple small changes in this release:

Blog posts are now allowed to have images inside the post directory. This makes
it a lot easier to add images to blogs. You don't need to configure a global
`/images` directory. You can put your image in `/blog/YYYY/MM/DD/post-title`.
Even better, you get to refer to it in your post as `![](image.jpg)`.

The [link check plugin](/pod/Statocles/Plugin/LinkCheck.html) now correctly finds
links the URL encoded characters.

The recent posts helper now allows filtering by tag, if, for example, you want to
display only the last `release` blog and not any other blog post.

`statocles daemon` now allows setting `-p <port>`, in case port 3000 is in-use, or
you need to run multiple instances.

Full changelog below:

---

* [allow blog post collateral in post directory](https://github.com/preaction/Statocles/commit/c2be5c6ac4b4b2bd0585398ac098b39e194f6f12) ([#228](https://github.com/preaction/Statocles/issues/228))
* [fix link check plugin not finding url-encoded links](https://github.com/preaction/Statocles/commit/bd6f74c457cd75077713716b0073d9bff264e49d) ([#294](https://github.com/preaction/Statocles/issues/294))
* [allow recent posts filtering by tag](https://github.com/preaction/Statocles/commit/9f37c4ef0fbc9e0495c87197f0d749d4f9b30af3) ([#292](https://github.com/preaction/Statocles/issues/292))
* [add -p <port> option to specify port in daemon](https://github.com/preaction/Statocles/commit/7501643b2f80eb8d70b3a58ccc800cf9ff550df6) ([#219](https://github.com/preaction/Statocles/issues/219))
