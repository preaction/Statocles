---
last_modified: 2015-02-22 19:57:07
tags: release
title: Statocles Beta (Release v0.039)
---

This is it! The beta milestone is complete!

This release adds the "create" command to easily create new Statocles sites.

Blog posts are now directories, which will allow us (in the future) to have
images and other documents inside. The breaking part of this change was made now,
and future additions will be made as beta progresses.

There were a couple reorganizations of the documentation and tests to make them
easier to understand.

Full changelog below:

---

* [normalize the default log level to warn](https://github.com/preaction/Statocles/commit/7775bc6f8e83e113ebdec18778ec6c219b29d107)
* [rearrange tests into small, feature-sized chunks](https://github.com/preaction/Statocles/commit/a5abff731d7a207f7c999f36de000afa73051a5c)
* [create new blog posts in directories](https://github.com/preaction/Statocles/commit/c142dd83e5d959f58e6ef4a99cbb9397d58801ec) ([#239](https://github.com/preaction/Statocles/issues/239))
* [allow blog posts to be directories](https://github.com/preaction/Statocles/commit/e9be65ec64687d497149f776e4f2a958e25e54d3) ([#239](https://github.com/preaction/Statocles/issues/239))
* [organize core and non-core deps](https://github.com/preaction/Statocles/commit/b94550ab7a7ebe8204e7ddc4dd64fa5c42753df6)
* [add create command example to website](https://github.com/preaction/Statocles/commit/0675a7eb6dd020e59293e36e1b31cf15cc54d150)
* [fix note about default theme using skeleton](https://github.com/preaction/Statocles/commit/8ffaf939e216e4e62dd6ee414d5556e3c6de4900)
* [add note about create command to Setup guide](https://github.com/preaction/Statocles/commit/ce252e546ce2cdb02da9edcb43d828003e2854c5)
* [add site "create" command](https://github.com/preaction/Statocles/commit/c06a75a5a7a666179c5190629377dbb4a97be7e0) ([#28](https://github.com/preaction/Statocles/issues/28))
* [add link to content guide](https://github.com/preaction/Statocles/commit/01140f81af3e042e957872fa259bd9fdb261f7b6)
* [reorganize guides and add Statocles::Help](https://github.com/preaction/Statocles/commit/78bc4d5aa935f73880c6db722e4d7cd24e198fe7) ([#253](https://github.com/preaction/Statocles/issues/253))
* [split the Setup guide into Config and Content](https://github.com/preaction/Statocles/commit/1916925c74f94a080caa2b2972a0e953c2766691)
* [fix navbar too close to main page content](https://github.com/preaction/Statocles/commit/3a58a277fb41ea2dbd78465cb2d778131787cd3e)
* [break parsing a frontmatter file into its own sub](https://github.com/preaction/Statocles/commit/a125716301fd93a80cdecc79885a3912cbec2e69)
* [clarify the docs on Pages and what a Site is](https://github.com/preaction/Statocles/commit/e069c8a18c8b17ad3bba26b5a73a3171f2c82a26)
* [split the main doc into the Develop guide](https://github.com/preaction/Statocles/commit/b77d61ca34117fe84826e942845c1b9658d2da62) ([#242](https://github.com/preaction/Statocles/issues/242))
