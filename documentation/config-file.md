<!--
This is part of the VimFx documentation.
Copyright Simon Lydell 2015.
See the file README.md for copying conditions.
-->

# Config file

VimFx can be configured using a configuration file. This should be done by users
who:

- prefer to configure things using text files.
- would like to add [custom commands].
- would like to set [special options].
- would like to make [site-specific customizations][overrides].
- would like to customize [which elements do and don’t get hints][hint-matcher].

Look at the [Share your config file] wiki page for inspiration.

You get far just by copying and pasting.

[custom commands]: api.md#vimfxaddcommandoptions-fn
[special options]: options.md#special-options
[overrides]: api.md#vimfxaddoptionoverridesrules-and-vimfxaddkeyoverridesrules
[hint-matcher]: api.md#vimfxhintmatcher
[Share your config file]: https://github.com/akhodakivskiy/VimFx/wiki/Share-your-config-file


## Setup

The config file is written in JavaScript and is actually a regular Firefox
add-on, that makes use of VimFx’s [public API]. Don’t worry, creating such an
add-on is a lot easier than it might sound.

**[VimFx Config template – Download and instructions][config-template]**

Follow the above link to get started. Basically, download a few files and put
them in a place where Firefox can find them.

[public API]: api.md
[config-template]: https://github.com/lydell/VimFx-config/


## config.js

This is the actual config file, written in JavaScript. It is in this file you
add custom commands and set options, or whatever you’d like to do.

Example:

```js
vimfx.set('hint_chars', 'abcdefghijklmnopqrstuvwxyz')
```


## frame.js

If you add custom commands that accesses web page content, put their "frame
script code" in this file.

This file is also where usage of the [frame script API] goes.

[frame script API]: api.md#frame-script-api

Here’s a typical pattern used in custom commands that communicate with a frame
script:

```js
// config.js
let {messageManager} = vim.window.gBrowser.selectedBrowser
let callback = ({data: {selection}}) => {
  messageManager.removeMessageListener('VimFx-config:selection', callback)
  console.log('Currently selected text:', selection)
}
messageManager.addMessageListener('VimFx-config:selection', callback)
messageManager.sendAsyncMessage('VimFx-config:getSelection', {exampleValue: 1337})
```

And here’s some accompaning frame script code:

```js
// frame.js
addMessageListener('VimFx-config:getSelection', ({data: {exampleValue}}) => {
  console.log('exampleValue should be 5:', exampleValue)
  let selection = content.getSelection().toString()
  sendAsyncMessage('VimFx-config:selection', {selection})
})
```
