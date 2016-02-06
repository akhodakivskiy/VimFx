<!--
This is part of the VimFx documentation.
Copyright Simon Lydell 2016.
See the file README.md for copying conditions.
-->

# Modes


## Summary

VimFx’s functionality is contained in an hierarchy.

1. There are several _modes._

   Modes decide how VimFx works.

2. Each mode has several _commands._

   Commands do things.

3. Each command has several _shortcuts._

   Shortcuts tell which keys to press to activate a command.

These are the modes of VimFx:

- Normal mode. This is where you’ll stay most of the time, while only
  occasionally popping into another mode for a bit, before returning to Normal
  mode again.

- Ignore mode. When you want VimFx to get out of the way. In some pages it might
  make sense to [enter Ignore mode by default][blacklist] and stay in Ignore
  mode most of the time, occasionally popping into Normal mode.

- Hints mode. Entered when using the [`f` commands][f-commands] and let’s click
  things by typing the letters of hint markers.

If you’re unsure which mode you’re in, have a look at VimFx’s toolbar [button].


## Details

A mode does three things.

- It decides which _commands_ are available. Normal mode has lots of commands,
  while the point of Ignore mode is to have as few as possible. This is the most
  important point of modes.

- It decides what happens when you press keys on your keyboard. If your key
  press is part of the [shortcut] for a command, it is usually consumed by
  VimFx. If not, Normal mode and Ignore mode pass the key press on (letting it
  behave as if VimFx wasn’t even installed), while in [Hints mode][f-commands]
  _all_ key presses are captured, allowing you to type the letters of a hint
  marker.

- It tells all parts of VimFx what mode you’re in. (How surprising!) Some
  features are only enabled in certain modes. For example, [autofocus
  prevention] in only enabled in Normal mode.

All modes have a way to return to Normal mode. By default, you usually press
`<escape>`. To enter other modes, you usually run some command. For example, the
default shortcut for running the command to enter Normal mode is `i`.

Note that the mode is per tab, not global.


[blacklist]: options.md#blacklist
[autofocus prevention]: options.md#prevent-autofocus
[shortcut]: shortcuts.md
[f-commands]: commands.md#the-f-commands--hints-mode
[button]: button.md
