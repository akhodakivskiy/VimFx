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

[custom commands]: api.md#vimfxaddcommandoptions-fn
[special options]: options.md#special-options
[overrides]: api.md#vimfxaddoptionoverridesrules-and-vimfxaddkeyoverridesrules
[hint-matcher]: api.md#vimfxhintmatcher


## Technical notes

The config file is written in JavaScript and is actually a regular Firefox
add-on, that makes use of VimFx’s [public API].

[public API]: api.md


## Setup

1. Create a directory for your config file to live in. Actually, there will be
   _three_ files that will live in it.

2. Create an [install.rdf] file in your directory. Inside that file there is an
   extension ID; take note of it.

3. Create a [bootstrap.js] and a [vimfx.js] file in your directory.

4. Find the `extensions/` directory in your [profile directory].

5. In the extensions directory, do one of the following:

   - Move your config file directory into it, renamed as the extension ID.

   - Create a plain text file named as the extension ID with the absolute path
     to your config file directory inside it. You might want to read the
     documentation about such [proxy files].

   - Create a symlink named as the extension ID pointing to your config file
     directory.

6. Restart Firefox.

7. Open the [browser console]. If you copied the [bootstrap.js] and [vimfx.js]
   templates below, you should see a greeting and an inspection of VimFx’s
   public API.

Any time you make changes to any of your add-on files you need to restart
Firefox to make the changes take effect.

Now you might want to read about the [public API] or look at the [Custom
Commands][custom-commands-wiki] wiki page.

[install.rdf]: #installrdf
[bootstrap.js]: #bootstrapjs
[vimfx.js]: #vimfxjs
[profile directory]: https://support.mozilla.org/en-US/kb/profiles-where-firefox-stores-user-data
[proxy files]: https://developer.mozilla.org/en-US/Add-ons/Setting_up_extension_development_environment#Firefox_extension_proxy_file
[browser console]: https://developer.mozilla.org/en-US/docs/Tools/Browser_Console
[custom-commands-wiki]: https://github.com/akhodakivskiy/VimFx/wiki/Custom-Commands


## install.rdf

This file tells Firefox that this is an add-on and provides some information
about it. You’ll probably look at this once and not touch it again.

Here is a boilerplate that you can copy without changing anything (unless you
feel like it):

```rdf
<?xml version="1.0" encoding="utf-8"?>
<RDF xmlns="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
     xmlns:em="http://www.mozilla.org/2004/em-rdf#">
  <Description about="urn:mozilla:install-manifest">

    <!-- Edit from here ... -->
    <em:name>VimFx-custom</em:name>
    <em:id>VimFx-custom@vimfx.org</em:id>
    <em:version>1</em:version>
    <!-- ... to here (if you feel like it). -->

    <em:bootstrap>true</em:bootstrap>
    <em:multiprocessCompatible>true</em:multiprocessCompatible>
    <em:type>2</em:type>
    <em:targetApplication>
      <Description>
        <em:id>{ec8030f7-c20a-464f-9b0e-13a3a9e97384}</em:id>
        <em:minVersion>38</em:minVersion>
        <em:maxVersion>*</em:maxVersion>
      </Description>
    </em:targetApplication>
  </Description>
</RDF>
```

You might also want to read the [install.rdf documentation].

[install.rdf documentation]: https://developer.mozilla.org/en-US/Add-ons/Install_Manifests


## bootstrap.js

This file starts up your add-on. Just like [install.rdf], you’ll probably look
at this once and not touch it again.

Here is a boilerplate that you can copy as is. All it does is loading VimFx’s
public API, as well as some very commonly used Firefox APIs, and passing those
to [vimfx.js].

```js
let {classes: Cc, interfaces: Ci, utils: Cu} = Components
function startup() {
  Cu.import('resource://gre/modules/Services.jsm')
  Cu.import('resource://gre/modules/devtools/Console.jsm')
  let apiPref = 'extensions.VimFx.api_url'
  let apiUrl = Services.prefs.getComplexValue(apiPref, Ci.nsISupportsString).data
  Cu.import(apiUrl, {}).getAPI(vimfx => {
    let path = __SCRIPT_URI_SPEC__.replace('bootstrap.js', 'vimfx.js')
    let scope = {Cc, Ci, Cu, vimfx}
    Services.scriptloader.loadSubScript(path, scope, 'UTF-8')
  })
}
function shutdown() {}
function install() {}
function uninstall() {}
```


## vimfx.js

This is the actual config file, written in JavaScript.

```js
console.log('Hello, world! This is vimfx:', vimfx)
```


## Frame script API and custom commands that access web page content

If you plan to use the [frame script API], or to add custom commands that need
to access web page content, you have to add two more files and make an
adjustment to bootstrap.js.

[frame script API]: api.md#frame-script-api

### bootstrap.js adjustment

In bootstrap.js there is one function called `startup` and one called
`shutdown`. At the end of the `startup` function, add the following:

```js
Cc['@mozilla.org/globalmessagemanager;1']
  .getService(Ci.nsIMessageListenerManager)
  .loadFrameScript('chrome://vimfx-custom/content/frame.js', true)
```

Inside the `shutdown` function, add the following:

```js
Cc['@mozilla.org/globalmessagemanager;1']
  .getService(Ci.nsIMessageListenerManager)
  .removeDelayedFrameScript('chrome://vimfx-custom/content/frame.js')
```

That will load a so called “frame script,” named [frame.js] in our case, and
unload it when your add-on shuts down.

[frame.js]: #framejs

### chrome.manifest

In order for Firefox to be able to find [frame.js], you need to add a file
called `chrome.manifest` with the following contents:

```
content vimfx-custom ./
```

[frame.js]: #framejs

### frame.js

Finally you of course need to add the file frame.js itself. Add any code that
needs access web page content inside this file.

### Example

Here’s a typical pattern used in custom commands that communicate with a frame
script:

```js
let {messageManager} = vim.window.gBrowser.selectedBrowser
let callback = ({data: {selection}}) => {
  messageManager.removeMessageListener('VimFx-custom:selection', callback)
  console.log('Currently selected text:', selection)
}
messageManager.addMessageListener('VimFx-custom:selection', callback)
messageManager.sendAsyncMessage('VimFx-custom:getSelection', {exampleValue: 1337})
```

And here’s some accompaning frame script code:

```js
addMessageListener('VimFx-custom:getSelection', ({data: {exampleValue}}) => {
  console.log('exampleValue should be 5:', exampleValue)
  let selection = content.getSelection().toString()
  sendAsyncMessage('VimFx-custom:selection', {selection})
})
```
