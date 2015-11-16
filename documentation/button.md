<!--
This is part of the VimFx documentation.
Copyright Simon Lydell 2015.
See the file README.md for copying conditions.
-->

# Button

VimFx has a toolbar button. It looks like this: ![VimFx button icon].

If you focus a text input, the icon is greyed out. This is to show that your key
presses will be passed into the text input rather than activating VimFx
commands.

When in Normal mode, clicking it opens VimFx’s Keyboard Shortcuts dialog, just
like the `?` shortcut does.

In other modes, clicking it returns you to normal mode. If you feel like VimFx
does not respond to any of your key presses, it might be because you’re not in
Normal mode. If you don’t know how to exit that mode (or have accidentally
removed the keyboard shortcut to do so), clicking the button is the way to
“escape” back to Normal mode. (On such occasions, you can hover the button and
its tooltip will say what mode you’re currently in.)

In Ignore mode, the icon also turns red, like this: ![VimFx button icon red].
([Blacklisted] sites enter Ignore mode automatically.) The reason is that the
whole point of Ignore mode is to “ignore” all of VimFx’s commands, passing your
key presses to the page instead. It is helpful to know that you’re really in
Ignore mode, so you can be confident that your key presses do what you expect
them to. (See [Styling] if you’d like to highlight Ignore mode, or any mode for
that matter, some other way.)

Other modes are easily detectable. You know that you’re in Find mode if the find
bar is focued. If there are hint markers visible for the page, you’re in Hints
mode.

A quick takeaway from this part of the documentation: **If you don’t know what’s
going on, look for VimFx’s toolbar button.** It can often help you.

[VimFx button icon]: ../extension/skin/icon16.png
[VimFx button icon red]: ../extension/skin/icon16-red.png
[Blacklisted]: options.md#blacklist
[Styling]: styling.md
