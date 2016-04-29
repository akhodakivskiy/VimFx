<!--
This is part of the VimFx documentation.
Copyright Simon Lydell 2016.
See the file README.md for copying conditions.
-->

# Installation

## Option 1: [addons.mozilla.org] \(AMO)

**<https://addons.mozilla.org/firefox/addon/VimFx>**

Follow the above link and hit the green “Install” button and you should be ready
to go!

- [Signed][signed] and reviewed by Mozilla.
- Hosted on AMO.
- Automatic updates.

[addons.mozilla.org]: https://addons.mozilla.org/


## Option 2: [GitHub releases][releases]

Go to VimFx’s [releases] page and click the link to “VimFx.xpi” for the version
you’re interested in (most likely the latest). Firefox should then ask you about
allowing the installation. (If not, download the .xpi file and [open it in
Firefox][open-xpi].)

- [Signed][signed] by Mozilla (but not reviewed).
- Available as a backup alternative, and in case of slow reviews on AMO.
- No automatic updates.

[releases]: https://github.com/akhodakivskiy/VimFx/releases


## Option 3: Build from source

[Build VimFx] and then [open the produced `build/VimFx.xpi` file][open-xpi].

- [Unsigned][signed].
- Bleeding edge.
- Allows you to fiddle with the code.
- No automatic updates.

[Build VimFx]: tools.md#how-to-build-and-install-the-latest-version-from-source

### How to install an .xpi file in Firefox

Firefox add-ons are .xpi files (a renamed .zip file—try renaming it to .zip and
open it like any old .zip file to see what’s inside). There are several ways of
installing them:

- Drag and drop the .xpi file into the Firefox window.
- Press ctrl+o and choose the .xpi file.
- Use “Install from file…” in the top-right menu in the Add-ons Manager.


## What is a signed add-on?

By default it is not possible to install add-ons which haven’t been signed by
Mozilla. In order for an add-on to be signed it must pass some code checks. The
idea is to protect users from malware.

If you’re interested in installing an unsigned add-on (such as if you’ve built
a VimFx .xpi from source yourself), read all about extension signing here:

<https://wiki.mozilla.org/Addons/Extension_Signing>


[open-xpi]: #how-to-install-an-xpi-file-in-firefox
[signed]: #what-is-a-signed-add-on
