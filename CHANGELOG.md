# Release Notes

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

0.4.1, 0.4.2 (12-14 Dec 2012)

- Small tweaks of the find feature.
- Bugfix for keyboard handling on non-english keyboard layouts

0.4.3 (27 Dec 2012)

- Toolbar button bugfix
- Added an option to disable individual commands via the help dialog

0.4.4 (30 Jan 2013)

- Thanks to @mozillazg and @mcomella for translation contributions.
- Added `gh` command that will navigate to the home page.
- Added `o` command to focus address bar.
- `p` and `P` will parse the contents of the clipboard. If the string in the clipboard appears to be a url then it will navigate to this url. Otherwise it will search for the string in the clipboard using currently selected search provider.
- Now hint markers for links will stay on top of all the markers for different kinds of elements.
- Esc will now also close the focused default search bar.
- Fixed bugs related to keyboard events handling, XUL documents, and some other issues.
- Bug fixed where not all the commands could be disabled via the Help dialog.

0.4.5 (12 Mar 2013)

- `:` to open Firefox Developer Toolbar, `Esc` to close it.
- Add Hungarian locale (@thenonameguy).
- Add Polish locale (@grn).
- Don't close pinned tabs when pressing x (@grn).
- Switched to Makefile for building the extension release (@carno).
- Mrakers CSS tweaks (@helmuthdu)

0.4.6 (27 Mar 2013)

- Reimplemented find mode: CJK support, performace boost
- `a/` or `a.` to highlight all matches of the search string on the page
- Hint markers will now reach into iframes
- Key handling is disabled when a popupmenu or panel are shown
- `yf` will now also focus links and copy values from text/textarea element
- `vf` will show hit markers to focus the underlying element

0.4.7 (12 Jun 2013)

- `embed` and `object` tags will now have their own hints
- Bug fixes related to custom hint chars (@LordJZ)
- Fixed `t` - now it will be nice to other extensions
- Updated Chineese translations (@mozillazg)
- Reenter Normal mode on page reloads to avoid getting stuck in Hints mode withou any hints
- Search will focus element that contains matching text
- Fixed hint markers for iframes
- Marker bug fixes (@LordJZ)
