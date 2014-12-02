# Contributing

## Reporting issues

First off, write in English!

Secondly, search both open and closed issues, to avoid duplicates.

Include this in bug reports:

- VimFx version, Firefox version, keyboard layout and operating system.
- Steps to reproduce.
- Whether the bug is a regression or not (if you know). Bonus points for
  telling since when the bug appeared.

If you’re suggesting a new feature always state your use case. Try to do it
both in general and with a really specific example.

Lastly, don’t hesitate to open issues!


## Localizing

Contribute your localization! See `locale` folder.

Send your pull request to the **master** branch (no matter if it is a new
locale or an update to an existing one).


## Developing

### Versioning and branches

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

### Pull requests

Create a new topic branch, based on either master or develop. See above.

    git checkout -b myTopicBranch master
    # or
    git checkout -b myTopicBranch develop

Code! Try to follow the following simple rules:

- Always use parenthesis when calling functions. (Except `require`.)
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

Please lint your code. See below.

Break up your pull request in several commits if necessary. The first line of
commit messages should be a short summary. Add a blank line and then a nicely
formatted markdown description after it if needed.

Finally send a pull request to same branch as you based your topic branch on
(master or develop).

### Building VimFx

1. Install [Node.js].
2. Run `npm install` to download dependencies and development dependencies.
3. Run `npm install -g gulp` to be able to run [`gulp`][gulp] commands.
   (Alternatively, you may use `./node_modules/.bin/gulp`.)
4. Create a new Firefox profile for development.
5. Install the [Extension Auto-Installer] add-on in your development profile.

- `gulp build` creates the `build/` directory. It is basically a copy of the
  `extension/` directory, with the .coffee files compiled to .js.
- `gulp xpi` zips up the `build/` directory into `build/VimFx.xpi`.
- `gulp push` (or just `gulp`) pushes `build/VimFx.xpi` to
  `http://localhost:8888`, which causes the Extension Auto-Installer to
  automatically install it. (No need to restart Firefox.)
- `gulp clean` removes the `build/` directory.
- `gulp lint` lints your code.

An easy workflow is code, `gulp`, test, repeat.

[Node.js]: http://nodejs.org/
[gulp]: https://github.com/gulpjs/gulp
[Extension Auto-Installer]: https://addons.mozilla.org/firefox/addon/autoinstaller
