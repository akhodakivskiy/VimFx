# VimFx – Vim keyboard shortcuts for Firefox

<img src="icon-large.png" alt="" align="right">

[VimFx] is a [Mozilla Firefox] extension which adds Vim-style keyboard shortcuts
for browsing and navigation, significantly reducing the use of the mouse, and
allowing your hands to rest on the home row.

VimFx was inspired by [Vimperator] and designed after [Vimium] for [Google
Chrome], preserving the shortcuts and behavior. If you are used to Vimium then
it will be easy to get started with VimFx.

**Mailing list:** [vimfx@librelist.com] (just send an email to subscribe)

Read [CONTRIBUTING.md](CONTRIBUTING.md) before opening issues and pull requests.

VimFx is made by [these awesome people](PEOPLE.md).

[vimfx@librelist.com]: mailto:vimfx@librelist.com?subject=Subscribe
[VimFx]: https://addons.mozilla.org/firefox/addon/vimfx
[Mozilla Firefox]: https://www.mozilla.org/firefox
[Vimperator]: http://www.vimperator.org/vimperator
[Vimium]: http://vimium.github.io/
[Google Chrome]: https://www.google.com/chrome

## Why VimFx was created

> Even before Vimium there was Vimperator for Firefox. In my opinion the problem
> with Vimperator is that it has too many features and aggressively changes the
> default Firefox appearance and behavior. Vimium was developed for Google Chrome
> and it was exactly what I needed in terms of added functionality. That's why I
> decided to develop similar extension for Firefox.
>
> VimFx will be nice to your browser and to your habits. Promise.
>
> <footer>– <cite>Anton Khodakivskiy</cite>, VimFx’s original author.</footer>

## Key Features

- Concise shortcuts for most commonly performed actions.
- Follow links, focus text inputs and click buttons on the page using hint
  markers.
- Easily accessible help dialog for the keyboard shortcuts.
- Every keyboard shortcut is customizable.
- Prefers native Firefox features over re-implementing similar functionality.

## Shortcuts

This is a text representation of the keyboard shortcuts dialog within the
extension, which helps you remember the shortcuts, and lets you customize them.
Press <kbd>?</kbd> or use the toolbar button to open it.

### Dealing with URLs

    o            Focus the Address Bar
    O            Focus the Search Bar
    p            Paste and go
    P            Paste and go in a new tab
    yf           Copy link url to the clipboard
    vf           Focus element
    yy           Copy link or text input value
    r            Reload
    R            Reload (override cache)
    ar           Reload all tabs
    aR           Reload all tabs (override cache)
    s            Stop loading the page
    as           Stop loading all tabs

### Navigating the Page

    gg           Scroll to top
    G            Scroll to bottom
    j            Scroll down
    k            Scroll up
    h            Scroll left
    l            Scroll right
    d            Scroll half a page down
    u            Scroll half a page up
    <space>      Scroll full page down
    <s-space>    Scroll full page up

### Working with Tabs

    t            New tab
    T  S         New Tab with Search Dialog focused
    J  gT        Previous tab
    K  gt        Next tab
    gJ           Move tab left
    gK           Move tab right
    gh           Go to the Home Page
    gH  g0       Go to the first tab
    g^           Go to the first non-pinned tab
    gL  g$       Go to the last tab
    gp           Pin/Unpin tab
    yt           Duplicate tab
    gx$          Close tabs to the right
    gxa          Close other tabs
    x            Close tab
    X            Restore closed tab

### Browsing

    f            Follow link, focus text input or click button
    F            Follow link in a new tab
    af           Follow a link on the current page in a new tab
    [            Go to the next page
    ]            Go to the previous page
    gu           Go up one level in the URL
    gU           Go to root in the URL
    H            Go back in history
    L            Go forward in history

### Misc

    /            Enter Find mode
    a/           Enter Find mode highlighting all matches
    n            Find next
    N            Find previous
    i            Enter insert mode: Ignore all commands
    I            Pass next keypress through to the page
    ?            Show this dialog
    :            Open the Developer Toolbar
    <escape>     Blur/close active element

### Hints Mode

    <escape>     Return to normal mode
    <space>      Rotate overlapping markers forward
    <s-space>    Rotate overlapping markers backward
    <backspace>  Delete last typed hint character

### Insert Mode

    <s-escape>   Return to normal mode

### Find Mode

    <escape> <return> Close find bar
