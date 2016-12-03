<!--
This is part of the VimFx documentation.
Copyright Simon Lydell 2015, 2016.
See the file README.md for copying conditions.
-->

# Options

VimFx has many options that can be configured, but they all have nice defaults
so you shouldn’t need to.

Advanced users might also be interested in [styling] VimFx and writing a [config
file].

[styling]: styling.md
[config file]: config-file.md


## Regular options

These options are available in VimFx’s options page in the Add-ons Manager
(where you can also customize [keyboard shortcuts]).

[keyboard shortcuts]: shortcuts.md

### Prevent autofocus

`prevent_autofocus`

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
sufficient to distinguish between intended focusing and automatic unwanted
focusing. It made things worse more than it helped. Since these cases are so
difficult (if not impossible) to detect, it is better to leave them. Thankfully
they are not very common.

On page load or when coming back to a tab, before you have interacted with the
page in any way, we can be _sure_ that any focusing is automatic (not caused by
you), which makes it safe to prevent all focusing in those time spans.

### Ignore keyboard layout

`ignore_keyboard_layout`

If you use more than one keyboard layout, you probably want to enable this
option.

People who use a keyboard layout _without_ the letters A–Z usually also use the
standard en-US QWERTY layout as well.

This option makes VimFx ignore your current layout and pretend that the standard
en-US QWERTY layout is _always_ used. This way the default shortcuts work even
if your layout doesn’t contain the letters A–Z and all shortcuts can be typed by
the same physical keys on your keyboard regardless of your current keyboard
layout.

Note that when filtering hints markers by element text (but not when typing hint
characters) in [Hints mode], your current layout _is_ used, even if you’ve
enabled ignoring of it. That’s because otherwise you wouldn’t be able to filter
by element text in any other language than English.

If you have modified your keyboard layout slightly using software, such as
having swapped `<capslock>` and `<escape>`, this option will cause VimFx to
ignore that as well. If that’s unwanted, you need to tell VimFx about your
layout customizations by using the special option [`translations`].

If you’d like VimFx to pretend that some other keyboard layout than the standard
en-US QWERTY is always used, that’s also a job for the special option
[`translations`].

[Hints mode]: commands.md#the-hint-commands--hints-mode
[`translations`]: #translations

### Blacklist

`blacklist`

Space separated list of URL patterns where VimFx should automatically enter
Ignore mode. Example:

    *example.com*  http://example.org/editor/*

**The fastest way** to blacklist the page you’re currently on, is to **use the
`gB` command.** It opens a modal with a text input filled in with the blacklist,
and with `*currentdomain.com*` added at the start for you! Edit it if needed, or
just press `<enter>` straight away to save. Ignore mode is then automatically
entered (if the URL patterns apply).

Note that the URLs in the list must match the current URL _entirely_ for it to
apply. Therefore it is easiest to always use the `*` wildcard (which matches
zero or more characters).

Set the option to `*` to make VimFx start out in Ignore mode _everywhere._

When you’re done editing the blacklist, go to one of the pages you intend to
match. If you already have a tab open for that page, reload it. Then look at
VimFx’s [button] to see if your edits work out.

Note that when Ignore mode is automatically entered because of the blacklist, it
is also automatically exited (returning to Normal mode) if you go to a
non-blacklisted page in the same tab. On the other hand, if you entered Ignore
mode by pressing `i`, you’ll stay in Ignore mode in that tab until you exit it,
even if you navigate to another page.

You might also want to read about the [Ignore mode `<s-f1>` command][s-f1].

[button]: button.md
[s-f1]: commands.md#ignore-mode-s-f1

#### Blacklisting specific elements

VimFx automatically enters Ignore mode while Vim-style editors are focused, such
as the [wasavi] extension and [CodeMirror editors in Vim mode][codemirror-vim].

By default, VimFx lets you press `<escape>` to blur text inputs. Also by
default, Vim-style editors use `<escape>` to exit from their Insert mode to
their Normal mode. In other words, there is a keyboard shortcut conflict here.

It makes the most sense to let the Vim-style editor “win.” That’s why VimFx
(temporarily) enters Ignore mode when focusing such an editor. In Ignore mode,
there is no `<escape>` shortcut (by default), and thus no conflict. Instead,
there’s `<s-escape>` to blur the current element and exit Ignore mode.
`<s-escape>` was chosen because it is very unlikely to cause conflicts. If it
ever does, there’s the [`<s-f1>`] command to the rescue.

There is currently no way of specifying your own elements to be blacklisted, but
such a feature could be added if there’s demand for it.

[wasavi]: http://appsweets.net/wasavi/
[codemirror-vim]: https://codemirror.net/demo/vim.html
[`<s-f1>`]: commands.md#ignore-mode-s-f1

### Hint characters

`hints.chars`

The characters used for the hints in Hints mode, which can be entered using one
of the many [hint commands].

**Tip:** Prefer filtering hints by element text? Use only uppercase hint
characters (such as `FJDKSLAGHRUEIWONC MV`), or only numbers (`01234567 89`).

[hint commands]: commands.md#the-hint-commands--hints-mode

#### Filtering hints by element text

All characters other than the hint characters are used to filter hint markers by
element text.

The filtering works like in Firefox’s location bar. In short, that means:

- It is case insensitive.
- Your typed characters are split on spaces. Each part must be present in the
  element text (in any order, and they may overlap).

By default, “f” is a hint character. If you type an “f”, that character is used
to match the hints on screen. If you type an “F” (uppercase), though, which is
_not_ a hint character by default, you will filter the hints based on element
text, causing some hints markers to disappear, and the rest to be replaced. Only
the markable elements with text containing an “f” or “F” will now get a hint
marker. All the “f”s and “F”s are highlighted on the page, to help you keep
track of what’s going on. Keep typing other non-hint characters to further
reduce the number of hint markers, and make the hints shorter all the time.

Hint markers are usually displayed in uppercase, because it looks nicer.
However, if you mix both lowercase and uppercase hint characters, they will be
displayed as-is, so you can tell them apart. It is recommended to either use
_only_ lowercase or _only_ uppercase characters, though.

Some people prefer to filter hint markers by element text in the first hand,
rather than typing hint characters. If so, it is a good idea to choose all
uppercase hint characters, or only numbers. This way, you can press `f` and then
simply begin typing the text of the link you wish to follow.

#### Easy-to-type and performant hints

Quick suggestion: Put more easily reachable keys longer to the left. Put two
pretty good (but not the best) keys at the end, after the space.

Some hint characters are easier to type than others. Many people think that the
ones on the home row are the best. VimFx favors keys to the left. That’s why you
should put better keys longer to the left.

The hint characters always contain a single space. This splits them into two
groups: _primary_ hint characters (before the space), and _secondary_ hint
characters (after the space). Read on to find out why.

Some markable elements are quicker to find than others. Therefore, VimFx looks
for markable elements in two passes for some commands, such as the `f` command.
(This is why all hints don’t always appear on screen at the same time). If two
passes are used, hints from the _first_ pass can only begin with _primary_ hint
characters. In all other cases hints may start with _any_ hint character.

When choosing how many secondary hint characters you want (there are two by
default), think about this: Usually most markable elements are found in the
first pass, while fewer are found in the second pass. So it makes sense to have
more primary hint characters than secondary. It’s a tradeoff. If you think the
hints from the first pass are too long, you probably need more primary hint
characters. On the other hand, if you think the hints from the _second_ pass are
too long, you might need a few extra secondary hint characters, but remember
that it might be at the expense of longer hints in the first pass.

All of this also help you understand why hints may be slow on some pages:

- One reason could be that most hints come from a second pass, which are slower
  to compute (and are worse than first pass hints).

  If a site gets an unusual amount of second pass hints, it might be because the
  site is badly coded accessibility-wise. If so, consider contacting the site
  and telling them so, which improves their accessibility for everyone!

- Another reason could be that a page has a _huge_ amount of links. If that
  bothers you regularly, feel free to send a pull request with faster code!

### Hint auto-activation

`hints.auto_activate`

The marker (or marker<strong>s</strong> in the case where several links go to
the same place and have gotten the same hint) with the best hint are highlighted
with a different color. You may at any time press `<enter>` to activate those
markers.

One workflow is to type non-hint characters until the hint marker of the element
you want to activate gets highlighted, and then hit `<enter>`. To make this more
obvious, the entire element text is selected, too. However, if _all_ hint
markers end up highlighted (because the text you’ve typed uniquely identifies a
single link) the highlighted markers will be activated _automatically._

If you dislike that, disable this option. Then, you either have to press
`<enter>` or a hint character to activate hint markers.

### Auto-activation timeout

`hints.timeout`

If you type quickly, you might find that you will keep typing even after a hint
marker has been automatically activated (see [Hint auto-activation]). You might
simply not react that quickly. This might cause you to accidentally trigger
VimFx commands. Therefore, VimFx ignores all your keypresses for a certain
number of milliseconds when having automatically activated a hint marker after
filtering by element text. This option controls exactly how many milliseconds
that is.

If you can’t find a timeout that works for you, you might want to disable [Hint
auto-activation] instead.

[Hint auto-activation]: #hint-auto-activation

### Timeout

`timeout`

The maximum amount of time (in milliseconds) that may pass between two
keypresses of a shortcut.

It’s easy to press, say, `a` by mistake while browsing. Without a timeout, you
might be surprised that all search results are highlighted when you a bit later
try to search using the `/` command. (That’s what `a/` does.) _With_ a timeout,
the `a` would be cancelled when the timeout has passed.

### “Previous”/“Next” link patterns

`prev_patterns`/`next_patterns`

Space separated lists of patterns that match links to the previous/next page.
Used by the `[` and `]` commands.

There is a standardized way for websites to tell browsers the URLs to the
previous and next page. VimFx looks for that information in the first place.
Unfortunately, many websites don’t provide this information. Then VimFx falls
back on looking for links on the page that seem to go to the previous/next page
using patterns.

The patterns are matched at the beginning and end of link text (and the
attributes defined by the advanced option [`pattern_attrs`]). The patterns do
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


## Advanced options

These options are _not_ available in VimFx’s options page in the Add-ons
Manager. They can only be changed in [about:config] or using a [config file].
They all start with `extensions.VimFx.`.

Don’t feel that you have to go through all of these options in order to get the
most from VimFx! Really, there’s no need at all to change the defaults unless
you’ve run into some edge case.

(There are actually a few more advanced options than those listed here. You can
see them all in [defaults.coffee].)

[about:config]: http://kb.mozillazine.org/About:config
[config file]: config-file.md
[defaults.coffee]: ../extension/lib/defaults.coffee

### `notifications_enabled`

Controls whether [notifications] should be shown or not.

You can also choose to show notifications any way you want by listening for the
[the `notification` and `hideNotification` events][notification-events].

[notifications]: notifications.md
[notification-events]: api.md#the-notification-and-hidenotification-events

### `notify_entered_keys`

If enabled, a [notification] is shown with the keys you have entered so far of
a command. This is only noticeable if you type a multi-key shortcut or use a
count, or if you filter hint markers by element text (then, the text you’ve
typed will be shown).

[notification]: notifications.md

### `prevent_target_blank`

You might have noticed that some links open in new tabs when you click them.
That is not the case if you “click” them using VimFx’s `f` command, though. If
you dislike that, disable this option.

### `counts_enabled`

Controls whether [counts] are enabled or not.

[counts]: commands.md#counts

### `find_from_top_of_viewport`

Toggles whether the various find commands are Vim-style or Firefox
default-style.

Disable this option if you want `/` to work more like `<c-f>` and `n`/`N` to
work more like `<f3>`/`<s-f3>`.

If there is selected text on the page, Firefox starts searching after that.
VimFx does so too, but only if the selection is currently _visible_ (inside the
current viewport).

If there _isn’t_ selected text on the page, Firefox starts searching from the
top of the page. VimFx instead starts searching from the top of the current
viewport.

The VimFx behavior is designed to be less disorienting. It is also similar to
how searching in Vim works. Again, you can return to the Firefox default
behavior (if you prefer that) by disabling this option.

One of the main benefits of the VimFx behavior is that you can scroll past a
block of the text with lots of search matches and then continue going through
matches with `n` after that block, without having to spam `n` lots and lots of
times.

### `browsewithcaret`

[Caret mode] uses [Firefox’s own Caret mode] under the hood. This means that
VimFx temporarily enables the Firefox option `accessibility.browsewithcaret`
when you are in VimFx’s Caret mode. When you leave Caret mode, that option is
turned off again.

VimFx automatically syncs the `browsewithcaret` option with
`accessibility.browsewithcaret`. If you change the latter manually (such as by
using the Firefox default shortcut `<f7>`), VimFx’s option is changed as well,
so you shouldn’t really have to touch this option at all.

[Caret mode]: commands.md#caret-mode
[Firefox’s own Caret mode]: http://kb.mozillazine.org/Accessibility_features_of_Firefox#Allow_text_to_be_selected_with_the_keyboard

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

### `config_file_directory`

VimFx can optionally be customized using a [config file]. If you want to that,
you need to tell VimFx where that file is. That’s what this option is for.

By default this option is blank (the empty string), which means that no config
file should be loaded.

If non-blank, it should be the path to the directory where the config file
exists. See the [config file] documentation for more information.

[config file]: config-file.md

### `blur_timeout`

The number of milliseconds VimFx should wait after an element has been blurred
before checking if you’re inside a text input or not.

Some sites with fancy text inputs (such as twitter) blur the text input for a
split second and then re-focus it again while typing (for some reason). If you
happen to press a key during that split second, that key might trigger a VimFx
shortcut instead of typing into the text input, which can be quite annoying. To
avoid the problem, VimFx waits a bit before checking if you have left the text
input.

### `refocus_timeout`

If you switch to another window while a text input is focused, Firefox actually
blurs the text input. If you then switch back again, Firefox will re-focus the
text input.

VimFx tracks that case, so that the [Prevent autofocus] option does not think it
should prevent that refocus. Unfortunately, the tracking requires a timeout.
This option let’s you customize that timeout (measured in milliseconds).

If you experience that text input focus is lost after switching back to Firefox
from another window, you might want to increase this timeout.

[Prevent autofocus]: #prevent-autofocus

### Scrolling options

Apart from its own options, VimFx also respects a few built-in Firefox options.

#### Smooth scrolling

If you want to customize Firefox’s smooth scrolling, adjusting
`general.smoothScroll.{lines,pages,other}.duration{Min,Max}MS` is the way to
go. VimFx has similar options for the scrolling commands, but they work like
`layout.css.scroll-behavior.spring-constant`.

Basically, the higher the value, the faster the scrolling.

These are VimFx’s variants, and the commands they affect:

- `smoothScroll.lines.spring-constant`: `h`, `l`, `j`, `k`
- `smoothScroll.pages.spring-constant`: `d`, `u`, `<space>`, `<s-space>`
- `smoothScroll.other.spring-constant`: `gg`, `G`, `0`, `^`, `$`, `'`

Note that the value of these options are _strings,_ not numbers!

Unfortunately, Firefox provides no way for code to tell which “spring constant”
it wants when scrolling smoothly. All VimFx can do is to temporarily set
Firefox’s `layout.css.scroll-behavior.spring-constant` option. It is reset again
after one second (by default). If that doesn’t work out for you, you can
customize that timeout using the `scroll.reset_timeout` option.

Another quirk of Firefox’s smooth scrolling is that it doesn’t like if you ask
for smooth scrolling too often: The scrolling can get stuttery, progressively
slower and even grind to a halt. On a long page with lots of elements, simply
holding `d`, `u`, `<space>` or `<s-space>` can be too much. By default, keyboard
software typically repeats keypresses every 30ms when holding keys. Because of
this, VimFx only asks for smooth scrolling if more than 65ms (two repeats) has
passed since the last request. You can customize that timeout via the
`scroll.repeat_timeout` option.

The Firefox option `general.smoothScroll` lets you turn off smooth scrolling
entirely, including all of VimFx’s scrolling commands.

`general.smoothScroll.lines`, `general.smoothScroll.pages`, and
`general.smoothScroll.other` lets you selectively disable smooth scrolling.
VimFx’s scrolling commands follow the same “lines,” “pages” and “other”
categorization as in the above list.

#### Scroll step

By default you can scroll using the arrow keys in Firefox. You can control how
much they scroll by adjusting the following options:

- `toolkit.scrollbox.horizontalScrollDistance`: `<left>`, `<right>`, `h`, `l`
- `toolkit.scrollbox.verticalScrollDistance`:   `<down>`, `<up>`,    `j`, `k`

(VimFx used to have a `scroll_step` option, but is has been replaced by the
above.)

#### `scroll.horizontal_boost` and `scroll.vertical_boost`

When holding down `h`, `l`, `j` or `k` (rather than just tapping those keys),
their scrolling speed is sped up, just like when you hold down an arrow key to
scroll. These options control _how much_ the mentioned commands are sped up. The
usual scroll distances are multiplied by these numbers.

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

These two options control how many pixels “about a line” actually means for the
different page scrolling commands.

- `scroll.full_page_adjustment`: `<space>, `<s-space>`
- `scroll.half_page_adjustment`: `d`, `u`

#### `scroll.last_position_mark` and `scroll.last_find_mark`

These options allow you to customize the [special marks] for the
[`'`][scroll-to-mark] command.

[special marks]: commands.md#special-marks
[scroll-to-mark]: commands.md#marks-m-and-

### `pattern_selector`

A CSS selector that targets candidates for a previous/next page link.

### `pattern_attrs`

A space-separated list of attributes that the [“Previous”/“Next” link patterns]
should be matched against.

[“Previous”/“Next” link patterns]: #previousnext-link-patterns

### `hints.matched_timeout`

The number of milliseconds a matched hint marker should stay on screen before
disappearing (or resetting).

### `hints.sleep`

In Hints mode, VimFx continually checks if the element for a hint marker has
moved. If so, the marker is moved as well. This option controls how many
milliseconds VimFx should “sleep” between each check. The shorter, the more CPU
usage, the longer, the more stuttery marker movement.

The default value should work fine, but if you have a low-performing computer
and you notice bothering CPU usage during Hints mode you might want to raise the
sleep time.

Set it to -1 to disable the marker movement feature entirely.

### `hints.match_text`

If you strongly dislike that typing non-[Hint characters] filters hint markers
by element text, disable this option. (That’ll make things work like it did in
VimFx 0.18.x and older.)

[Hint characters]: #hint-characters

### `hints.peek_through`

This option doesn’t do much. If you’ve used custom [styling] to change which
modifier lets you peek through markers in [Hints mode], you might want to change
this option as well. Otherwise VimFx’s Keyboard Shortcuts dialog will still tell
you to press shift for this task.

[styling]: styling.md
[Hints mode]: commands.md#the-hint-commands--hints-mode

### `hints.toggle_in_tab`

If the keypress that matched a hint starts with this string, toggle whether to
open the matched link in the current tab or a new tab. See the [hint commands]
for more information.

### `hints.toggle_in_background`

If the keypress that matched a hint starts with this string, open the matched
link in a new tab and toggle whether to open that tab in the background or
foreground. See the [hint commands] for more information.

### `activatable_element_keys`

Keys that should not trigger VimFx commands but be sent through to the page if
an “activatable” element (link or button) is focused.

### `adjustable_element_keys`

Keys that should not trigger VimFx commands but be sent through to the page if
an “adjustable” element (form control or video player) is focused.

### `focus_previous_key` and `focus_next_key`

The default values are `<s-tab` and `<tab>`, respectively. Those keys are
specially handled after focusing a text input using [`gi`]. To disable this
special handling, set the options to the empty string.

[`gi`]: commands.md#gi-1


## Special options

These options are available in neither VimFx’s options page in the Add-ons
Manager nor in [about:config]. The only way to change them is by using the
a [config file].

### `translations`

This option is only useful if you use the [Ignore keyboard layout] option. As
mentioned in the documentation for that option, `translations` exist to let you:

- Teach VimFx about layout customizations you’ve made, that otherwise get
  ignored.
- Make VimFx pretend that some other keyboard layout than the standard en-US
  QWERTY is always used.

Here’s some example usage:

```js
vimfx.set('translations', {
  // Swapped <capslock> and <escape>.
  'CapsLock': 'Escape',
  'Escape': 'CapsLock',

  // AZERTY mappings.
  'KeyQ': ['a', 'A'],
  'KeyA': ['q', 'Q'],
  // etc.

  // Bonus: Distinguish between regular numbers and numpad numbers by
  // translating the numpad numbers into made-up names (regardless of numlock
  // state). Then, you can use `<k0>` to `<k9>` in shortcuts.
  'Numpad0': 'K0',
  'Numpad1': 'K1',
  'Numpad2': 'K2',
  'Numpad3': 'K3',
  'Numpad4': 'K4',
  'Numpad5': 'K5',
  'Numpad6': 'K6',
  'Numpad7': 'K7',
  'Numpad8': 'K8',
  'Numpad9': 'K9',
})
```

More formally, `translations` is an object where:

- The object keys are [`event.code`] strings that should be translated.

- The object values are either strings or arrays of two strings.

  If an array is provided, the first value of it is used when shift is _not_
  held, and the other value when shift _is_ held.

  If only one string is provided, that value is always used (regardless of the
  shift state).

  The strings are what you want VimFx to treat the pressed key as. For example,
  providing `Escape` will cause the translated key to match VimFx shortcuts
  containing `<Escape>` (or `<escape>`—the case doesn’t matter).

At this point, you might be wondering why these options to ignore your keyboard
layout and translate keys have to exist. It’s all about the data that is
available in Firefox (basically [`event.key`] and [`event.code`]). There is a
longer technical explanation in [vim-like-key-notation], the library VimFx uses
for dealing with keyboard stuff.

[Ignore keyboard layout]: #ignore-keyboard-layout
[`event.code`]: https://developer.mozilla.org/en-US/docs/Web/API/KeyboardEvent/code
[`event.key`]: https://developer.mozilla.org/en-US/docs/Web/API/KeyboardEvent/key
[vim-like-key-notation]: https://github.com/lydell/vim-like-key-notation#technical-notes

### `categories`

See the documentation for [`vimfx.get('categories')`][categories].

[categories]: api.md#vimfxgetcategories
