<!--
This is part of the VimFx documentation.
Copyright Simon Lydell 2015.
See the file README.md for copying conditions.
-->

# Commands

Most of VimFx’s commands are straight-forward enough to not need any
documentation. For some commands, though, there is a bit more to know.

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
of the tab bar.

### `gJ`, `gK`

Moves the current tab _count_ tabs forward/backward.

If the count is greater than one they don’t wrap around when reaching the ends
of the tab bar.

### `x`

Closes the current tab and _count_ minus one of the following tabs.

### `X`

Restores the _count_ last closed tabs.

### `q`

Passes on the next _count_ keypresses to the page, without activating VimFx
commands.

### The `f` commands

Explained in the their own section below.

### `gi`

Explained in its own section below.


## `<force>` commands

By putting the special “key” `<force>` at the beginning of a shortcut the
shortcut will work exactly as it would without `<force>`, except that it will
also be available in text inputs.

VimFx enters a kind of “automatic insert mode” when you focus a text input,
allowing you to type text into it without triggering VimFx commands. The `esc`
command, however, is still available, allowing you to blur the text input by
pressing `<escape>`. The reason it is available is because the default shortcut
is `<force><escape>`.

Using `<force>` allows you to run other commands in text inputs as well. For
example, you could use `<force><a-j>` and `<force><a-k>` to be able to select
tab backward and forward regardless if you happen to be in a text input or not.


## Scrolling commands

Firefox lets you scroll with the arrow keys, page down, page up, home, end and
space by default. VimFx provides similar scrolling commands (and actually
overrides space), but they work a little bit differently.

They scroll _the currently focused element._ If the currently focused element
isn’t scrollable, or there are no (apparent) currently focused element, the
entire page is scrolled.

You can focus scrollable elements using the `vf` command.


## `gi`—Text Input mode

`gi` focuses the text input you last used, or the first one on the page. Note
that a [prevented autofocus] still counts as having focused and used a text
input. This allows you to have your cake and eat it too: You can enable
autofocus prevention, and type `gi` when you wish you hadn’t.

`gi` takes a count. It then selects the `counth` text input on the page. Note
that `gi` and `1gi` are different: The latter _always_ focuses the first input
of the page, regradless of which input you used last.

Typing `gi` also enters Text Input mode. That’s mostly an implementation detail.
What it means is that `<tab>` will only switch between text inputs on the page,
as opposed to between all focusable elements (such as links, buttons and
checkboxes) as it does otherwise.

[prevented autofocus]: options.md#prevent-autofocus


## The `f` commands

When invoking one of the `f` commands you enter Hints mode. In Hints mode,
markers with hints are shown for some elements. By typing the letters of a hint
something is done to that element, depending on the command.

Which elements get hints depends on the command as well:

- `f` and `af`: Anything clickable—links, buttons, form controls.
- `F` and `gf`: Anything that can be opened in a new tabs—links.
- `yf`: Anything that has something useful to copy—links (their URL) and text
  inputs (their text).
- `vf`: Anything focusable—links, buttons, form controls, scrollable elements,
  frames.

It might seem simpler to match the same set of elements for _all_ of the
commands. The reason that is not the case is because the fewer elements the
shorter the hints. (Also, what should happen if you tried to `F` a button?)

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

One more thing about hints: Some hint characters are easier to type than others.
The ones on the home row are of course the best. When customizing the [hint
chars] option you should put the best keys to the left and the worst ones to the
right. VimFx favors keys to the left, so that should give you the optimal hints.

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

The `vf` and `yf` commands do not accept counts.

[hint chars]: options.md#hint-chars
