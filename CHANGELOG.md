# Change Log

0.5.15 (Jan 21 2015)

- Improved: This version is now forwards-compatible with the upcoming version
  0.6.0. Downgrading from 0.6.0 to 0.5.14 or older might cause VimFx to crash,
  but downgrading from 0.6.0 to 0.5.15 is safe.
- Fixed: Non-hintchars key presses in hints mode are now suppressed. They used
  to be passed along to the browser, which could confusingly activate site
  commands.
- Fixed: The 'f' command now always opens links in the same tab. Links used to
  be able to force a new tab or window.
- Fixed: Pressing 'Esc' in the location bar now restores the URL, as is the
  default behaviour of Firefox. You may now also close Firefox dialogs using
  'Esc'.
- Improved: Updated the de locale. Thanks to Alexander Haeussler!
- Improved: Updated the pl locale. Thanks to morethanoneanimal!

0.5.14 (Aug 16 2014)

- Fixed: Locales should now work properly.
- Improved: Updated the zh-CN locale (@mozillazg).
- Improved: Updated the de locale (@Kambfhase).
- Added: Japanese locale (@pluser).
- Fixed: If you switched to another tab or window while an `<input>` element
  was focused and then switched back, the `<input>` element got blurred, while
  it should have stayed focused. This caused the auto-type feature of KeePassX
  to break.

0.5.13 (Aug 2 2014)

- Fixed: The vote button on StackExchange sites are now markable again.
- Improved: Detection of previous/next links. Should work better on gmail now.
- Fixed: It is now possible to use Enter/Return in keyboard shortcuts.
- Improved: The n/N commands (etc.) now work even if you didn’t open the finbar
  using the VimFx command (such as the default key binding ctrl+f, or by
  clicking a menu item).
- Improved: It is now possible to blur text inputs without sending Esc to the
  page, which could cause dialogs etc. to annoyingly close.
- Improved: Updated the el-GR locale (@sirodoht).
- Fixed: Autofocus prevention sometimes made text inputs impossible to focus
  until you reloaded the page.
- Improved: Autofocus prevention now works on more sites than before.
- Improved: Autofocus prevention now prevents _all_ automatic focusing (not
  just when the page loads). This makes devdocs.io much easier to use.
- Added: When viewing images directly and the image has been resized to fit the
  screen the image is now markable, allowing you to toggle zoom on it using the
  keyboard.
- Fixed: It is no longer possible to add conflicting shortcuts (such as adding
  'a' when 'af' and 'as' are already present).

0.5.12 (June 1 2014)

- Fixed: Autofocus preventiton got stuck sometimes, making it impossible to
  focus inputs.

0.5.11 (June 1 2014)

- Fixed: The focus search bar command was broken.
- Fixed: Autofocus prevention was broken.
- Fixed: The top bar on YouTube could not be accessed by VimFx.
- Fixed: You can no longer add blank hotkeys.
- Improved: Tab Groups are supported.
- Improved: Matching of previous/next links should be more reliable.
- Improved: A few minor things.

0.5.10 (May 7 2014)

- Fixed yet another bug related to the default pereferences

0.5.9 (May 4 2014)

- Fixed a bug with default preferences not being set
- Fixed gg and G to be faster

0.5.8 (Apr 18 2014)

AMO Preliminary Review bug fix (sorry for such long delay)

0.5.7 (Mar 3 2014)

- Bug fix

0.5.6 (Feb 26 2014)

- Updated some translations
- Updated pagination patterns and logic

0.5.5 (Jan 3 2014)

- Hotfix release to address a bug that has been introduced in 0.5.4

0.5.4 (Jan 3 2014)

- Fix for popup passthrough mode stucking
- Make toolbar button click depend on current mode
- Higher weight markers should not be overlapped
- Refactor find mode to use Firefox native search bar
- Bump minimum requred Firefox version to 25
- Added commands to go in the URL path
- Added commands to navigate previous and next links with customizable link patterns
- Use Firefox 24+ native console API
- Update zh-CN localization

0.5.3 (Oct 16 2013)

- Lots of refactoring
- Insert mode (`i` command)
- Follow multiple links with `af` command
- Hint marker rotation with `space` while in hints mode

0.5.1 (Aug 21 2013)

- Fixed regression with stylesheets
- Updated icon

0.5 (Aug 19 2013)

- Added command to focus search bar: `O`
- Added commands to stop loading current page and all pages: `s` and `as`
- Invisible elements will not get hint markers
- Compatibility with Firefox 25
- Simple shortcut customization with UI in Help dialog
- Use huffman coding algorithm for hint markers generation which results in shorter links
- Implemented Bloom filters to achieve shorter hints for those shortcuts that are used often
- Reimplemented scrolling - now works with pages wihere window is not scrollable
- Find disabled on non HTML documents
- Find string is now global for all windows.
- Fixed logic of locale discovery. Now we rely on general.useragent.locale Firefox preference for current locale

0.4.8 (12 Jun 2013)

- `embed` and `object` tags will now have their own hints
- Bug fixes related to custom hint chars (@LordJZ)
- Fixed `t` - now it will be nice to other extensions
- Updated Chineese translations (@mozillazg)
- Reenter Normal mode on page reloads to avoid getting stuck in Hints mode withou any hints
- Search will focus element that contains matching text
- Fixed hint markers for iframes
- Marker bug fixes (@LordJZ)

0.4.6 (27 Mar 2013)

- Reimplemented find mode: CJK support, performace boost
- `a/` or `a.` to highlight all matches of the search string on the page
- Hint markers will now reach into iframes
- Key handling is disabled when a popupmenu or panel are shown
- `yf` will now also focus links and copy values from text/textarea element
- `vf` will show hit markers to focus the underlying element

0.4.5 (12 Mar 2013)

- `:` to open Firefox Developer Toolbar, `Esc` to close it.
- Add Hungarian locale (@thenonameguy).
- Add Polish locale (@grn).
- Don't close pinned tabs when pressing x (@grn).
- Switched to Makefile for building the extension release (@carno).
- Mrakers CSS tweaks (@helmuthdu)

0.4.4 (30 Jan 2013)

- Thanks to @mozillazg and @mcomella for translation contributions.
- Added `gh` command that will navigate to the home page.
- Added `o` command to focus address bar.
- `p` and `P` will parse the contents of the clipboard. If the string in the clipboard appears to be a url then it will navigate to this url. Otherwise it will search for the string in the clipboard using currently selected search provider.
- Now hint markers for links will stay on top of all the markers for different kinds of elements.
- Esc will now also close the focused default search bar.
- Fixed bugs related to keyboard events handling, XUL documents, and some other issues.
- Bug fixed where not all the commands could be disabled via the Help dialog.

0.4.3 (27 Dec 2012)

- Toolbar button bugfix
- Added an option to disable individual commands via the help dialog

0.4.1, 0.4.2 (12-14 Dec 2012)

- Small tweaks of the find feature.
- Bugfix for keyboard handling on non-english keyboard layouts

0.4 (9 Dec 2012)

- Implemented find with `/` and `n/N`
- Added `ar` and `aR` commands to reload pages in all open tabs.
- Added a preference that enables bluring from any element that has input focus in the browser on Esc keydown (on by default)
- Fixed bug where markers and help dialog would blow up some of the pages.
- Marker hints are now sorted with respect to the underlying element area. Elements with larger area get shorter hints
- Added *mail.google.com* to the default black list
- Various bug fixed and improvements.

0.3.2, 0.3.2, 0.3.3 (20-21 Nov 2012)

- Hotfixes for the build script to include localization related files and folders

0.3 (19 Nov 2012)

- Fixed [Desktop](https://addons.mozilla.org/en-us/firefox/addon/desktop/) extension compatibility problem
- Removed c-b/c-f for now. c-f is a standard search hotkey. Will put c-f back when proper Vim-like search with / is implemented
- Scrolling with G will now reach the bottom of the page
- Implemented localization, currently there is only Russian localization. Community is welcome
  [to contribute your localizations](https://github.com/akhodakivskiy/VimFx/tree/master/extension/locale)!
- Implemented simple smooth scolling

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

0.1.1 (27 Oct 2012)

- Just to deal with AMO - no changes

0.1 (26 Oct 2012)

- Initial Release
