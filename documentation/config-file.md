<!--
This is part of the VimFx documentation.
Copyright Simon Lydell 2015, 2016.
See the file README.md for copying conditions.
-->

# Config file

VimFx can optionally be configured using a text file—called a _config file._
This should be done by users who:

- prefer to configure things using text files.
- would like to add [custom commands].
- would like to set [special options].
- would like to make [site-specific customizations][overrides].
- would like to customize [which elements do and don’t get hints][hint-matcher].

Look at the [Share your config file] wiki page for inspiration.

You get far just by copying and pasting.

[custom commands]: api.md#vimfxaddcommandoptions-fn
[special options]: options.md#special-options
[overrides]: api.md#vimfxaddoptionoverrides-and-vimfxaddkeyoverrides
[hint-matcher]: api.md#vimfxsethintmatcherhintmatcher
[Share your config file]: https://github.com/akhodakivskiy/VimFx/wiki/Share-your-config-file


## Getting started

VimFx requires you to provide either none or _two_ config files: `config.js` and
`frame.js`. Even though they are technically two, it’s easier to just say “the
config file,” (in singular) and think of `config.js` is the _actual_ config file
and `frame.js` as an implementation detail. Both of these files are written in
JavaScript and are explained in more detail in the upcoming sections.

Follow these steps to get started with your config file:

1. Create a directory, anywhere on your hard drive. Examples:

   - GNU/Linux: `~/.config/vimfx` or `~/.vimfx`.
   - Windows: `c:\Users\you\vimfx`.

2. Create two empty plain text files in your directory, called `config.js` and
   `frame.js`.

3. Set the [`config_file_directory`] pref (that’s an [advanced option]) to the
   path of the directory you created above. It can be either absolute, such as
   `/home/you/.config/vimfx` or `C:\Users\you\vimfx`, or start with a `~`, which
   is a shortcut to your home directory, such as `~/.config/vimfx` or `~\vimfx`.

4. Run the `gC` command in VimFx. That needs to be done any time
   `config_file_directory` is changed, or the contents of `config.js` or
   `frame.js` are changed. This tells VimFx to reload the config file. If
   everything went well, a [notification] should appear telling you that the
   config file was successfully reloaded.

[`config_file_directory`]: options.md#config_file_directory
[advanced option]: options.md#advanced-options
[notification]: notifications.md


## Tips

If you make errors in `config.js` or `frame.js` they will appear in the [browser
console].

Remember to press `gC` after you’ve edited `config.js` or `frame.js` to reload
them. A [notification] will appear telling you if there was any trouble
reloading or not.

Use `console.log(...)` to inspect things. For example, try putting
`console.log('This is vimfx:', vimfx)` in `config.js`. Then, open the [browser
console]. There you should see an entry with the message “This is vimfx:” as
well as an interactive inspection of the `vimfx` object.

[browser console]: https://developer.mozilla.org/en-US/docs/Tools/Browser_Console
[notification]: notifications.md


## Scope

Both `config.js` and `frame.js` have access to the following variables:

- `vimfx`: VimFx’s [`config.js` API] or [`frame.js` API]. You’ll probably only
  work with this object and not much else.
- [`console`]: Let’s you print things to the [browser console]. Great for
  simple debugging.
- `__dirname`: The full path to the config file directory, in a format that
  Firefox likes to work with. Useful if you want to import other files relative
  to the config file.
- [`Components`]: This object is available to all add-ons, and is the main
  gateway to all of Firefox’s internals. This lets advanced users do basically
  anything, as if they had created a full regular Firefox add-on.
- [`Services`]: Shortcuts to some `Components` stuff.

`frame.js` also has access to the entire standard Firefox [frame script
environment], which might be interesting to advanced users.

[`config.js` API]: api.md#configjs-api
[`frame.js` API]: api.md#framejs-api
[`console`]: https://developer.mozilla.org/en-US/docs/Web/API/console
[`Components`]: https://developer.mozilla.org/en-US/docs/Mozilla/Tech/XPCOM/Language_Bindings/Components_object
[`Services`]: https://developer.mozilla.org/en-US/docs/Mozilla/JavaScript_code_modules/Services.jsm
[frame script environment]: https://developer.mozilla.org/en-US/Firefox/Multiprocess_Firefox/Frame_script_environment
[browser console]: https://developer.mozilla.org/en-US/docs/Tools/Browser_Console


## config.js

This is the actual config file, where you’ll do most things. It is in this file
you add custom commands and set options, or whatever you’d like to do.

Example code:

```js
vimfx.set('hints.chars', 'abcdefghijklmnopqrstuvwxyz')
vimfx.set('custom.mode.normal.zoom_in', 'zi')
```

If you add custom commands, remember to [add shortcuts to
them][custom-command-shortcuts]!

Tip: If you already have made customizations in VimFx’s settings page in the
Add-ons Manager, you can use the “Export all” button there to copy all prefs as
JSON. Paste it in your config file and either edit it, or iterate of it:

```js
let prefs = {"hints.chars": "1234567 89"} // Pasted exported prefs.
Object.entries(prefs).forEach(([pref, value]) => vimfx.set(pref, value))
```

[custom-command-shortcuts]: api.md#user-content-custom-command-shortcuts


## frame.js

If you add custom commands which access web page content, put their “frame
script code” in this file.

Typically, all you do in `frame.js` is listening for messages from `config.js`
and reponding to those messages with some data from the current web page, which
only `frame.js` has access to. The [`vimfx.send(...)`] documentation has an
example of this.

Note: Even if you don’t need `frame.js` right now, the file still must exist if
`config.js` exists. Simply leave it blank.

[`vimfx.send(...)`]: api.md#vimfxsendvim-message-data--null-callback--null


## When is the config file executed?

- Every time VimFx starts up. In other words, when Firefox starts up and when
  you update VimFx (or disable and then enable it).
- Every time you use the `gC` command to reload the config file.

“Executing the config file” means running `config.js` once and `frame.js` for
each open tab. `frame.js` also runs every time you open a new tab.

(See also [the `shutdown` event].)

[the `shutdown` event]: api.md#the-shutdown-event
