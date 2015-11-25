<!--
This is part of the VimFx documentation.
Copyright Simon Lydell 2015.
See the file README.md for copying conditions.
-->

# Shortcuts

All of VimFx’s keyboard shortcuts can be customized in VimFx’s settings page in
the Add-ons Manager. Doing so is really easy. You get far just by looking at the
defaults and trying things out. If not, read on.


## Key notation

VimFx’s key notation is inspired by Vim’s key notation. An example:

    J  gT  <c-s-tab>  g<left>  <c-j>

The above defines five alternative shortcuts. The odd ones consist of one key
each, while the even ones consist of two. Letters can be written as they are,
while non-letter keys like Tab and the arrow keys need to be put inside `<` and
`>`. Letters also need to be put inside `<` and `>` if you want to specify a
modifier (as in the `<c-j>` example, which might be notated as “CTRL+J” in some
other programs.)

If you’re usure on how to express a key press you’d like to use as part of a
shortcut, press `<c-q>` while inside one of the text inputs for a command and
then press your desired key (optionally holding modifier keys). That will paste
the key notation for that particular key press into the text input. `<c-d>`
pastes the default shortcut(s), and `<c-r>` resets the text input to the default
entirely. You can of course use the standard `<c-z>` to undo.

You can specify any number of shortcuts for every command. Separate them from
each other by one or more spaces.

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
will appear, including the interpreted key notation for that key press.

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

### `<late>`

The `<late>` special key makes the shortcut in question run _after_ the handling
of key presses in the current page, allowing the current page to override it.

Normally, all of VimFx’s shortcuts are triggered _before_ the current page gets
the key presses. This makes the VimFx shortcuts work consistently regardless of
what the current page happens to be up to.

Sometimes, though, it is useful to let the page override a shortcut. For
example, if you plan to use the arrow keys for VimFx’s scrolling commands, while
still being able to move the focus in the custom menus some sites use.
