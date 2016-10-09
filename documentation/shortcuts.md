<!--
This is part of the VimFx documentation.
Copyright Simon Lydell 2015, 2016.
See the file README.md for copying conditions.
-->

# Shortcuts

All of VimFx’s keyboard shortcuts can be customized in VimFx’s options page in
the Add-ons Manager. Doing so is really easy. You get far just by looking at the
defaults and trying things out. If not, read on.

In VimFx’s Keyboard Shortcuts help dialog (which can be opened by pressing `?`)
you can click any command to open VimFx’s options page in the Add-ons Manager
and automatically select the text input for that command. Tip: Use the `eb`
command to click without using the mouse.

Shortcuts tell which keys to press to activate a command. A command may have
several different shortcuts. Read about [modes] for more information.

This file documents how the shortcuts work in general, not the [default
shortcuts] or details on what the [_command_][commands] for a shortcut does.

[modes]: modes.md
[default shortcuts]: https://github.com/akhodakivskiy/VimFx/blob/master/extension/lib/defaults.coffee
[commands]: commands.md


## Key notation

VimFx’s key notation is inspired by Vim’s key notation.

Here is an example of what you can type into a text input for a command in
VimFx’s options page in the Add-ons Manager:

    J  <c-s-tab>  <c-j>  gT  g<left>

The above defines five alternative shortcuts for the same command. The first
three consist of one key each, while the rest consist of two. Letters can be
written as they are, while non-letter keys like Tab and the arrow keys need to
be put inside `<` and `>`. If you want to specify a modifier, then letters need
to be put inside `<` and `>` as well (as in the `<c-j>` example, which might be
notated as “CTRL+J” in some other programs.)

You can specify any number of shortcuts for every command. Separate them from
each other by one or more spaces.

### Helper keyboard shortcuts

When you have focused the text input for one of all commands, there are a few
handy keyboard shortcuts that help you with editing your shortcuts:

- `<c-q>`: Use this when you’re unsure on how to express a keypress you’d like
  to use as part of a shortcut. First, press `<c-q>`. Then, press your desired
  key (optionally holding modifier keys). That will paste the key notation for
  that particular keypress into the text input. For example: First press
  `<c-q>`. Then hold down ctrl and press `[`. That results in `<c-[>` being
  inserted into the text input.

- `<c-d>`: Pastes the default shortcut(s) into the text input.

- `<c-r>`: Resets the text input to the default entirely.

- `<c-z>`: Undo. (This is simply the standard undo feature of your operating
  system. It’s just mentioned because it is easy to forget that it can actually
  be used here.)

(`<c-d>`, `<c-r>` and `<c-z>` also work in other VimFx setting inputs, such as
the [“Previous”/“Next” link patterns].)

[“Previous”/“Next” link patterns]: options.md#previousnext-link-patterns

### A bit more formal description

A _shortcut_ consists of one or more _keys_ that you need to press in order to
activate the command. (See also the [timeout] option.)

A _key_ corresponds to pressing a single key on your keyboard, optionally while
holding one or more _modifiers._ The following modifiers are recognized:

- a: alt
- c: control (also known as ctrl)
- m: meta
- s: shift

(Which of the above you can actually use depends on your operating system.)

If you’d like to know even more about the key notation, see
[vim-like-key-notation].

[timeout]: options.md#timeout
[vim-like-key-notation]: https://github.com/lydell/vim-like-key-notation


## Tips

If you use more than one keyboard layout, remember to check out the [Ignore
keyboard layout] option.

If you’d like see what VimFx interprets a key stroke as, you can (ab)use the
[`m`] command. Press `m` followed by your desired key stroke. A [notification]
will appear, including the interpreted key notation for that keypress.

[Ignore keyboard layout]: options.md#ignore-keyboard-layout
[`m`]: commands.md#marks-m-and-
[notification]: notifications.md


## Special keys

Just like Vim, VimFx has a few “special keys:”

- [`<force>`]
- [`<late>`]

No keyboard (or keyboard layout) can produce those (in practise). As a
consequence, putting one of those “keys” in a shortcut would normally make it
impossible to trigger. However, that is not the case for special keys.

By putting a special key at the beginning of a shortcut, the shortcut will work
exactly as it would without the special key, except that some behavior of the
shortcut is changed (depending on the special key used). Special keys specify an
_option_ for the shortcut rather than a key to press in order to activate the
command.

Each special key is described below.

[`<force>`]: #force
[`<late>`]: #late

### `<force>`

The `<force>` special key makes the shortcut in question available in text
inputs.

VimFx enters a kind of “automatic insert mode” when you focus a text input,
allowing you to type text into it without triggering VimFx commands. The `esc`
command, however, is still available, allowing you to blur the text input by
pressing `<escape>`. The reason it is available is because the default shortcut
is `<force><escape>`.

Using `<force>` allows you to run other commands in text inputs as well. For
example, you could use `<force><a-j>` and `<force><a-k>` to be able to select
tab backward and forward regardless if you happen to be in a text input or not.

Notice that VimFx’s [button] turns grey when you’re in this “automatic insert
mode.”

[button]: button.md

### `<late>`

The `<late>` special key makes the shortcut in question run _after_ the handling
of keypresses in the current page, allowing the current page to override it.

Normally, all of VimFx’s shortcuts are triggered _before_ the current page gets
the keypresses. This makes the VimFx shortcuts work consistently regardless of
what the current page happens to be up to.

Sometimes, though, it is useful to let the page override a shortcut. For
example, if you plan to use the arrow keys for VimFx’s scrolling commands, while
still being able to move the focus in the custom menus some sites use.
