# VimFx - Vim keyboard shortcuts for Firefox

*Extension AMO page*: https://addons.mozilla.org/en-US/firefox/addon/vimfx/

*Contribute your localization! See `locale` folder*

[VimFx](https://addons.mozilla.org/en-US/firefox/addon/vimfx/) 
is a [Mozilla Firefox](https://www.mozilla.org/en-US/firefox/fx/#desktop) 
extension which introduces Vim-style keyboard shortcuts for browsing and navigation, 
significantly reducing the use of mouse, and allowing your hands to rest on the home row.

VimFx was inspired by [Vimperator](http://www.vimperator.org/) 
and designed after [Vimium](http://vimium.github.com/) for 
[Google Chrome](https://www.google.com/intl/en/chrome/browser/) preserving the shortcuts and behavior.
If your are used to Vimium then it will be easy to get started with VimFx.

## Why VimFx was created

Even before Vimium there was Vimperator for Firefox.  In my opinion the problem 
with Vimperator is that it has too many features and aggressively changes 
the default Firefox appearance and behavior. Vimium was developed for Google Chrome
and it was exactly what I needed in terms of added functionality. That's why I decided 
to develop similar extension for Firefox.

VimFx will be nice to your browser and to your habits. Promise.

## Credits

  

## Key Features

- Concise shortcuts for most commonly performed actions
- Follow and access controls on the page using hint markers
- Easy access to the Help page which describes all available shortcuts (press ?)

## Shortcuts

Might not be up to date. Please refer to the Help dialog withing the extension 
for the most relevant list.

Global shortcut to enable/disable VimFx: `Shift-Alt-v`

### URLs

    p       Navigate to the address in the clipboard
    P       Open new tab and navigate to the address in the clipboard
    yf      Copy link url to the clipboard
    yy      Copy current page link to the clipboard
    r       Reload current page
    R       Reload current page and all the assets (js, css, etc.)
    ar      Reload pages in all tabs
    aR      Reload pages in all tabs including assets (js, css, img)

### Navigating

    gg      Scroll to the Top of the page
    G       Scroll to the Bottom of the page
    j c-e   Scroll Down
    k c-y   Scroll Up
    h       Scroll Left
    l       Scroll Right
    d       Scroll half a Page Down
    u       Scroll half a Page Up
    c-f     Scroll full Page Down
    c-b     Scroll full Page Up

### Tabs

    t       Open New Blank tab
    J gT    Go to the Previous tab
    K gt    Go to the Next tab
    c-J     Move current tab to the Left
    c-K     Move current tab to the Right
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

    /       Enter Find mode
    n       Go ot the next Find match
    N       Go ot the previous Find match
    ?       Show Help Dialog
    Esc     Close this dialog and cancel hint markers

## Release Notes

0.1 (26 Oct 2012)

- Initial Release

0.1.1 (27 Oct 2012)

- Just to deal with AMO - no changes

0.2 (5 Nov 2012)

- document.designMode='on' is now honored. Will also provide hint markers for iframes on the page.
- Bug fixed where it would completely reset the toolbar while installing the toolbar button.
- Bug fixed where it's not possible to change the text in the blaclisting textbox
- Changed u/d to scroll half a page, added c-f/c-b to scroll full page
- Added tab movement commands: c-J and c-K.
- Invisible markers bug fixed.
- Global hotkey to disable the commands (equal to the toolbar button click): Alt-Shift V
- ^u and ^d are removed from the command list. ^u is commonly used to show the page source code
- Opening new tab with now focuses the Address Bar
- Other small bugs nailed down.

0.3 (19 Nov 2012)

- Fixed [Desktop](https://addons.mozilla.org/en-us/firefox/addon/desktop/) extension compatibility problem
- Removed c-b/c-f for now. c-f is a standard search hotkey. Will put c-f back when proper Vim-like search with / is implemented
- Scrolling with G will now reach the bottom of the page
- Implemented localization, currently there is only Russian localization. Community is welcome
  [to contribute your localizations](https://github.com/akhodakivskiy/VimFx/tree/master/extension/locale)! 
- Implemented simple smooth scolling

0.3.2, 0.3.2, 0.3.3 (20-21 Nov 2012)

- Hotfixes for the build script to include localization related files and folders

0.4 (9 Dec 2012)

- Implemented find with `/` and `n/N`
- Added `ar` and `aR` commands to reload pages in all open tabs.
- Added a preference that enables bluring from any element that has input focus in the browser on Esc keydown (on by default)
- Fixed bug where markers and help dialog would blow up some of the pages.
- Marker hints are now sorted with respect to the underlying element area. Elements with larger area get shorter hints
- Added *mail.google.com* to the default black list
- Various bug fixed and improvements.

0.4.1 (13 Dec 2012)

- Small tweaks of the find feature.
- Bugfix for keyboard handling on non-english keyboard layouts
