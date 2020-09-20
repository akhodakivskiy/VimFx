# Tools

This section describes how to install and use the tools needed to:

- Build VimFx from source
- Lint code
- Sync locales
- Prepare releases


## Installation

1. Install [Node.js].

2. Run `npm install` to download dependencies and development dependencies.

3. Optional: Run `npm install --global gulp` to be able to run [`gulp`][gulp]
   from the terminal.

   If you prefer not to install `gulp` globally, you can use `npm run gulp`
   instead. For example, to create an .xpi file: `npm run gulp -- xpi`.

[Node.js]: http://nodejs.org/
[gulp]: https://github.com/gulpjs/gulp


## Getting started

### How to build and install the latest version from source

1. Follow the installation instructions above.

2. Run `npm run gulp -- xpi`.

3. [Open `build/VimFx.xpi` in Firefox][open-xpi].

Note that the built .xpi file is [unsigned].

[open-xpi]: installation.md#how-to-install-an-xpi-file-in-firefox
[unsigned]: installation.md#what-is-a-signed-add-on

### Development

You need Firefox version 68 or higher (or a compatible fork) and [LegacyFox].
Optionally, create a new [Firefox profile] for development.

To test a new verison, open the build directory in the browser and install the
XPI from there. Sometimes, you'll have to restart Firefox after
installation/upgrade.

[Firefox Profile]: https://support.mozilla.org/en-US/kb/profile-manager-create-and-remove-firefox-profiles
[LegacyFox]: https://git.gir.st/LegacyFox.git


## Gulp tasks

[gulp] is a task runner, which is used to automate most VimFx tasks.

The tasks are defined in [gulpfile.coffee]. They are summarized in the following
sub-sections.

(There are a few more tasks defined in [gulpfile.coffee], but they are only used
internally by other tasks.)

[gulpfile.coffee]: ../gulpfile.coffee

### Building

- `gulp build` creates the `build/` directory. It is basically a copy of the
  `extension/` directory, except some of the files have been compiled. For
  example, the .coffee files are compiled to .js.

- `gulp xpi` runs `gulp build` and then zips the `build/` directory into
  `build/VimFx.xpi` (an .xpi file is a renamed .zip file).

- Use the `--test` or `-t` option to include the unit test files into the build.
  The output of the tests are `console.log`ed. Use the [browser console], or
  start Firefox from the terminal to see it.

- Use the `--unlisted` or `-u` option to append `-unlisted` to the extension ID.
  This is used when adding .xpi files to github releases.

- `gulp clean` removes the `build/` directory.

[browser console]: https://developer.mozilla.org/en-US/docs/Tools/Browser_Console

### Management

- `gulp lint` lints all .coffee files. There’s also `npm run addons-linter` to
  run [`addons-linter`] on a freshly built VimFx .xpi.

- `gulp sloc` prints comment and source code line counts.

- `gulp sync-locales` syncs locales. See the [“Syncing locales”][sync-locales]
  section below for more information.

[`addons-linter`]: https://github.com/mozilla/addons-linter/
[sync-locales]: #syncing-locales

### Helpers

- `gulp faster` compiles `gulpfile.coffee` to `gulpfile.js`. If you run `gulp` a
  lot and wish it ran faster, just tell it and it will! You’ll have to remember
  to re-run `gulp faster` whenever `gulpfile.coffee` is updated, though.

- `gulp help.html` dumps VimFx’s Keyboard Shortcuts help dialog into
  `help.html`. You can then open up `help.html` in Firefox and style it live
  using the Style Editor! You can even press the “Save” button when done to save
  your changes!

- `gulp hints.html` is like `gulp help.html` but for styling hint markers.


## Syncing locales

This is usually not done by translators, but by developers who change, add or
remove features that involves localized text.

If you add, remove or reorder translations in a file, do so in _one_ of the
locales (one that is easy for you to test—but always write new translations in
English!). If you modified the en-US locale, run `gulp sync-locales --en-US` (or
just `gulp sync-locales`). Substitute “en-US” with a locale of choice if needed.
That rewrites all other locales so that:

- Old translations are removed.
- New translations are added (in English).
- All translations appear in the same order.

If you modify an existing translation in a file and want to update all other
locales to use the new wording, add `UPDATE_ALL` at the end of it. `gulp
sync-locales` will then use that translation in _all_ locales, replacing what
was there before. It also removes `UPDATE_ALL` for you. However, if possible,
edit all other locales by hand to save as much translated text as possible.

Note that `gulp sync-locales` requires every translation to be in a single line.
In other words, do not line-wrap translations. Also don’t bother adding comments
when translating locale files, since they will be removed by `gulp
sync-locales`.

If you run `gulp sync-locales` with “en-US” as the base locale, a report is
printed telling how complete all other locales are. Add `--sv-SE?` (note the
question mark) to restrict the report to the “sv-SE” locale (you can of course
substitute with any other locale). In that case, every line (including line
number) that don’t differ compared to “en-US” is also be printed.


## Making a release

Before making a release, it might be wise to:

- Run `npm update` and/or `npm outdated` to see if there are any updates to
  dependencies. Investigate what’s new and test!
- Run `gulp sync-locales` to make sure that no translation has been left behind.
- Run `gulp lint` and `npm run addons-linter` to catch potential problems.
- Run `gulp --test` to make sure the tests pass.
- Inspect the `build/` directory to see that nothing strange has been included
  or generated by `gulp build`.

Run `./release` with argument `minor` or `patch`, which does the following for you:

  - Updates the version in `package.json`.
  - Adds a heading with the new version number and today’s date at the top of
    `CHANGELOG.md`.
  - Commits `CHANGELOG.md` and `package.json`.
  - Tags the commit.
  - Lints the code and builds an xpi.
  - Opens the browser to help publish the release on GitHub, and to attach an
    .xpi to it.
