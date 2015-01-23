# Contributing

## Reporting issues

_Please_ read the following four lines!

- Use **English.**
- Search for **duplicates**—also closed issues.
- Bugs: Include **VimFx version**, Firefox version, OS and keyboard layout.
- Feature requests: Include a specific detailed **use case** example.


---


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

Break up your pull request in several commits if necessary. The first line of
commit messages should be a short summary. Add a blank line and then a nicely
formatted markdown description after it if needed.

Finally send a pull request to same branch as you based your topic branch on
(master or develop).

### Tips:

- Compile the .coffee files with the **`--bare`** option! Otherwise you will
  get errors.
- Run `coffee -cbw .` from the root of the project to automatically compile on
  changes.
- Put a file called exactly `VimFx@akhodakivskiy.github.com` in the extensions/
  folder of a Firefox profile, containing the absolute path to the extension/
  folder in the project. Then you just need to restart Firefox (use some
  add-on!) after each change. More details in this [MDN article][mdn-extdevenv].
- Only create tickets for issues and feature requests in English. Otherwise
  duplicate tickets in different languages will pile up.

[mdn-extdevenv]: https://developer.mozilla.org/en-US/docs/Setting_up_extension_development_environment#Firefox_extension_proxy_file
