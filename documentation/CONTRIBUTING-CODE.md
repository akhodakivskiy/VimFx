<!--
This is part of the VimFx documentation.
Copyright Simon Lydell 2015.
See the file README.md for copying conditions.
-->

# Contributing code

**This document is meant to _help,_ not to scare you off!** Contributions are
more than welcome. Don’t be afraid to make mistakes–we’ll help you out!


## Localizations

Contribute your localization! Copy the `extension/locale/en-US` directory and go
wild! Usually, it’s best to stick to the master branch.

Tip: If you’re translating into Swedish, run `gulp sync-locales --sv-SE?` to see
how many percent is done. All lines (including line numbers) that don’t differ
compared to “en-US” are also printed, letting you know what’s left to do.
Subsitute “sv-SE” with the locale you’re working on.

Also, don’t worry if you can’t get a 100% difference compared to “en-US.”
Sometimes text strings are very short and will look identical in both languages.
That’s completely OK.


## Code

Create a new topic branch, based on either master or develop.

    git checkout -b my-topic-branch master
    # or
    git checkout -b my-topic-branch develop

Code! Try to follow these simple rules:

- Always use parenthesis when calling functions.
- Always use explicit `return`s, unless the function is a one-liner.
- Always use single quotes, unless you use interpolation.
- Prefer interpolation over concatenation, both in strings and in regexes.
- Always use the following forms (not any aliases):
  - `true` and `false`
  - `==` and `!=`
  - `and` and `or`
  - `not`
- Never put spaces inside `[]` and `{}`.
- Comment when necessary. Comments should be full sentences.
- Try to keep lines at most 80 characters long.
- Indent using two spaces.

See [tools.md] for how to **build,** **lint,** and **run the tests.**

Break up your pull request in several commits if necessary. The first line of
commit messages should be a short summary. Add a blank line and then a nicely
formatted markdown description after it if needed.

Finally send a pull request to same branch as you based your topic branch on
(master or develop).

[tools.md]: tools.md


## Versioning and branches

VimFx uses three numbers to describe its version: x.y.z, or major.minor.patch.

Version 1.0.0 will soon be released. When that’s the case, the first number
(major) will only be incremented when there are backwards-incompatible changes,
such as changes to defaults or to the public API. This should be avoided. The
idea is that when a user installs a new major release, they should expect
changes that they need to get familiar with.

The middle number (minor) is incremented when a release contains new features,
or larger changes/refactors to code. Users should expect things to be roughly
the same, but with a few new features (and the potential bugs along with them),
when installing a new minor release.

The last number (patch) is incremented when a release contains only (simple)
bugfixes, new localizations and updates to localizations. If a user installs a
new patch release they shouldn’t have to get familiar with anything. Things
should be like they were before, just a little better. Code released as a patch
version should ideally have a low risk of bugs.

VimFx uses two branches: **master** and **develop**. master is the latest
stable version plus trivial bugfixes. develop is the next minor version. master
is merged into develop when needed, and develop is merged into master before it
is going to be released.

In short, “backwards-incomptaible” changes and new features go into the develop
branch, while most other things go into the master branch.

Trying to choose the right branch is important in order to be able to keep a
rapid release cycle.
