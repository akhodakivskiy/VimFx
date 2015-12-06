<!--
This is part of the VimFx documentation.
Copyright Simon Lydell 2015.
See the file README.md for copying conditions.
-->

# Options

VimFx has many options that can be configured, but they all have nice defaults
so you shouldn’t need to.

You might also be interested in [styling] VimFx and writing a [config file].

[styling]: styling.md
[config file]: config-file.md


## Regular options

These options are available in VimFx’s settings page in the Add-ons Manager
(where you can also customize all [keyboard shortcuts]).

[keyboard shortcuts]: shortcuts.md

### Hint chars

The characters used for the hints in Hints mode, which can be entered using one
of the many `f` commands. See also [The `f` commands].

[The `f` commands]: commands.md#the-f-commands-1

### Previous/Next page patterns

Space separated lists of patterns that match links to the previous/next page.
Used by the `[` and `]` commands. Example:

    *example.com*  http://example.org/editor/*

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

Space separated list of URLs where VimFx should automatically enter Ignore mode.

Note that the URLs in the list must match the current URL _entirely_ for it to
apply. Therefore it is easiest to always use the `*` wildcard (which matches
zero or more characters).

(Set the option to `*` to make VimFx start out in Ignore mode _everywhere._)

You might also want to read about the [Ignore mode `<s-f1>` command][s-f1].

[s-f1]: commands.md#ignore-mode-s-f1

### Prevent autofocus

Many sites autofocus their search box, for example. This might be annoying when
browsing using the keyboard, as you do with VimFx, because it often feels like
VimFx isn’t responding, until you realize that you are typing in a text box—not
running VimFx commands!

For this reason VimFx can prevent autofocus. It’s not enabled by default,
though, since one of VimFx’s key features is to be nice to your browser and your
habits.

If enabled, all focusing that occurs on page load, or after you’ve just switched
back to a tab from another, until you interact with the page is prevented.

#### Technical notes and trivia

Autofocus on page load and when coming back to a tab are the two most common
cases. Some sites, though, automatically focus a text input in other cases as
well. Trying to catch those cases as well, VimFx used to prevent all focusing
that didn’t occur within a fixed number of milliseconds after your last
interaction (click or keypress). However, this proved to be too aggressive,
preventing too much focusing. In other words, the time-based check was not
sufficent to distinguish between inteded focusing and automatic unwanted
focusing. It made things worse more than it helped. Since these cases are so
difficult (if not impossible) to detect, it is better to leave them. Thankfully
they are not very common.

On page load or when coming back to a tab, before you have interacted with the
page in any way, we can be _sure_ that any focusing is automatic (not caused by
you), which makes it safe to prevent all focusing in those time spans.

### Ignore keyboard layout

If you use more than one keyboard layout, you probably want to enable this
option.

People who use a keyboard layout _without_ the letters A–Z usually also use the
standard en-US QWERTY layout as well.

This option makes VimFx ignore your current layout and pretend that the standard
en-US QWERTY layout is _always_ used. This way the default shortcuts work even
if your layout doesn’t contain the letters A–Z and all shorcuts can be typed by
the same physical keys on your keyboard regardless of your current keyboard
layout.

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

### `notifications_enabled`

Controls whether [notifications] should be shown or not.

You can also choose to show notifications any way you want by listening for the
[the `notification` and `hideNotification` events][notification-events].

[notifications]: notifications.md
[notification-events]: api.md#the-notification-and-hidenotification-events

### `notify_entered_keys`

If enabled, a [notification] is shown with the the keys you have entered so far
of a command. This is only noticeable if you type a multi-key shortcut or use a
count.

[notification]: notifications.md

### `prevent_target_blank`

You might have noticed that some links open in new tabs when you click them.
That is not the case if you “click” them using VimFx’s `f` command, though. If
you dislike that, disable this option.

### `ignore_ctrl_alt`

This option is enabled by default on Windows, and disabled otherwise.

If enabled, ignores ctrl+alt for printable keys. `<a-c-$>` becomes `$` and
`<a-c-A>` becomes `A`, while `<a-c-enter>` stays the same.

This option is suitable on Windows, which treats [AltGr as
ctrl+alt][wikipedia-altgr]. For example, if a user of the sv-SE layout on
Windows holds AltGr and presses the key labeled `4`, in order to produce a `$`,
the result would be `<a-c-$>` without this option, making it impossible to
trigger a keyboard shortcut containing `$`. _With_ this option the result is
`$`, as expected (and as on GNU/Linux). On the other hand it won’t be possible
to trigger keyboard shortcuts such as `<a-c-a>`, but ctrl+alt keyboard shortcuts
are [discouraged on Windows][wikipedia-altgr] anyway because of this reason.

[wikipedia-altgr]: https://en.wikipedia.org/wiki/AltGr_key#Control_.2B_Alt_as_a_substitute

### `prevent_autofocus_modes`

Space separated list of modes where `prevent_autofocus` should be used.

### `hints_timeout`

The number of milliseconds a matched hint marker should stay on screen before
disappearing (or resetting).

### Scrolling prefs

Apart from its own prefs, VimFx also respects a few built-in Firefox prefs.

#### Smooth scrolling

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

The Firefox pref `general.smoothScroll` lets you turn off smooth scrolling
entirely, including all of VimFx’s scrolling commands.

`general.smoothScroll.lines`, `general.smoothScroll.pages`, and
`general.smoothScroll.other` lets you selectively disable smooth scrolling.
VimFx’s scrolling commands follow the same “lines,” “pages” and “other”
categorization as in the above list.

#### Scroll step

By default you can scroll using the arrow keys in Firefox. You can control how
much they scroll by adjusting the following prefs:

- `toolkit.scrollbox.horizontalScrollDistance`: `<left>`, `<right>`, `h`, `l`
- `toolkit.scrollbox.verticalScrollDistance`:   `<down>`, `<up>`,    `j`, `k`

(VimFx used to have a `scroll_step` pref, but is has been replaced by the
above.)

#### `scroll.full_page_adjustment` and `scroll.half_page_adjustment`

An important use case for scrolling a full page down is to read an entire page
(a window-full) of text, press `<space>` and then continue reading the next
page. However, if you can only see, say, _half_ of the height the last line,
pressing `<space>` would give you the other half, but reading only the top or
bottom parts of letters is difficult. Even if the lines happen to line up with
the window edge to not be sliced horizontally, it might feel disorienting
pressing `<space>`.

For this reason, both VimFx and Firefox by default scroll _about a line less
than a whole page_ when pressing `<space>`. This solves the sliced-last-line
problem, and provides some context on where you are in the text you’re reading.

These two prefs control how many pixels “about a line” actually means for the
different page scrolling commands.

- `scroll.full_page_adjustment`: `<space>, `<s-space>`
- `scroll.half_page_adjustment`: `d`, `u`

#### `scroll.last_position_mark`

The special mark for the [`` ` ``][scroll-to-mark] command that takes you to the
last position.

[scroll-to-mark]: commands.md#marks-m-and-

### `pattern_selector`

A CSS selector that targets candidates for a previous/next page link.

### `pattern_attrs`

A space-separated list of attributes that the previous/next page patterns should
be matched against.

### `hints_toggle_in_tab`

If the keypress that matched a hint starts with this string, toggle whether to
open the matched link in the current tab or a new tab. See [The `f` commands]
for more information.

### `hints_toggle_in_background`

If the keypress that matched a hint starts with this string, open the matched
link in a new tab and toggle whether to open that tab in the background or
foreground. See [The `f` commands] for more information.

### `activatable_element_keys`

Keys that should not trigger VimFx commands but be sent through to the page if
an “activatable” element (link or button) is focused.

### `adjustable_element_keys`

Keys that should not trigger VimFx commands but be sent through to the page if
an “adjustable” element (form control or video player) is focused.

### `focus_previous_key` and `focus_next_key`

The default values are `<s-tab` and `<tab>`, respectively. Those keys are
specially handled after focusing a text input using [`gi`]. To disable this
special handling, set the prefs to the empty string.

[`gi`]: commands.md#gi-1


## Special options

These options are available in neither VimFx’s settings page in the Add-ons
Manager nor in [about:config]. The only way to change them is by using the
[public API].

### `translations`

See the description of the `translations` option in [vim-like-key-notation].

[vim-like-key-notation]: https://github.com/lydell/vim-like-key-notation#api

### `categories`

See the documentation for [`vimfx.get('categories')`][categories].

[categories]: api.md#vimfxgetcategories
