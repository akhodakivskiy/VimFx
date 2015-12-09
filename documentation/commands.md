<!--
This is part of the VimFx documentation.
Copyright Simon Lydell 2015.
See the file README.md for copying conditions.
-->

# Commands

Most of VimFx’s commands are straight-forward enough to not need any
documentation. For some commands, though, there is a bit more to know.

In this document, many commands are referred to by their default shortcut. You
can of course [change those] if you like.

[change those]: shortcuts.md

## Counts

Some commands support _counts._ That means that you can type a number before a
command and it will change its behavior based on that number—the count. For
example, typing `12x` would close 12 tabs.

(As opposed to vim, you may only supply a count _before_ a command, not in the
middle of one. This is because VimFx’s commands are simple sequences, while
vim’s are operators and motions.)

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

### The `f` commands

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

You can focus scrollable elements using the `zf` command (or the `f` command).
Scrollable browser elements, such as in the dev tools, can be focused using the
`zF` command. The right border of hint markers for scrollable elements is styled
to remind of a scroll bar, making them easier to recognize among hints for
links.

Note that `zf` and `f` do _not_ add a hint marker for the _largest_ scrollable
element (such as the entire page). There’s no need to focus that element, since
it is scrolled by default if no other scrollable element is focused, as
explained above. (This prevents the largest scrollable element from likely
eating your best hint char on most pages; see [The `f` commands]).

[The `f` commands]: #the-f-commands-1

### Marks: `m` and `` ` ``

Other than traditional scrolling, VimFx has _marks._ Press `m` followed by a
letter to associate the current scroll position with that letter. For example,
press `ma` to save the position into mark _a._ Then you can return to that
position by pressing `` ` `` followed by the same letter, e.g. `` `a ``.

One mark is special: `` ` ``. Pressing ``` `` ``` takes you to the scroll
position before the last `gg`, `G`, `0`, `$`, `/`, `n`, `N` or `` ` ``. (You can
change this mark using the [`scroll.last_position_mark`] pref.)

[`scroll.last_position_mark`]: options.md#scroll.last_position_mark

#### Minor notes

Unlike Vim, you may press _any_ key after `m`, and the scroll position will be
associated with that key (Vim allows only a–z, roughly).

Unlike Vim and Vimium, VimFx has no global marks. The reason is that they would
be a lot more complicated to implement and do not seem useful enough to warrant
that effort.

As mentioned above, `m` stores the _current scroll position._ Specifically, that
means the scroll position of the element that would be scrolled if the active
element isn't scrollable; see [Scrolling commands] above.

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


## The `f` commands

When invoking one of the `f` commands you enter Hints mode. In Hints mode,
markers with hints are shown for some elements. By typing the letters of a hint
something is done to that element, depending on the command.

Another way to find links on the page is to use `g/`. It’s like the regular find
command (`/`), except that it searches links only.

Which elements get hints depends on the command as well:

- `f` and `af`: Anything clickable—links, buttons, form controls.
- `F`, `gf` and `gF`: Anything that can be opened in a new tab or window—links.
- `yf`: Anything that has something useful to copy—links (their URL) and text
  inputs (their text).
- `zf`: Anything focusable—links, buttons, form controls, scrollable elements,
  frames.
- `zF`: Browser elements, such as toolbar buttons.

It might seem simpler to match the same set of elements for _all_ of the
commands. The reason that is not the case is because the fewer elements the
shorter the hints. (Also, what should happen if you tried to `F` a button?)

(You can also customize [which elements do and don’t get hints][hint-matcher].)

Another way to make hints shorter is to assign the same hint to all links with
the same URL. So don’t get surprised if you see the same hint repeated several
times.

VimFx also tries to give you shorter hints for elements that you are more likely
to click. This is done by the surprisingly simple rule: The larger the element,
the shorter the hint.

There are standardized elements which are always clickable—_semantically_
clickable elements. Unfortunately, many sites use unclickable elements and then
make them clickable using JavaScript—<em>un</em>semantically clickable elements.
Such elements are difficult to find. VimFx has a few techniques for doing so,
which works many times but not always, but unfortunately they sometimes produce
false positives. Many times those false positives are pretty large elements,
which according to the last paragraph would give them really short hints, making
other more important elements suffer by getting longer ones. Therefore VimFx
favors semantic elements over unsemantic ones and takes that into account when
deciding the hint length for elements.

Some hint characters are easier to type than others. The ones on the home row
are of course the best. When customizing the [hint chars] option you should put
the best keys to the left and the worst ones to the right. VimFx favors keys to
the left, so that should give you the optimal hints.

Hints are added on top of the corresponding element. If they obscure the display
too much you can hold shift to make them transparent. (See [Styling] if you’d
like to change that.) The hints can also sometimes cover each other. Press
`<space>` and `<s-space>` to switch which one should be on top.

When giving a count to an `f` command, all markers will be re-shown after you’ve
typed the hint characters of one of them, _count_ minus one times. All but the
last time, the marker’s link will be opened in a new background tab. The last
time the command opens links as normal (in the current tab (`f`) or in a new
background (`F`) or foreground tab (`gf`)).

Note that the `f` command adds markers not only to links, but to buttons and
form controls as well. What happens the _count_ minus one times then? Buttons,
checkboxes and the like are simply clicked, allowing you to quickly check many
checkboxes in one go, for example. Text inputs cancel the command.

`af` works as if you’d supplied an infinite count to `f`. (In fact, the `af`
command is implemented by running the same function as for the `f` command,
passing `Infinity` as the `count` argument!) Therefore the `af` command does not
accept a count itself.

The `gF`, `zf`, `yf` and `zF` commands do not accept counts.

Press `<enter>` to increase the count by one. This is useful when you’ve already
entered Hints mode but realize that you want to interact with yet a marker. This
can be faster than going into Hints mode once more.

If you’ve pressed `f` but realize that you’d rather open a link in a new tab you
can hold ctrl while typing the last hint character. This is similar to how you
can press `<c-enter>` on a focused link to open it in a new tab (while just
`<enter>` would have opened it in the same tab). Hold alt to open in a new
foreground tab. In other words, holding ctrl works as if you’d pressed `F` from
the beginning, and holding alt works as if you’d pressed `gf`.

For the `F` and `gf` commands, holding ctrl makes them open links in the same
tab instead, as if you’d used the `f` command. Holding alt toggles whether to
open tabs in the background or foreground—it makes `F` work like `gf`, and `gf`
like `F`.

(Also see the advanced prefs [hints\_toggle\_in\_tab] and
[hints\_toggle\_in\_background].)

[hint-matcher]: api.md#vimfxhintmatcher
[hint chars]: options.md#hint-chars
[Styling]: styling.md
[hints\_toggle\_in\_tab]: options.md#hints_toggle_in_tab
[hints\_toggle\_in\_background]: options.md#hints_toggle_in_background


## Ignore mode `<s-f1>`

Ignore mode is all about ignoring VimFx commands and sending the keys to the
page instead. Sometimes, though, you might want to run some VimFx command even
when in Insert mode.

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

vim has something called “ex” commands. Want something similar in VimFx? True to
its spirit, VimFx embraces a standard Firefox feature for this purpose: The
[Developer Toolbar]. That link also includes instructions on how to extend it
with your own commands.

In the future VimFx might even ship with a few extra “ex” commands by default.
We’re open for suggestions!

[Developer Toolbar]: https://developer.mozilla.org/en-US/docs/Tools/GCLI
