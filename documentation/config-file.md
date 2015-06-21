<!--
This is part of the VimFx documentation.
Copyright Simon Lydell 2015.
See the file README.md for copying conditions.
-->

# Config file

VimFx can be configured using a configuration file. This should be done by users
who:

- prefer to configure things using text files.
- would like to add custom commands.
- would like to set [special options].
- would like to make site-specific customizations.

[special options]: options.md#special-options


## Technical notes

The config file is written in JavaScript and is actually a regular Firefox
add-on, that makes use of VimFx’s [public API].

[public API]: api.md


## Setup

1. Create a directory for your config file to live in. Actually, there will be
   _two_ files that will live in it.

2. Create an [install.rdf] file in your directory. Inside that file there is an
   extension ID; take note of it.

3. Create a [bootstrap.js] file in your directory.

4. Find the `extensions/` directory in your [profile directory].

5. In the extensions directory, do one of the following:

   - Move your config file directory into it, renamed as the extension ID.

   - Create a plain text file named as the extension ID with the absolute path
     to your config file directory inside it. You might want to read the
     documentation about such [proxy files].

   - Create a symlink named as the extension ID pointing to your config file
     directory.

6. Restart Firefox.

7. Open the [browser console]. If you copied the bootstrap.js template below,
   you should see a greeting and an inspection of VimFx’s public API.

Any time you make changes to any of your add-on files you need to restart
Firefox to make the changes take effect.

Now you might want to read about the [public API] or look at the [Custom
Commands] wiki page.

[install.rdf]: #installrdf
[bootstrap.js]: #bootstrapjs
[profile directory]: https://support.mozilla.org/en-US/kb/profiles-where-firefox-stores-user-data
[proxy files]: https://developer.mozilla.org/en-US/Add-ons/Setting_up_extension_development_environment#Firefox_extension_proxy_file
[browser console]: https://developer.mozilla.org/en-US/docs/Tools/Browser_Console
[Custom Commands]: https://github.com/akhodakivskiy/VimFx/wiki/Custom-Commands


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

This is the actual config file, written in JavaScript.

Here is a boilerplate that you can copy as is:

```js
function startup() {
  Components.utils.import('resource://gre/modules/Services.jsm')
  Components.utils.import('resource://gre/modules/devtools/Console.jsm')
  let api_url = Services.prefs.getCharPref('extensions.VimFx.api_url')
  Components.utils.import(api_url, {}).getAPI(vimfx => {

    // Do things with the `vimfx` object between this line
    console.log('Hello, word! This is vimfx:', vimfx)
    // and this line.

  })
}
function shutdown() {}
function install() {}
function uninstall() {}
```
