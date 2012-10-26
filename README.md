# VimFx - Vim keyboard shortcuts for Firefox

VimFx is a [Mozilla Firefox](https://www.mozilla.org/en-US/firefox/fx/#desktop) 
extension which introduces Vim-style keyboard shortcuts for browsing and navigation, 
significantly reducing the use of mouse, and allowing your hands to rest on the home row.

VimFx was designed after [Vimium](http://vimium.github.com/) for 
[Google Chrome](https://www.google.com/intl/en/chrome/browser/) preserving the shortcuts and behavior.
If your are used to Vimium then it will be easy to get started with VimFx.

## Why VimFx was created

Even before Vimium there was [Vimperator](http://www.vimperator.org/) for Firefox. 
The problem with Vimperator is that it has too many features and aggressively
change the default Firefox appearance and behavior. Vimium was developed for Google Chrome
and it was exactly what I needed in terms of added functionality. That's why I decided 
to develop similar extension for Firefox.

VimFx will be nice to your browser and to your habits.  Promise.

## Key Features

- Concise shortcuts for most commonly performed actions
- Follow and access controls on the page using hint markers
- Easy access to the Help page which describes all available shortcuts (press ?)

## Shortcuts

Might not be up to date. Please refer to the Help dialog withing the extension 
for the most relevant list.

### URLs

    p       Navigate to the address in the clipboard
    P       Open new tab and navigate to the address in the clipboard
    yf      Copy link url to the clipboard
    yy      Copy current page link to the clipboard
    r       Reload current page
    R       Reload current page and all the assets (js, css, etc.)

### Navigating

    gg      Scroll to the Top of the page
    G       Scroll to the Bottom of the page
    j c-e   Scroll Left
    k c-y   Scroll Right
    h       Scroll Down
    l       Scroll Up
    d c-d   Scroll a Page Down
    u c-u   Scroll a Page Up

### Tabs

    t       Open New Blank tab
    J gT    Go to the Previous tab
    K gt    Go to the Next tab
    gH g0   Go to the First tab
    gL g$   Go to the Last tab
    x       Close current tab
    X       Restore last closed tab

### Browsing

    f       Follow a link on the current page
    F       Follow a link on the current page in a new tab
    H       Go Back in history
    L       Go Forward in history

### Misc

    ?       Show Help Dialog
    Esc     Close this dialog and cancel hint markers

## Release Notes

0.1 (26 Oct 2012)

- Initial Release
