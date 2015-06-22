<!--
This is part of the VimFx documentation.
Copyright Simon Lydell 2015.
See the file README.md for copying conditions.
-->

# Options

VimFx has many options that can be configured, but they all have nice defaults
so you shouldn’t need to.

You might also be interested [styling] VimFx and writing a [config file].

[styling]: styling.md
[config file]: config-file.md


## Regular options

These options are available in VimFx’s settings page in the Add-ons Manager.

### Hint chars

The characters used for the hints in Hints mode, which can be entered using one
of the many `f` commands. See also [The `f` commands].

[The `f` commands]: commands.md#the-f-commands-1

### Previous/Next page patterns

Space separated lists of patterns that match links to the previous/next page.
Used by the `[` and `]` commands.

There is a standardized way for websites to tell browsers the URLs to the
previous and next page. VimFx looks for that information in the first place.
Unfortunately, many websites don’t provide this information. Then VimFx falls
back on looking for links on the page that seem to go to the previous/next page
using patterns.

The patterns are matched at the beginning and end of link text (and the
attributes defined by the advanced setting [`pattern_attrs`]). The patterns do
not match in the middle of words, so “previous” does not match “previously”.
The matching is case <strong>in</strong>sensitive.

Actually, the patterns are regular expressions. If you do not know what a
regular expression is, that’s fine. You can type simple patterns like the
default ones without problems. If you do know what it is, though, you have the
possibility to create more advanced patterns if needed.

Some of the default patterns are English words. You might want to add
alternatives in your own language.

Note: If you need to include a space in your pattern, use `\s`. For example:
`next\spage`.

[`pattern_attrs`]: #pattern_attrs

### Blacklist

Space separated list of URLs where VimFx should automatically enter Insert mode.

Note that the URLs in the list must match the current URL _entirely_ for it to
apply. Therefore it is easiest to always use the `*` wildcard (which matches
zero or more characters).

### Prevent autofocus

Many sites autofocus their search box, for example. This might be annoying when
browsing using the keyboard, as you do with VimFx, because it often feels like
VimFx isn’t responding, until you realize that you are typing in a text box—not
running VimFx commands!

For this reason VimFx prevents autofocus. If you dislike that, or think the
prevention is too aggressive, you may disable it, returning to the standard
behavior.

What is meant by “aggressive”? Well, in fact it is very hard to tell if a focus
was an “autofocus” or a “regular focus” caused by you. VimFx prevents all
focusing that doesn’t happen reasonably close (200ms by default) to an
interaction by you (such as clicking something or using one of the `f`
commands). (You may change what “reasonably close” means through the advanced
setting [`autofocus_limit`]).

[`autofocus_limit`]: #autofocus_limit

### Ignore keyboard layout

If you use more than one keyboard layout, you probably want to enable this
option.

People who use a keyboard layout without the letters A-Z usually also use the
standard en-US QWERTY layout as well.

This option makes VimFx ignore your current layout and pretend that the standard
en-US QWERTY layout is always used. This way the default shortcuts work even if
your layout doesn’t contain the letters A-Z and all shorcuts can be typed by the
same physical keys on your keyboard regardless of your current keyboard layout.

(If you’d like VimFx to pretend that some other keyboard layout than the
standard en-US QWERTY is always used, you may do so with the special option
[`translations`].)

[`translations`]: #translations

### Timeout

The maximum amount of time (in milliseconds) that may pass between two
keypresses of a shortcut.

It’s easy to press, say, `a` by mistake while browsing. Without a timeout, you
might be surprised that all search results are highlighted when you a bit later
try to search using the `/` command. (That’s what `a/` does.) _With_ a timeout,
the `a` would be cancelled when the timeout has passed.


## Advanced options

These options are _not_ available in VimFx’s settings page in the Add-ons
Manager. They can only be changed in [about:config] or using the [public API].
They all start with `extensions.VimFx.`.

(There are actually a few more advanced options than those listed here. You can
see them all in [defaults.coffee].)

[about:config]: http://kb.mozillazine.org/About:config
[public API]: api.md
[defaults.coffee]: ../extension/lib/defaults.coffee

### `prevent_target_blank`

You might have noticed that some links open in new tabs when you click them.
That is not the case if you “click” them using VimFx’s `f` command, though. If
you dislike that, disable this option.

### `autofocus_limit`

If `prevent_autofocus` is enabled, all focus events except those that occur
within this number of milliseconds after a user interaction are suppressed.

### `prevent_autofocus_modes`

Space separated list of modes where `prevent_autofocus` should be used.

### `hints_timeout`

The number of milliseconds a matched hint marker should stay on screen before
disappearing (or resetting).

### Scrolling prefs

If you want to customize Firefox’s smooth scrolling, adjusting
`general.smoothScroll.{lines,pages,other}.duration{Min,Max}MS` is the way to
go. VimFx has similar prefs for the scrolling commands, but they work like
`layout.css.scroll-behavior.spring-constant`.

Basically, the higher the value, the faster the scrolling.

These are VimFx’s variants, and the commands they affect:

- `smoothScroll.lines.spring-constant`: `h`, `l`, `j`, `k`
- `smoothScroll.pages.spring-constant`: `d`, `u`, `<space>`, `<s-space>`
- `smoothScroll.other.spring-constant`: `gg`, `G`, `0`, `^`, `$`

Note that the value of these prefs are _strings,_ not numbers!

VimFx’s scrolling commands also respect a few built-in Firefox prefs.

`general.smoothScroll` lets you turn off smooth scrolling entirely, including
all of VimFx’s scrolling commands.

`general.smoothScroll.lines`, `general.smoothScroll.pages`, and
`general.smoothScroll.other` lets you selectively disable smooth scrolling.
VimFx’s scrolling commands follow the same “lines,” “pages” and “other”
categorization as in the above list.

By default you can scroll using the arrow keys in Firefox. You can control how
much they scroll by adjusting the following prefs:

- `toolkit.scrollbox.horizontalScrollDistance`: `<left>`, `<right>`, `h`, `l`
- `toolkit.scrollbox.verticalScrollDistance`:   `<down>`, `<up>`,    `j`, `k`

(VimFx used to have a `scroll_step` pref, but is has been replaced by the
above.)

### `pattern_selector`

A CSS selector that targets candidates for a previous/next page link.

### `pattern_attrs`

A space-separated list of attributes that the previous/next page patterns should
be matched against.

### `activatable_element_keys`

Keys that should not trigger VimFx commands but be sent through to the page if
an “activatable” element (link or button) is focused.

### `adjustable_element_keys`

Keys that should not trigger VimFx commands but be sent through to the page if
an “adjustable” element (form control or video player) is focused.


## Special options

These options are available in neither VimFx’s settings page in the Add-ons
Manager nor in [about:config]. The only way to change them is by using the
[public API].

### `translations`

See the description of the `translations` option in [vim-like-key-notation].

[vim-like-key-notation]: https://github.com/lydell/vim-like-key-notation#api
