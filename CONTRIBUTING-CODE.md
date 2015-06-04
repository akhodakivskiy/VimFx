# Contributing code

## Localizing

Contribute your localization! Copy the `extension/locale/en-US` directory and go
wild!


## Developing

### Versioning and branches

Currently, no more updates are planned for 0.5.x = master branch. **Please only
contribute to the develop branch for now.** It contains quite a bit of backwards
incomptaible improvements, and will be released as 0.6.0 as soon as it is ready.
That will be the last “big” release. Then we’ll switch to a more rapid release
cycle, detailed below.

#### Vision ####

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

Create a new topic branch, based on either master or develop. **Note:** For now,
_always_ base it on **develop**.

    git checkout -b myTopicBranch master
    # or
    git checkout -b myTopicBranch develop

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

Please lint your code. See below.

Run the tests and make sure that all pass. See below. Add tests if possible.

Break up your pull request in several commits if necessary. The first line of
commit messages should be a short summary. Add a blank line and then a nicely
formatted markdown description after it if needed.

Finally send a pull request to same branch as you based your topic branch on
(master or develop).

### Building VimFx

1. Install [Node.js] or [io.js].
2. Run `npm install` to download dependencies and development dependencies.
3. Run `npm install -g gulp` to be able to run [`gulp`][gulp] commands.
   If you prefer not to install gulp globally, you can use `npm run gulp`
   instead. For example, to create an .xpi: `npm run gulp -- xpi`. (Note that
   you might need to update `npm` for this to run; try `npm update -g npm`.)
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
- `gulp faster` compiles `gulpfile.coffee` to `gulpfile.js`. If you run `gulp` a
  lot and wish it ran faster, just tell it and it will! You’ll have to remember
  to re-run it whenever gulpfile.coffee is updated, though.
- `gulp sync-locales` syncs all locales against the en-US locale. To sync against
  for example the sv-SE locale instead, pass `--sv-SE` as an option. See also
  the “Syncing locales” section below.
- `gulp help.html` dumps VimFx’s Keyboard Shortcuts dialog into help.html. You
  can then open up help.html in Firefox and style it live using the Style
  Editor! You can even press the “Save” button when done to save your changes!
- Use the `--test` or `-t` option to include the unit test files. The output of
  the tests are `console.log`ed. See the browser console, or start Firefox from
  the command line to see it.

An easy workflow is code, `gulp`, test, repeat. (Use `gulp -t` to also run the
unit tests.)

If you’re having problems, don’t forget to try `npm update`. Your problem might
be in a dependency and already have been fixed.

[Node.js]: http://nodejs.org/
[io.js]: https://iojs.org/
[gulp]: https://github.com/gulpjs/gulp
[Extension Auto-Installer]: https://addons.mozilla.org/firefox/addon/autoinstaller

### Syncing locales

This is usually not done by translators, but by developers who change, add or
remove features that involves localized text.

If you add, remove or reorder translations in a file, do so in _one_ of the
locales (one that is easy for you to test—but always write new translations in
English!). If you modified the en-US locale, run `gulp sync-locales` (or `gulp
sync-locales --en-US`—substitute “en-US” with a locale of choice if needed).
That rewrites all other locales so that:

- Old translations are removed.
- New translations are added (in English).
- All translations appear in the same order.

If you modify an existing translation in a file and want to update all other
locales to use the new wording:

- If possible, edit all other locales by hand to save as much translated text as
  possible.
- Otherwise:
  1. Before modifying existing translations, copy the file in question and add
     the extension “.old” to the filename. For example, copy a
     “vimfx.properties” file to “vimfx.properties.old”.
  2. Make your modifications (in for example “vimfx.properties”, leaving
     “vimfx.properties.old” intact).
  3. Run `gulp sync-locales`. It does the same thing as before, except that if a
     translation has changed compared to an “.old”-file, the newly changed
     translation is used in all locales, replacing what was there before.
  4. Remove the “.old”-file.

Note that `gulp sync-locales` requires every translation to be in a single line.
In other words, do not line-wrap translations. Also don’t bother adding comments
when translating locale files, since they’ll likely be removed by `gulp
sync-locales`.


### Making a release

Before making a release, it might be wise to:

- Run `npm update` and/or `npm outdated` to see if there are any updates to
  dependencies. Investigate what’s new and test!
- Run `gulp sync-locales` to make sure that no translation has been left behind.
- Inspect the build/ directory to see that nothing strange has been included or
  generated by `gulp build`.

1. Add a list of changes since the last version at the top of CHANGELOG.md.
2. Update the version in package.json (see above about versioning), and, if
   needed, the minimum Firefox version.
3. Run `gulp release`, which does the following for you:
  - Adds a heading with the new version number and today’s date at the top of
    CHANGELOG.md.
  - Commits CHANGELOG.md and package.json.
  - Tags the commit.
4. Run `gulp xpi` to rebuild with the new version number.
5. Push to github. Don’t forget to push the tag!
6. Make a “release” out of the new tag on github, and attach VimFx.xpi to it.
7. Publish on addons.mozilla.org. Add the release notes list as HTML. `gulp
   changelog` prints the latest changelog entry as HTML. `gulp changelog -2`
   prints the latest two (etc). The latter is useful if publishing a new version
   before the last published version has been reviewed; then the new version
   should contain both changelog entries.

The idea is to use the contents of the README as the add-on descripton on
addons.mozilla.org. You can print it as HTML by runnning `gulp readme`.
