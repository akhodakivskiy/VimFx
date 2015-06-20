<!--
This is part of the VimFx documentation.
Copyright Simon Lydell 2015.
See the file README.md for copying conditions.
-->

# Contributing code

## Localizations

Contribute your localization! Copy the `extension/locale/en-US` directory and go
wild!


## Code

Create a new topic branch, based on either master or develop. **Note:** For now,
_always_ base it on **develop**.

    git checkout -b my-topic-branch master
    # or
    git checkout -b my-topic-branch develop

Code! Try to follow the following simple rules:

- Always use parenthesis when calling functions.
- Always use explicit `return`s, unless the function is a one-liner.
- Always use single quotes, unless you use interpolation.
- Prefer interpolation over concatenation, both in strings and in regexes.
- Always use the following forms (not any aliases):
  - `true` and `false`
  - `==` and `!=`
  - `and` and `or`
  - `not`
- Put spaces inside `[]` and `{}` when destructuring and interpolating, but not
  in array and object literals.
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

Currently, no more updates are planned for 0.5.x = master branch. **Please only
contribute to the develop branch for now.** It contains quite a bit of backwards
incomptaible improvements, and will be released as 0.6.0 as soon as it is ready.
That will be the last “big” release. Then we’ll switch to a more rapid release
cycle, detailed below.

### Vision

VimFx uses three numbers to describe its version: x.y.z, or major.minor.patch.
However, in reality it is more like 0.y.z. The first number (major) won’t
change until we feel that we don’t have any major changes coming. So until then
it is only worth describing the two other numbers.

The middle number (minor) is incremented when a release contains new features,
major refactors or changes to defaults. The idea is that when a user installs a
new minor release, they should expect changes that they need to get familiar
with.

The last number (patch) is incremented when a release contains only (simple)
bugfixes, new localizations and updates to localizations. If a user installs a
new patch release they shouldn’t have to get familiar with anything. Things
should be like they were before, just a little better.

VimFx uses two branches: **master** and **develop**. master is the latest
stable version plus trivial bugfixes. develop is the next minor version. master
is merged into develop when needed, and develop is merged into master before it
is going to be released.

In short, “backwards-incomptaible” changes and new features go into the develop
branch, while most other things go into the master branch.
