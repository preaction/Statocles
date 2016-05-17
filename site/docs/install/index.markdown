---
title: Installing Statocles
---

This guide will walk you through installing Statocles. Statocles is a
command-line application, so some familiarity with using a command
terminal is needed. 

Throughout this guide, the `$` character will be placed before commands
for you to run. This is the standard "prompt" character on Unix-like
terminals. Your prompt may look different (for example, `C:/>` on
Windows and DOS-like terminals). Any line not preceded by a `$` is
example output from running the command.

# Installing Perl

Statocles is a Perl application, so you will need a Perl installation
before you can run Statocles.

## Linux

Many Linux distributions come with a basic Perl that can run Statocles.
Other distributions come with a `perl` executable, but lack some of the
core modules Statocles expects.

To check if you've got a Perl already installed, open a terminal and run
`which perl`:

```
$ which perl
/usr/bin/perl
```

The `which` command will tell you whether there is anything called
`perl` available to execute. If `which` can't find a Perl, it will print
nothing, and you'll be shown your prompt again. You should install Perl
using your distribution's package manager.

* RedHat, CentOS, Fedora: `sudo yum install perl-core`
* Debian, Ubuntu, Mint: `sudo apt-get install perl`

When Perl is installed, you should verify you have a recent-enough
version. Statocles requires Perl 5.10.1 or later (released in 2001). You
can run `perl -v` to see what version of Perl you have.

```
$ perl -v
This is Perl v5.12.2
```

If you have a recent enough Perl, you can proceed on to [Installing
Statocles](#Installing-Statocles). If your OS doesn't have a recent
enough Perl, you can build Perl from source using [perlbrew](),
[plenv](), or [perl-build]().

## Mac OS X

Mac OS X comes with a Perl modern enough to run Statocles. Skip ahead to
[Installing Statocles](#Installing-Statocles) to install Statocles. If
you want to install a separate Perl to ensure there are no problems when
upgrading your Mac OS X, you can try [homebrew]() for installing a wide
variety of software, or Perl-specific solutions like [perlbrew](),
[plenv](), or [perl-build]().

XXX Do we need a compiler / XCode?

## Windows

Windows rarely comes with a Perl install, so you'll have to do it
yourself. We recommend using [Strawberry Perl](), but [ActivePerl by
ActiveState]() is also an option. Install the latest version of one of
these Windows Perl distributions.

If you choose ActivePerl, installing Statocles will be slightly
different. See [Installing with ActivePerl]().

### Installing with access to Git

A common Statocles deployment strategy involves using Git for deploying
the website. To make Statocles automatically deploy using Git, it must
have access to the Git command-line tools.

XXX

# Installing Statocles

Once Perl is installed, we can install Statocles itself. There are a
couple ways to do this depending on whether you have administrator
(root) access to the machine.

## Installing without administrator privileges

This is the recommended way to install Statocles on Linux and Mac OS X.
Installing Statocles for the entire machine can create problems,
especially if your OS depends on the Perl it includes for its own
operations. Installing to your own user directory ensures that you can
easily uninstall Statocles without impacting the rest of your system.

This method will not work on Windows, unfortunately, but on Windows
there is also no danger of the OS relying on Perl for its own operation.

### Setting up your user environment

XXX

### Installing Statocles

Now that your environment is ready, you can install Statocles with `cpan
Statocles`.

XXX

## Installing for the entire machine

With admin privileges, you can simply run "cpan Statocles" and
everything will work. A wall of text will fly past your screen, and
Statocles will test itself and install itself if the tests pass.

If the tests fail on your machine, or if Statocles fails to install for
any reason, please [open a bug report](), and include the full log from
your terminal so we can help fix the problem.

This is the recommended way to install Statocles on Windows using
Strawberry Perl.

## Installing with ActivePerl

ActivePerl for Windows has a slightly different way to install Perl
modules, called Perl Package Manager (PPM). To install Statocles using
ActivePerl, run `ppm Statocles`.

```
C:/> ppm Statocles
XXX
```

# Installing optional prereqs

Optional prereqs are installed in the same way as Statocles. If you
installed Statocles using the `cpan` command, you install these optional
prereqs using the same command. If you installed Statocles using the
`ppm` command, you most likely install these using the `ppm` command
again.

## Git::Repository

This module allows Statocles to use Git as a deployment target, which
enables [Github Pages]() support, or a nicely-automated, authenticated,
and auditable way of deploying to your own machines using only a
standard ssh login.

To install the `Git::Repository` module, do `cpan Git::Repository` or
`ppm Git::Repository`, depending on how you installed Statocles.

## Auto-build daemon

On Mac OS X, the Statocles daemon can automatically rebuild your site
when its content changes. To enable this feature, we need the
`Mac::FSEvents` module.

To install the `Mac::FSEvents` module, do `cpan Mac::FSEvents`.
Then, the Statocles daemon will automatically begin watching your
content directories for changes.

## Syntax::Highlighter::Engine::Kate

The optional Statocles syntax highlighting plugin, which colorizes code
sections for technical page and blog content, requires an optional
prerequisite, the `Syntax::Highlighter::Engine::Kate` module. Before we
can [enable this plugin in our config](../config#Plugins), we need to
install its prereq. If we don't, we will get an error message saying we
need to install the prereq.

To install the `Syntax::Highlighter::Engine::Kate` module, do `cpan
Syntax::Highlighter::Engine::Kate` or `ppm
Syntax::Highlighter::Engine::Kate`, depending on how you installed
Statocles.

## HTML::Lint::Pluggable

XXX
