<!--
This is part of the VimFx documentation.
Copyright Simon Lydell 2015.
See the file README.md for copying conditions.
-->

# Tools

This section describes how to install and use the tools needed to:

- Build VimFx from source
- Lint code
- Sync locales
- Prepare releases


## Installation

1. Install [Node.js].

2. Run `npm install` to download dependencies and development dependencies.

3. Optional: Run `npm install -g gulp` to be able to run [`gulp`][gulp] tasks.

   If you prefer not to install gulp globally, you can use `npm run gulp`
   instead. For example, to create an `.xpi`: `npm run gulp -- xpi`. (Note that
   you might need to update `npm` for this to run; try `npm update -g npm`.)

[Node.js]: http://nodejs.org/
[gulp]: https://github.com/gulpjs/gulp

## Getting started

### How to build and install the latest version from source

1. Follow the installation instructions above.

2. Run `npm run gulp -- xpi`.

3. Install `build/VimFx.xpi` in Firefox by doing one of the following:

   - Dragging and dropping it.
   - Pressing ctrl+o and choosing it.
   - Using “Install from file…” in the top-right menu in the Add-ons Manager.

### Development

1. Create a new [Firefox profile] for development.

2. Install the [Extension Auto-Installer] add-on in your development profile.

An easy workflow is code, `gulp`, test, repeat. (Use `gulp -t` to also run the
unit tests.)

If you’re having problems, don’t forget to try `npm update`. Your problem might
be in a dependency and already have been fixed.

[Firefox Profile]: https://support.mozilla.org/en-US/kb/profile-manager-create-and-remove-firefox-profiles
[Extension Auto-Installer]: https://addons.mozilla.org/firefox/addon/autoinstaller


## Gulp tasks

[gulp] is the task runner used to automate most of the common VimFx tasks.

The tasks are defined in [gulpfile.coffee]. They are summarized in the follwing
sub-sections.

(There are a few more tasks defined in [gulpfile.coffee], but they are only used
internally by other tasks.)

[gulpfile.coffee]: ../gulpfile.coffee

### Building

- `gulp build` creates the `build/` directory. It is basically a copy of the
  `extension/` directory, with some of the files being compiled. For example,
  the `.coffee` files compiled to `.js`.

- `gulp xpi` runs `gulp build` and then zips the `build/` directory into
  `build/VimFx.xpi`.

- `gulp push` (or just `gulp`) runs `gulp xpi` and then pushes `build/VimFx.xpi`
  to `http://localhost:8888`, which causes the [Extension Auto-Installer] to
  automatically install it. (No need to restart Firefox.)

- Use the `--test` or `-t` option to include the unit test files. The output of
  the tests are `console.log`ed. See the browser console, or start Firefox from
  the command line to see it.

- `gulp clean` removes the `build/` directory.

### Management

- `gulp lint` lints all `.coffee` files.

- `gulp sloc` prints comment and source code line counts.

- `gulp sync-locales` syncs locales. See the [“Syncing locales”][sync-locales]
  section below for more information.

[sync-locales]: #syncing-locales

### Helpers

- `gulp faster` compiles `gulpfile.coffee` to `gulpfile.js`. If you run `gulp` a
  lot and wish it ran faster, just tell it and it will! You’ll have to remember
  to re-run it whenever gulpfile.coffee is updated, though.

- `gulp help.html` dumps VimFx’s Keyboard Shortcuts dialog into `help.html`. You
  can then open up `help.html` in Firefox and style it live using the Style
  Editor! You can even press the “Save” button when done to save your changes!

### Release

See the [“Making a release”][release] section below for more information.

- `gulp release` tags things with a new version number.

- `gulp changelog` prints changelog entries from `CHANGELOG.md` as HTML to
  stdout.

- `gulp readme` prints `README.md` as HTML to stdout.

Tip: Add `--silent` at the end of the gulp command to suppress gulp’s standard
progress output, allowing to pipe stdout to the clipboard.

[release]: #making-a-release


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
locales to use the new wording:

- If possible, edit all other locales by hand to save as much translated text as
  possible.

- Otherwise:

  1. Before modifying existing translations, copy the file in question and add
     the extension `.old` to the filename. For example, copy a
     `vimfx.properties` file to `vimfx.properties.old`.
  2. Make your modifications (in for example `vimfx.properties`, leaving
     `vimfx.properties.old` intact).
  3. Run `gulp sync-locales`. It does the same thing as before, except that if a
     translation has changed compared to an `.old`-file, the newly changed
     translation is used in all locales, replacing what was there before.
  4. Remove the `.old`-file.

Note that `gulp sync-locales` requires every translation to be in a single line.
In other words, do not line-wrap translations. Also don’t bother adding comments
when translating locale files, since they’ll likely be removed by `gulp
sync-locales`.

If you run `gulp sync-locales` with “en-US” as the base locale, a report is
printed telling how complete all other locales are. Add `--sv-SE?` (note the
question mark) to restrict the report to the “sv-SE” locale (you can of course
substitue with any other locale). In that case, every line (including line
number) that don’t differ compared to “en-US” is also be printed.


## Making a release

Before making a release, it might be wise to:

- Run `npm update` and/or `npm outdated` to see if there are any updates to
  dependencies. Investigate what’s new and test!
- Run `gulp sync-locales` to make sure that no translation has been left behind.
- Inspect the `build/` directory to see that nothing strange has been included
  or generated by `gulp build`.

Steps:

1. Add a list of changes since the last version at the top of `CHANGELOG.md`.

2. Update the version in `package.json` (see `CONTRIBUTING-CODE.md` about
   versioning), the minimum Firefox version (if needed) and the maximum Firefox
   version (ideally to the latest nightly). See [valid Firefox versions].

3. Run `gulp release`, which does the following for you:

  - Adds a heading with the new version number and today’s date at the top of
    CHANGELOG.md.
  - Commits CHANGELOG.md and package.json.
  - Tags the commit.

4. Run `gulp xpi` to rebuild with the new version number.

5. Try the just build version, just to be sure.

6. Publish on addons.mozilla.org. Add the release notes list as HTML. `gulp
   changelog` prints the latest changelog entry as HTML. `gulp changelog -2`
   prints the latest two (etc). The latter is useful if publishing a new version
   before the last published version had been reviewed; then the new version
   should contain both changelog entries.

7. Push to github. Don’t forget to push the tag! (It’s better to do this after
   the publish on addons.mozilla.org, because sometimes its validator complains.
   This saves some commits.)

8. Make a “release” out of the new tag on github, and attach VimFx.xpi to it.

The idea is to use the contents of `README.md` as the add-on descripton on
addons.mozilla.org. You can print it as HTML by runnning `gulp readme`.

[valid Firefox versions]: https://addons.mozilla.org/en-US/firefox/pages/appversions/
