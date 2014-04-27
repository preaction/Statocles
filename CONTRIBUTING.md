# CONTRIBUTING

If you're not sure about anything, feel free to open an issue and ask!

## What to Contribute

### Fixes

For fixes, simply fork and send a pull request. Be sure to add yourself
to the dist.ini as an author!

Fixes to anything, documentation, code, tests, are equally welcome,
appreciated, and addressed!

### Features

All contributions are welcome if they fit the scope of this project. If
you're not sure if your feature fits, open an issue and ask. If it doesn't
fit, we will try to find a way to enable you to add your feature in a
related project (if it means changes in this project).

## Before you Contribute

### Copyright and License

All contributions are copyright their respective owners, so make sure you
agree with the project license (found in the LICENSE file) before
contributing.

Make sure to add yourself as an author to either the AUTHORS file or
the dist.ini file so you get your proper copyright attribution.

### Formatting and Syntax

I don't worry too much about this, yet. I'm sure I'll fill this section
in a bit more. For now, try to match as best you can the code that
already exists in this project.

## Developing on this Project

This project uses Dist::Zilla for its releases, but you aren't required
to use it for contributing.

### Using Build.PL

This is the easiest way that requires the fewest dependencies.

Install the project's dependencies and run the tests by doing:

```
perl Build.PL
./Build installdeps
./Build test
```

### Using Makefile.PL

This is the older standard way. If you can install CPAN modules, you can
probably do this. It requires `make` and maybe a C compiler.

Run the tests by doing:

```
perl Makefile.PL
make test
```

Install the module's dependencies by doing:

```
cpanm .
```

### Using Dist::Zilla

Once you have installed Dist::Zilla, you can get this distributions's
dependencies by doing:

```
dzil listdeps --author --missing | cpanm
```

Once all that is done, testing is as easy as:

```
dzil test
```
