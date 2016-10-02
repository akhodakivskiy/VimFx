<!--
This is part of the VimFx documentation.
Copyright Simon Lydell 2015, 2016.
See the file README.md for copying conditions.
-->

# Commands

Most of VimFx’s commands are straight-forward enough to not need any
documentation. For some commands, though, there is a bit more to know.

In this document, many commands are referred to by their default shortcut. You
can of course [change those] if you like. (Read about [modes] to tell the
difference between _commands_ and _shortcuts._)

[change those]: shortcuts.md
[modes]: modes.md

## Counts

Some commands support _counts._ That means that you can type a number before a
command and it will change its behavior based on that number—the count. For
example, typing `12x` would close 12 tabs.

(As opposed to Vim, you may only supply a count _before_ a command, not in the
middle of one. That’s because VimFx’s commands are simple sequences, while Vim’s
are operators and motions.)

### `gu`

Goes _count_ levels up in the URL hierarchy.

### `H` and `L`

Goes _count_ pages backward/forward in history.

### Scrolling commands

Specifying a count make them scroll _count_ times as far.

### `J`, `K`

Selects the tab _count_ tabs backward/forward.

If the count is greater than one they don’t wrap around when reaching the ends
of the tab bar, unless:

- the first tab is selected and `J` is used.
- the last tab is selected and `K` is used.

They only wrap around _once._

### `gl`

Selects the _count_ most recently visited tab.

### `gL`

Selects the _count_ oldest unvisited tab.

Tip: It might help to make “unread” tabs visually different through custom
[styling]:

```css
// Unread, unvisited tabs (opened in the background). These are the ones that
// can be selected using `gL`.
.tabbrowser-tab[unread]:not([VimFx-visited]):not(#override) {
    font-style: italic !important;
}

// Unread but previously selected tabs (that have changed since last select).
.tabbrowser-tab[unread][VimFx-visited]:not(#override) {
    font-weight: bold !important;
}
```

[styling]: styling.md

### `gJ`, `gK`

Moves the current tab _count_ tabs forward/backward.

As opposed to `J` and `K`, pinned and non-pinned tabs are handled separately.
The first non-pinned tab wraps to the last tab, and the last tab wraps to the
first non-pinned tab, and vice versa for non-pinned tabs. Use `gp` to move a tab
between the pinned and non-pinned parts of the tab bar.

Other than the above, the count and wrap semantics work like `J` and `K`.

### `g0`, `g^`, `g$`

`g0` selects the tab at index _count,_ counting from the start.

`g^` selects the tab at index _count,_ counting from the first non-pinned tab.

`g$` selects the tab at index _count,_ counting from the end.

### `x`

Closes the current tab and _count_ minus one of the following tabs.

### `X`

Restores the _count_ last closed tabs.

### `I`

Passes on the next _count_ keypresses to the page, without activating VimFx
commands.

### The hint commands

Explained in the their own section below.

### `gi`

Explained in its own section below.


## Scrolling commands

Firefox lets you scroll with the arrow keys, page down, page up, home, end and
space by default. VimFx provides similar scrolling commands (and actually
overrides `<space>`), but they work a little bit differently.

They scroll _the currently focused element._ If the currently focused element
isn’t scrollable, the largest scrollable element on the page (if any, and
including the entire page itself) is scrolled.

You can focus scrollable elements using the `ef` command (or the `f` command).
Scrollable browser elements, such as in the dev tools, can be focused using the
`eb` command. The right border of hint markers for scrollable elements is styled
to remind of a scroll bar, making them easier to recognize among hints for
links.

Note that `ef` and `f` do _not_ add a hint marker for the _largest_ scrollable
element (such as the entire page). There’s no need to focus that element, since
it is scrolled by default if no other scrollable element is focused, as
explained above. (This prevents the largest scrollable element from likely
eating your best hint char on most pages; see [The hint commands]).

[The hint commands]: #the-hint-commands--hints-mode

### `g[` and `g]`

Each time you use `gg`, `G`, `0`, `$`, `/`, `a/`, `g/`, `n`, `N` or `'`, the
current scroll position is recorded in a list just before the scrolling command
in question is performed. You can then travel back to the scroll positions in
that list by using the `g[` command. Went too far back? Use the `g]` to go
forward again.

If the current scroll position already exists in the list, it is moved to the
end. This way, repeating `g[` you will scroll back to old positions only once.

Both `g[` and `g]` go _count_ steps in the list.

This feature is inspired by Vim’s _jump list._ Some people prefer changing the
shortcuts to `<c-o>` and `<c-i>` to match Vim’s.

### Marks: `m` and `'`

Other than traditional scrolling, VimFx has _marks._ Press `m` followed by a
letter to associate the current scroll position with that letter. For example,
press `ma` to save the position into mark _a._ Then you can return to that
position by pressing `'` followed by the same letter, e.g. `'a`.

Note: Firefox has a `'` shortcut by default. It opens the Quick Find bar. VimFx
provides the `g/` shortcut instead.

#### Special marks

Just like Vim, VimFx has a few special marks. These are set automatically.

- `'`: Pressing `''` takes you to the scroll position before the last `gg`, `G`,
  `0`, `$`, `/`, `a/`, `g/`, `n`, `N`, `'`, `g[` or `g]`.

- `/`: Pressing `'/` takes you to the scroll position before the last `/`, `a/`
  or `g/`.

(You can change these marks by using the [`scroll.last_position_mark` and
`scroll.last_find_mark`][mark-options] options.)

[mark-options]: options.md#scroll.last_position_mark-and-scroll.last_find_mark

#### Minor notes

Unlike Vim, you may press _any_ key after `m`, and the scroll position will be
associated with that key (Vim allows only a–z, roughly).

Unlike Vim and Vimium, VimFx has no global marks. The reason is that they would
be a lot more complicated to implement and do not seem useful enough to warrant
that effort.

As mentioned above, `m` stores the _current scroll position._ Specifically, that
means the scroll position of the element that would be scrolled if the active
element isn’t scrollable; see [Scrolling commands] above.

[Scrolling commands]: #scrolling-commands-1


## `gi`

`gi` focuses the text input you last used, or the first one on the page. Note
that a [prevented autofocus] still counts as having focused and used a text
input. This allows you to have your cake and eat it too: You can enable
autofocus prevention, and type `gi` when you wish you hadn’t.

`gi` takes a count. It then selects the `counth` text input on the page. Note
that `gi` and `1gi` are different: The latter _always_ focuses the first input
of the page, regradless of which input you used last.

After having focused a text input using `gi`, `<tab>` and `<s-tab>` will _only
cycle between text inputs,_ instead of moving the focus between _all_ focusable
elements as they usually do. (See also the [`focus_previous_key` and
`focus_next_key`] advanced options.)

[prevented autofocus]: options.md#prevent-autofocus
[`focus_previous_key` and `focus_next_key`]: options.md#focus_previous_key-and-focus_next_key


## The hint commands / Hints mode

When invoking one of the hint commands (such as `f`, `et` or one of the [`v`
commands]) you enter Hints mode. In Hints mode, markers with hints are shown for
some elements. By typing the letters of a hint something is done to that
element, depending on the command. You can also **type the text of an element**
with a hint marker: See the [Hint characters] option for more information.

Another way to find links on the page is to use `g/`. It’s like the regular find
command (`/`), except that it searches links only.

Which elements get hints depends on the command as well:

- `f` and `af`: Anything clickable—links, buttons, form controls.
- `F`, `et`, `ew` and `ep`: Anything that can be opened in a new tab or
  window—links.
- `yf`: Anything that has something useful to copy—links (their URL) and text
  inputs (their text).
- `ef`: Anything focusable—links, buttons, form controls, scrollable elements,
  frames.
- `ec`: Most things that have a context menu—images, links, videos and text
  inputs, but also many textual elements.
- `eb`: Browser elements, such as toolbar buttons.

It might seem simpler to match the same set of elements for _all_ of the
commands. The reason that is not the case is because the fewer elements the
shorter the hints. (Also, what should happen if you tried to `F` a button?)

(You can also customize [which elements do and don’t get hints][hint-matcher].)

Another way to make hints shorter is to assign the same hint to all links with
the same URL. So don’t be surprised if you see the same hint repeated several
times.

VimFx also tries to give you shorter hints for elements that you are more likely
to click. This is done by the surprisingly simple rule: The larger the element,
the shorter the hint. To learn more about hint characters and hint length, read
about the [Hint characters] option.

Hints are added on top of the corresponding element. If they obscure the display
too much you can hold down ctrl and shift simultaneously to make them
transparent, letting you peek through them. (See [Styling] and the
[`hints.peek_through`] option if you’d like to change that.) The hints can also
sometimes cover each other. Press `<c-space>` and `<s-space>` to switch which
one should be on top.

Yet another way to deal with areas crowded with hint markers is to type part of
a marker’s element text. That will filter out hint markers whose elements
_don’t_ match what you’ve typed. Pagination links are good examples, like these
(fake) ones: [1](#1) [2](#2) [3](#3) [4](#4) [5](#5) [6](#6). It’s very hard to
tell which hint to use to go to page three. But if you type “3” things will be
much clearer. (It might even [auto-activate][Hint auto-activation] the hint
marker!)

When giving a count to a hint command, all markers will be re-shown after you’ve
typed the hint characters of one of them, _count_ minus one times. All but the
last time, the marker’s link will be opened in a new background tab. The last
time the command opens links as normal (in the current tab (`f`) or in a new
background (`F`) or foreground tab (`et`)).

Note that the hint command adds markers not only to links, but to buttons and
form controls as well. What happens the _count_ minus one times then? Buttons,
checkboxes and the like are simply clicked, allowing you to quickly check many
checkboxes in one go, for example. Text inputs cancel the command.

`af` works as if you’d supplied an infinite count to `f`. (In fact, the `af`
command is implemented by running the same function as for the `f` command,
passing `Infinity` as the `count` argument!) Therefore the `af` command does not
accept a count itself.

The `et`, `ef`, `yf` and `eb` commands do not accept counts.

Press `<up>` to increase the count by one. This is useful when you’ve already
entered Hints mode but realize that you want to interact with yet a marker. This
can be faster than going into Hints mode once more.

If you’ve pressed `f` but realize that you’d rather open a link in a new tab you
can hold ctrl while typing the last hint character. This is similar to how you
can press `<c-enter>` on a focused link to open it in a new tab (while just
`<enter>` would have opened it in the same tab). Hold alt to open in a new
foreground tab. In other words, holding ctrl works as if you’d pressed `F` from
the beginning, and holding alt works as if you’d pressed `et`.

For the `F` and `et` commands, holding ctrl makes them open links in the same
tab instead, as if you’d used the `f` command. Holding alt toggles whether to
open tabs in the background or foreground—it makes `F` work like `et`, and `et`
like `F`. As mentioned in [Hint auto-activation], the best hint is highlighted
with a different color, and can be activated by pressing `<enter>`. Holding alt
or ctrl works there too: `<c-enter>` toggles same/new tab and `<a-enter>`
toggles background/foreground tab.

(Also see the advanced options [`hints.toggle_in_tab`] and
[`hints.toggle_in_background`].)

Finally, if the element you wanted to interact with didn’t get a hint marker you
can try pressing `<c-backspace>` while the hints are still shown. That will give
hint markers to all _other_ elements. Warning: This can be very slow, and result
in an overwhelming amount of hint markers (making it difficult to know which
hint to activate sometimes). See this as an escape hatch if you _really_ want to
avoid using the mouse at all costs. (Press `<c-backspace>` again to toggle back
to the previous hints.)

### Mnemonics and choice of default hint command shortcuts

The main command is `f`. It comes from the Vimium and Vimperator extensions. The
mnemonic is “<strong>f</strong>ollow link.” It is a good key, because on many
keyboard layouts it is located right under where your left index finger rests.

The most common variations of `f` are centered around that letter: `F`, `yf` and
`af`. (Some users might want to swap `F` and `et`, though.) In Vim, it is not
uncommon that an uppercase letter does the same thing as its lowercase
counterpart, but with some variation (in this case, `F` opens links in new tabs
instead of in the current tab), and `y` usually means “yank” or “copy.” VimFx
also has this pattern that `a` means “all.”

You can think of the above commands as the “f commands.” That sounds like
“eff-commands” when you say it out loud, which is a way of remembering that the
rest of the `f` variations are behind the `e` key. That’s also a pretty good
key/letter, because it is close to `f` both alphabetically, and physically in
many keyboard layouts (and is pretty easy to type).

The second key after `e` was chosen based on mnemonics: There’s `et` as in
<strong>t</strong>ab, `ew` as in <strong>w</strong>indow, `ep` as in
<strong>p</strong>rivate window, `ef` as in <strong>f</strong>ocus, `ec` as in
<strong>c</strong>ontext menu and `eb` as in <strong>b</strong>rowser.

[`v` commands]: #the-v-commands--caret-mode
[hint-matcher]: api.md#vimfxsethintmatcherhintmatcher
[Hint characters]: options.md#hint-characters
[Hint auto-activation]: options.md#hint-auto-activation
[Styling]: styling.md
[`hints.peek_through`]: options.md#hints.peek_through
[`hints.toggle_in_tab`]: options.md#hints.toggle_in_tab
[`hints.toggle_in_background`]: options.md#hints.toggle_in_background


## The `v` commands / Caret mode

The point of Caret mode is to copy text from web pages using the keyboard.

### Entering Caret mode

Pressing `v` will enter Hints mode with hint markers for all elements with text
inside. When activating a marker, its element will get a blinking caret at the
beginning of it, and Caret mode will be entered.

The `av` command does the same thing as `v`, but instead of placing the caret at
the beginning of the element, it selects the entire element (it selects
<strong>a</strong>ll of the element).

The `yv` command brings up the same hint markers as `av` does, and then takes
the text that `av` would have selected and copies it to the clipboard. It does
not enter Caret mode at all.

The letter `v` was chosen for these shortcuts because that’s what Vim uses to
enter its Visual mode, which was an inspiration for VimFx’s Caret mode.

### Caret mode commands

Caret mode uses [Firefox’s own Caret mode] under the hood. This means that you
can use the arrows keys, `<home>`, `<end>`, `<pageup>` and `<pagedown>`
(optionally holding ctrl) to move the caret as usual. Hold shift while moving
the caret to select text.

In addition to the above, VimFx provides a few commands inspired by Vim.

- `h`, `j`, `k`, `l`: Move the caret left, down, up or right, like the arrow
  keys.

- `b`, `w`: Move the caret one word backward or forward, like `<c-left>` and
  `<c-right>` but a bit “Vim-adjusted” (see the section on Vim below) in order
  to be more useful.

- `0` (or `^`), `$`: Move the caret to the start or end of the line.

The above commands (except the ones moving to the start or end of the line)
accept a _count._ For example, press `3w` to move three words forward.

Press `v` to start selecting text. After doing so, VimFx’s commands for moving
the caret select the text instead of just moving the caret. Press `v` again to
collapse the selection again. (Note that after pressing `v`, only VimFx’s
commands goes into “selection mode,” while Firefox’s work as usual, requiring
shift to be held to select text.)

`o` moves the caret to the “other end” of the selection. If the caret is at the
end of the selection, `o` will move it to the start (while keeping the selection
intact), and vice versa. This let’s you adjust the selection in both ends.

Finally, `y` is a possibly faster alternative to the good old `<c-c>`. Other
than copying the selection to the clipboard, it also exits Caret mode, saving
you yet a keystroke. (`<escape>` is unsurprisingly used to exit Caret mode
otherwise.)

[Firefox’s own Caret mode]: http://kb.mozillazine.org/Accessibility_features_of_Firefox#Allow_text_to_be_selected_with_the_keyboard

### Workflow tips

If you’re lucky, the text you want to copy is located within a single element
that contains no other text, such as the text of a link or an inline code
snippet. If so, using the `yv` command (which copies an entire element without
entering Caret mode) is the fastest.

If you want to copy _almost_ all text of an element, or a bit more than it, use
the `av` command (which selects an entire element). Then adjust the selection
using the various Caret mode commands. Remember that `o` lets you adjust both
ends of the selection.

In all other cases, use the `v` command to place the caret close to the text you
want to copy. Then move the caret in place using the various Caret
mode commands, hit `v` to start selecting, and move the again.

Use `y` to finish (or `<escape>` to abort). Alternatively, use the `<menu>` key
to open the context menu for the selection.

### For Vim users

As seen above, Caret mode is obviously inspired by Vim’s Visual mode. However,
keep in mind that the point of Caret mode is to **copy text using the keyboard,
not mimicing Vim’s visual mode.** I’ve found that selecting text for _copying_
is different than selecting code for _editing._ Keep that in mind.

Working with text selection in webpages using code is a terrible mess full of
hacks. New commands will only be added if they _really_ are worth it.

A note on VimFx’s `b` and `w`: They work like Vim’s `b` and `w` (but a “word” is
according to Firefox’s definition, not Vim’s), except when there is selected
text and the caret is at the end of the selection. Then `b` works like Vim’s
`ge` and `w` works like Vim’s `e`. The idea is to keep it simple and only
provide two commands that do what you want, rather than many just to mimic Vim.


## Ignore mode `<s-f1>`

Ignore mode is all about ignoring VimFx commands and sending the keys to the
page instead. Sometimes, though, you might want to run some VimFx command even
when in Ignore mode.

One way of doing that is to press `<s-escape>` to exit Ignore mode, run your
command and then enter Ignore mode again using `i`. However, it might be
inconvenient having to remember to re-enter Ignore mode, and sometimes that’s
not even possible, such as if you ran the `K` command to get to the next tab.

Another way is to press `<s-f1>` followed by the Normal mode command you wanted
to run. (`<s-f1>` is essentially the inverse of the `I` command, which passes
the next keypress on to the page. Internally they’re called “quote” and
“unquote.”) This is handy if you’d like to switch away from a [blacklisted]
page: Just press for example `<s-f1>K`.

`<s-f1>` was chosen as the default shortcut because on a typical keyboard `<f1>`
is located just beside `<escape>`, which makes it very similar to `<s-escape>`,
which is used to exit Ignore mode. Both of those are uncommonly used by web
pages, so they shouldn’t be in the way. If you ever actually do need to send any
of those to the page, you can prefix them with `<s-f1>`, because if the key you
press after `<s-f1>` is not part of any Normal mode command, the key is sent to
the page. (Another way is for example `<s-f1>I<s-escape>`.)

[blacklisted]: options.md#blacklist


## Ex commands

Vim has something called “ex” commands. Want something similar in VimFx? True to
its spirit, VimFx embraces a standard Firefox feature for this purpose: The
[Developer Toolbar]. That link also includes instructions on how to extend it
with your own commands.

In the future VimFx might even ship with a few extra “ex” commands by default.
We’re open for suggestions!

[Developer Toolbar]: https://developer.mozilla.org/en-US/docs/Tools/GCLI
