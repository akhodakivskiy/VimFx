# Installation

Independently from the installation method chosen, you need Firefox version 68+
(or a compatible fork) and the [LegacyFox] shim. Both options are unsigned and
don't offer automatic updates. You may want to *watch releases* on GitHub.

[LegacyFox]: https://git.gir.st/LegacyFox.git


## Option 1: [GitHub releases][releases]

Go to VimFx’s [releases] page and click the link to “VimFx.xpi” for the version
you’re interested in (most likely the latest). Firefox should then ask you about
allowing the installation. (If not, download the .xpi file and [open it in
Firefox][open-xpi].)

[releases]: https://github.com/akhodakivskiy/VimFx/releases


## Option 2: Build from source

[Build VimFx] and then [open the produced `build/VimFx.xpi` file][open-xpi].

- Bleeding edge.
- Allows you to fiddle with the code.

[Build VimFx]: tools.md#how-to-build-and-install-the-latest-version-from-source

### How to install an .xpi file in Firefox

Firefox add-ons are .xpi files (a renamed .zip file—try renaming it to .zip and
open it like any old .zip file to see what’s inside). There are several ways of
installing them:

- Drag and drop the .xpi file into the Firefox window.
- Press ctrl+o and choose the .xpi file.
- Use “Install from file…” in the top-right menu in the Add-ons Manager.


[open-xpi]: #how-to-install-an-xpi-file-in-firefox
