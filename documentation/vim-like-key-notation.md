Overview [![Build Status](https://travis-ci.org/lydell/vim-like-key-notation.svg?branch=master)](https://travis-ci.org/lydell/vim-like-key-notation)
========

Parse and generate vim-like key notation for modern browsers, with support for
different keyboard layouts especially in mind.

A sneak peek:

```js
var notation = require("vim-like-key-notation")

document.addEventListener("keydown", function(event) {
  // The usual way.
  if (
    event.key === "Escape" &&
    event.shiftKey && event.ctrlKey &&
    !event.altKey && !event.metaKey
  ) {
    runCommand()
  }

  // With vim-like-key-notation.
  if (notation.stringify(event) === "<c-s-escape>") {
    runCommand()
  }
}, true)
```

vim-like-key-notation is used by [VimFx].

[VimFx]: https://github.com/akhodakivskiy/VimFx


Installation
============

`npm install vim-like-key-notation`

```js
var notation = require("vim-like-key-notation")
```


The notation
============

In short
--------

- Simple characters: `a`, `A`, `/`, `>`.
- Others: `<Escape>`, `<Enter>`, `<ArrowLeft>`.
- Modifiers: `<c-a>`, `<c-A>`, `<a-m-/>`, `<c-gt>`.
- Sequences: `<c-w>a`, `<2j`, `<Esc>>`, `<lt>Esc>>`.

In detail
---------

The basic rule is that each character represents itself.

`a` means that an “a” (lowercase) should be typed, which usually means hitting
the key labeled with an “A” on your keyboard.

`A` means that an “A” (uppercase) should be typed. Most likely you’d do that by
holding a shift key and pressing the same key as you did when typing an “a”
(lowercase).

`/` means that a “/” (slash) should be typed, regardless of whether that means
hitting a key labeled with a “/” (en-US QWERTY layout), or holding a shift key
and pressing a key labeled “7” (sv-SE QWERTY layout), or whatever.

The notation allows writing sequences of keys to be pressed in order. `ab` means
that an “a” should be typed, and then a “b” (both lowercase). `Esc` means that
an “E” (uppercase), followed by an “s” (lowercase), followed by a “c”
(lowercase) should be typed.

So how do you express the “Esc” (or “Escape”) key?

`<Esc>` means that the “Esc” key should be typed, which usually means hitting
the key labeled “Esc” or “Escape” on your keyboard. “Esc” normally doesn’t
result in a character on the screen, like “a”, “A”, “/” and “?” mentioned
before. Instead, it triggers other things.

“Esc”, as well as many other keys such as “Backspace”, “Shift” and “ArrowLeft”
are so called non-printable keys, while “a”, “A”, “/” and “?” are printable
keys.

In short, printable keys are notated the way they are, while non-printable keys
are notated by their name enclosed by `<` and `>`. In other words, the
non-printable keys in the previous paragraph would be notated as `<Backspace>`,
`<Shift>` and `<ArrowLeft>`.

The names of non-printable keys are case-insensitive, so you can say
`<backspace>`, `<SHIFT>` and `<arrowLEFT>` as well.

There is a [list of the names for non-printable keys][keylist] available on
[MDN]. Beyond those, there are a couple of aliases, mostly to support names
used by vim. After all, this module is called vim-like-key-notation.

Just like printable keys, you can type sequences of non-printable keys as well.
`<Esc><Backspace>` means first hitting the “Esc” key and then the “Backspace”
key. You may mix printable and non-printable keys as well. `<Esc>a` means
hitting “Esc” and then typing “a”.

But if `<` and `>` are used to denote non-printable keys, how do you express the
`<` and `>` keys themselves? `<` and `>` will do fine. Just watch out if you
want to use both `<` and `>` in a sequence. `<>bs`, `><bs` and `bs<>` all mean
that the characters “<”, “>”, “b” and “s” should be typed in different orders,
while `<bs>` means that the “Backspace” key should be pressed (“bs” is an alias
for “Backspace”). To escape that meaning, there is an alternate way of
expressing the `<` and `>` keys: `<lt>` and `<gt>`, respectively. (You may use
their aliases `<less>` and `greater`). While they look like non-printable keys
named “lt” and “gt”, they actually represent the printable keys `<` and `>`.
This allows to write `<lt>bs>`, `<bs<gt>` or `<lt>bs<gt>` to escape the meaning
of “Backslash”.

While talking about notation that looks like non-printable keys, there is yet
one: Space. It is denoted as `<Space>`, not ` `. That’s because ` ` isn’t
very readable. It is the same way for tabs and newlines; they’re called `<Tab>`
and `<Enter>`, respectively. (All three of those keys can actually be considered
to be in a middle-ground between printable and non-printable keys.)

Actually, you may put any printable character inside `<` and `>` (other than `<`
and `>`). In other words `<a>`, `<A>`, `</>` and `<?>` are equivalent to `a`,
`A`, `/` and `?`, respectively. The shorter forms are nothing other than just
that—_shorter forms._

There are a few special keys of the keyboard called modifiers, that can be held
while pressing another key. That other key is then modified, which makes it
carry along a list of all modifier keys that were held down when the key in
question was pressed. The pressed key then usually gets different behavior.
vim-like-key-notation supports the alt, ctrl and meta modifiers.

`<c-a>` means that an “a” (lowercase) should be typed while the ctrl modifier is
held. `<m-a>` means the same thing, but this time the meta modifier should be
held instead. As yet an example, `<a-a>` concerns the alt modifier.

You may specify more than one modifier. `<c-a-m-a>` means that an “a”
(lowercase) should be typed while all three of the ctrl, alt and meta modifiers
are held. In other words, to specify a modifier, make sure that the key is
wrapped with `<` and `>` and put the first letter of the name of the modifier
followed by a `-` after the `<`. (To modify `<` and `>` use `<c-lt>` and
`<m-a-gt>`, for example.)

The order of the modifiers does not matter. Neither does the case of the
modifier letters. `<c-a-m-a>` and `<M-c-A-a>` are equivalent.

What about shift? Isn’t that modifier, too? It is actually a bit of an odd bird.
It’s both a modifier and a layer switch. (The other modifiers can technically
work like shift does as well, but that is less common.)

Holding shift while pressing a printable key usually makes the key output a
different character than it normally would. For example, holding shift while
pressing the key labeled “A” outputs an “A” in the majority of keyboard layouts,
while the key would have produced an “a” if the shift key hadn’t been held.
Holding shift while pressing the key labeled with a “7” might produce an “&” or
a “/” (depending on the keyboard layout). In these cases shift enables a
different layer of your keyboard, making keys do other things than they do
otherwise.

For non-printable keys, holding shift usually makes no difference. Instead,
shift works as modifier.

Therefore, it is allowed to specify shift as a modifier for non-printable
keys—but only for them.

`<s-Esc>` means that the “Esc” key should be pressed while shift is held.

(In some systems it is technically _possible_ to make shift work as a layer
switch even on non-printable keys, but in practice nobody does that.)

`<s-a>` is an error. Write `<A>` or `A` instead (or whatever is produced by
holding shift and pressing the key that otherwise would output an “a”). Likewise
for `<s-/>`. It is invalid. For the en-US QWERTY layout, use `?`.

There are a few printable keys that are exceptions to the above rule. `<Space>`,
`<Tab>` and `<Enter>` are all allowed to have the shift modifier specified.
(Again, they are a middle-ground between printable and non-printable keys).

The part about shift is important to remember. In many programs you may see
instructions to press something like ctrl+shift+a. Don’t try to recreate such a
shortcut in vim-like-key-notation by writing `<c-s-a>`. That’s an error. The
correct way is most likely `<c-A>`.

Why have this restriction on the shift “modifier”? The technical answer is that
browsers do not have access to the current keyboard layout. While it is
extremely likely that “`<s-a>`” means `A`, it is impossible to know if “`<s-/>`”
means `?`, some other character or if the shift modifier is even _required_ to
type a `/` (such as when `/` is typed by pressing “`<s-7>`”).

This “untraditional” handling of shift might seem odd, but it depends on your
point of view. vim-like keys are _different._ In most other circumstances,
pressing “a” and “A” means the same thing: Hitting the key labeled “A”, without
holding shift. But not in vim. There, case matters. “a” means lowercase only,
and “A” uppercase only. vim does not care whether or not you need to press shift
to produce any of those characters. Moreover, in most other circumstances,
ctrl+shift+a and CTRL+SHIFT+A means the same thing (even though the former uses
a lowercase “a” while the latter uses an uppercase “A”). Since unmodified “a”
and “A” are different in vim, it is the most consistent if `<c-a>` and `<c-A>`
are different too. By distinguishing between “a” and “A” specifying shift is
redundant—even ambigous: For example, try to explain the differences between
`<c-4>`, `<c-$>`, `<c-s-4>` and `<c-s-$>` in the en-US QWERTY layout. (Even if
the browser would have access to the current keyboard layout it is difficult to
consistently define them all!)

An alternate rule for shift could be to always require it to be explicitly
specified in the notation. For example, `<c-$>` would not be possible to enter
using the en-US keyboard layout (because in that layout it is impossible to type
a `$` without holding shift), but `<c-s-$>` would be. However, this poses a
couple of problems. First off, to be consistent you’d have to write `<s-A>`
instead of `A`. Secondly, it would be very surprising that `<s-a>` would not
work as you’d probably expect (`<s-A>` would be the correct notation). Thirdly,
it complicates sharing shortcuts with other people. For example, the standard
keyboard shortcut for searching in vim is `/`. Let’s say that you’ve created an
alternate search mode. To make the shortcut easy to remember, you’ve bound it to
`<c-/>`. If you try to share that setup with a user of the sv-SE QWERTY layout,
that person would not be able to trigger your alternate search mode. In that
layout the shortcut would be `<c-s-/>`.

That’s the reason the shift “modifier” is handled the way it is. Complicated?
Nah. You just might to get used to it.

[keylist]: https://developer.mozilla.org/en-US/docs/Web/API/KeyboardEvent.key#Key_values
[MDN]: https://developer.mozilla.org/


Technical notes
===============

vim-like-key-notation requires that [`event.key`] and [`event.code`] are
available on keyboard events. When this was written, only Firefox 38+ supports
both of those by default. (Edit: As of 2017, Chrome 51+ also supports both.)

In case you haven’t heard about those two new properties of keyboard event
objects, here’s a little summary.

`event.key` is the character that would be typed by the keypress (such as “a”,
“A”, “/” and “?”), or a name of the key that would be sent if the key is
non-printable (such as “Escape”, “ArrowLeft” and “Shift”). This property takes
your current keyboard layout as well as shift in account, so the same physical
key on your keyboard might give a different `event.key` value if you switch
layouts or depending on if you hold shift or not.

`event.code` is a unique name for each key of your keyboard, that stays the same
regardless of your current layout, and regardless of whether shift is held or
not. The names come from the standard en-US QWERTY layout, such as “Escape”,
“ShiftLeft”, “KeyA” and “Digit1”. If the standard en-US QWERTY layout is used,
it is easy to guess what those keys do. However, we cannot know that for sure.
Fo example, if the AZERTY layout is used, “KeyA” will produce a “q”, not an “a”!

Both `event.key` and `event.code` are the same in all three keyboard
events—`keydown`, `keypress` and `keyup`. Best of all, the values are
standardized, which should reduce cross-browser problems in the future.

If you’ve ever worked with `event.keyCode`, `event.charCode` and `event.which`
you might see why `event.key` and `event.code` are superior. They are far easier
to use (meaningful string names instead of integer codes), and far more reliable
when it comes to international keyboard layouts.

For vim-like-key-notation’s purposes, `event.key` is perfect, so that is used
mainly. `event.key` lets you specify a keyboard shortcut as `/` (slash), and it
will work both for an en-US QWERTY user who has a key labeled “/”, and at the
same time for an sv-SE QWERTY user who needs to hold shift and press a key
labeled “7” to type a “/”. It doesn’t matter that the two users press two
different keys and that one of them needs to hold shift—it just works in both
cases.

However, many people use more than one keyboard layout. This is common when you
need to type both using the latin alphabet as well as the cyrillc or the greek
alphabet, or whatever. As far as I know, the most common setup is the usage of
the en-US QWERTY layout in combination with a non-latin layout. On most cyrillic
keyboards both the en-US QWERTY characters as well as the local ones are printed
on the keys.

The problem arises when there’s a shortcut such as `a` and the user currently
happens to not use the en-US QWERTY layout. Even if he presses the key labeled
“A”, the `a` shortcut won’t trigger, because the character that would be
typed—and `event.key`—is a Cyrillic character, not “a”!

Another problem is that characters that are common between layouts, such as `.`,
might be at different locations. While the user might not have any problems with
the `.` key to be in different locations while typing in different languages, it
most certainly will be a problem for keyboard shortcuts. Using shortcuts isn’t
typing. After a while it is mostly muscle memory, which means that moving things
around is a very bad idea.

Therefore vim-like-key-notation allows you to ignore the current layout.
Instead, the en-US QWERTY layout will be assumed. For this purpose, `event.code`
is perfect.

If the current layout is ignored, it doesn’t matter which layout the user
currently happens to use. The keyboard shortcuts stay on the same keys anyway.

Then why not always use `event.code`? Because users of only one keyboard layout
want the keyboard shortcuts to just work. They do not want to learn the en-US
QWERTY layout by heart just to be able to trigger keyboard shortcuts. Using
`event.code` in this case means that the user can never read documentation
telling which keys to press without first having to translate those keys to
their own keyboard layout. For example, an instruction might tell the user to
type “/”, but might in fact mean that he should press the key labeled “-” on his
keyboard. (People who only use the en-US QWERTY layout are an exception of
course—but the world is far larger than that.)

If the option to ignore the current keyboard layout is enabled, `event.code` is
translated into more `event.key`-like values, taking shift into account. For
example, `KeyA` is turned into `a` or `A`. `Digit1` is turned into `1` or `!`.

Note that while the current state of shift is available, the current state of
capslock isn’t, which means that capslock cannot be taken into account. Instead
it is assumed to always be off.

(Edit: Two years later, it turns out that it actually _is_ possible to detect
capslock, by using [`event.getModifierState`]. The correct shift state can then
be detected using `var shift = event.shiftKey !==
event.getModifierState("CapsLock")`, but I haven’t bothered updating
vim-like-key-notation with this.)

The numpad is an exception. `event.key` is used there even if the current layout
is set to be ignored. That’s because it is not possible to correctly emulate it.

Just as with capslock, we don’t know the state of numlock. This means that we
cannot know if `Numpad1` should result in `1` or `<End>`, for example.
Therefore, it is much more useful to the user if we actually rely on the current
layout in this case, in order not to break the numpad. This is especially
important on laptops, where `<Home>`, `<End>`, `<PageUp>` and `<PageDown>`
usually only exist there. The keypad usually doesn’t change between layouts
anyway—at least not enough to warrant drastic changes to it.

(Edit: Just like capslock (mentioned above), it actually _is_ possible to detect
numlock, by using `event.getModifierState("NumLock")`. However, I haven’t
researched whether that’s enough to emulate the numpad correctly, or whether it
is worth the trouble.)

Finally, what about those who use several layouts, but not the en-US QWERTY
layout? For example, it could be someone using the sv-SE QWERTY layout as well
as a Greek layout.

As I said, when the current keyboard layout is set to be ignored, the
`event.code` values are translated into `event.key`-like ones. This is trivial
for the en-US QWERTY layout, since the values are based on that layout.

There is another option that lets you translate the `event.code` values in a
custom way, which is a way of working around the problem. It requires the
shortcut setup to somehow allow to define these translations and some more work
from the user, but at least we’re not leaving them behind. Of course users may
share their translations to help others using the same main layout, or you may
choose to bundle a few such translations with your program. The reason no
translations other than for en-US QWERTY comes with this module, is that it
would be too much maintenance, and almost impossible to make it complete.

It is possible to provide translations even if the current layout _isn’t_ set to
be ignored, though it is of limited usefulness. One use case could be to
distinguish between the numpad numbers and the regular number keys. (There’s an
example of this in the [API](#api) section.)

You don’t have to specify translations for every key of your keyboard—only as
much as you need. If something isn’t provided in your translations table the
regular method of using `event.key` or translating `event.code` into en-US
QWERTY is used (depending on if the current layout is set to be ignored).

[`event.key`]:  https://developer.mozilla.org/en-US/docs/Web/API/KeyboardEvent.key
[`event.code`]: https://developer.mozilla.org/en-US/docs/Web/API/KeyboardEvent.code
[`event.getModifierState`]: https://developer.mozilla.org/en-US/docs/Web/API/KeyboardEvent/getModifierState


API
===

`stringify(event, options)`
---------------------------

Takes a keyboard event `event`—that has the `key` and `code` properties—and
returns the equivalent vim-like-key-notation, in a standardized way.

- All keynames are lowercase only. For example, `<space>`, not `<Space>`.
- Aliased keynames are changed to the standard `event.key` name.
- Modifiers, if any, are lowercase and sorted alphabetically. For example,
  `<a-c-s-esc>`, not `<A-s-c-esc>`.
- Printable characters are never enclosed in `<` and `>` unless they need to.
  For example, `a`, not `<a>`.
- `<` and `>` are always returned as `<lt>` and `<gt>`, respectively. This is so
  that you can safely concatenate return values from this function and then
  parse that and get the same sequence back. For example, `"<" + "a" + ">"`
  would be parsed as `<a>`, while `"<ls>" + "a" + "<gt>"` would be parsed as
  `<ls>`, `a`, `<gt>`.
- For unrecognized keys and modifiers the empty string is used. vim-like
  keyboard shortcuts do not use such keys.

`options`: (See [Technical Notes](#technical-notes) for more information).

- `ignoreCtrlAlt`: `Boolean`.

  If enabled, ignores ctrl+alt for printable keys. `<a-c-$>` becomes `$` and
  `<a-c-A>` becomes `A`, while `<a-c-enter>` stays the same.

  This option is suitable on Windows, which treats [AltGr as
  ctrl+alt][wikipedia-altgr]. For example, if a user of the sv-SE layout on
  Windows holds AltGr and presses the key labeled `4`, in order to produce a
  `$`, the result would be `<a-c-$>` without this option, making it impossible
  to trigger a keyboard shortcut containing `$`. _With_ this option the result
  is `$`, as expected (and as on GNU/Linux). On the other hand it won’t be
  possible to trigger keyboard shortcuts such as `<a-c-a>`, but ctrl+alt
  keyboard shortcuts are [discouraged on Windows][wikipedia-altgr] anyway
  because of this reason.

- `ignoreKeyboardLayout`: `Boolean`.

  If enabled, ignores the current keyboard layout and assumes that the en-US
  QWERTY layout is used.

- `translations`: `Object`.

  The keys are `event.code` strings that should be translated.

  The values are either strings or arrays of two strings. The strings are
  `event.key`-like values that the keys should be translated into. If only one
  string is provided, the key is always translated into that string. If an array
  is provided, the first value of it is used when shift is not held, and the
  other value when shift _is_ held.

  ```js
  stringify(event, {ignoreKeyboardLayout: true, translations: {
    // AZERTY mappings.
    "KeyQ": ["a", "A"],
    "KeyA": ["q", "Q"],
    // etc.

    // Swapped capslock and ctrl.
    "CapsLock":    "Control",
    "ControlLeft": "CapsLock",

    // Distinguish between regular numbers and numpad numbers by translating the
    // numpad numbers into made-up names (regardless of numlock state).
    "Numpad0": "K0",
    "Numpad1": "K1",
    "Numpad2": "K2",
    "Numpad3": "K3",
    "Numpad4": "K4",
    "Numpad5": "K5",
    "Numpad6": "K6",
    "Numpad7": "K7",
    "Numpad8": "K8",
    "Numpad9": "K9"
  }})
  ```

[wikipedia-altgr]: https://en.wikipedia.org/wiki/AltGr_key#Control_.2B_Alt_as_a_substitute

`parse(keyString)`
------------------

The inverse of `stringify`. Takes a `keyString`, and returns an event-like
object. Throws errors for invalid `keyString`s.

The `key` property will contain the key in question, with casing exactly like in
the input.

The `altKey`, `ctrlKey`, `metaKey` and `shiftKey` properties will be set to
`true` if the corresponding modifiers are present.


```js
parse("a") // {key: "a"}
parse("A") // {key: "A"}

parse("<c-m-a>")    // {key: "a", ctrlKey: true, metaKey: true}
parse("<s-escape>") // {key: "escape", shiftKey: true}
```

`normalize(keyString)`
----------------------

Simply a shortcut for `stringify(parse(keyString))`. Useful to compare different
keyStrings: `normalize("<c-s-esc>") === normalize("<s-c-Escape>")`.

`parseSequence(keySequence)`
----------------------------

Takes a `keySequence` and splits it into an array of individual keys. It does
not validate each individual key; you may use `parse` or `normalize` for that.

```js
parseSequence("<c-w>v")  // ["<c-w>", "v"]
parseSequence("<c-w")    // ["<", "c", "-", "w"]
parseSequence("<<c-w>>") // ["<", "<c-w>", ">"]

// Invalid keys.
parseSequence("<x-a><s-a><ctrl-a> <++>") // ["<x-a>", "<s-a>", "<ctrl-a>", " ", "<++>"]
parseSequence("<x-a><s-a><ctrl-a> <++>").map(parse) // Throws an error.
```


Errors
======

All errors thrown by vim-like-key-notation have an `id` property, which is a
string, and a `subject` key, which is what caused the error. Some errors have a
`context` key as well. The values of these keys are strings (unless otherwise
stated).

These are the different ids:

bad\_translation
----------------

- thrown by: `stringify(event, options)`
- context: a key in `options.translations` mapped to a bad value
- subject: the bad value (which may be of any type)

invalid\_key
------------

- thrown by: `parse(keyString)` and `normalize(keyString)`
- subject: the invalid `keyString`

unknown\_modifier
-----------------

- thrown by: `parse(keyString)` and `normalize(keyString)`
- context: the `keyString` containing the invalid modifier
- subject: an unknown modifier in `keyString`

duplicate\_modifier
-------------------

- thrown by: `parse(keyString)` and `normalize(keyString)`
- context: the `keyString` containing the duplicate modifier
- subject: a duplicate modifier in `keyString`

disallowed\_modifier
--------------------

- thrown by: `parse(keyString)` and `normalize(keyString)`
- context: the `keyString` containing the disallowed modifier
- subject: a disallowed modifier in `keyString` (in effect either `s` or `S`)

This error is thrown if you try to parse a key such as `<s-a>` (explained in
detail the notation section).


License
=======

[MIT](LICENSE).
