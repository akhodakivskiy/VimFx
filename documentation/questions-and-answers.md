<!--
This is part of the VimFx documentation.
Copyright Simon Lydell 2015.
See the file README.md for copying conditions.
-->

# Questions & Answers

## How do i re-map `<escape>` to blur text inputs?

The default shortcut is actually `<force><escape>`! Don’t forget [`<force>`] at
the beginning, and your new shortcut should work fine.

[`<force>`]: shortcuts.md#force

## What does `<force><late><tab>` mean?

- `<force>`: The shortcut works even in text inputs.
- `<late>`: The page can override it.
- `<tab>`: Press the Tab key to trigger it.

Need more explaination? Read about [special keys].

[special keys]: shortcuts.md#special-keys

## Will VimFx provide advanced Find features?

One VimFx’s key feauters is to embrace standard Firefox features. As long as
Firefox’s Find Bar doesn’t support for example reverse search (vim’s `?`
command) or regex search, VimFx won’t either.

The [public API] could be used, though, to integrate with another Add-on that
provides advanced Find features.

[public API]: api.md
