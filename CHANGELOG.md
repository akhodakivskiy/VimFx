### 0.10.0 (2015-12-09)

- Added: The `zF` command, which lets you click browser elements.
- Improved: The scrolling commands can now scroll browser elements (in other
  words, not only web page content), by first selecting the scollable element
  using `zF`.
- Added: The `gr` command, which toggles [Reader View].
- Added: The `gX` command, which opens the Recently Closed Tabs menu at the
  middle of the screen.
- Added: The keys you’ve typed so far of a command, as well the count, are now
  shown in a [notification]. (You may disable this using the
  [`notify_entered_keys`] pref.)
- Improved: When commands don’t do anything, they show a [notification] instead,
  letting you know that you actually pressed the right keys. For example, if you
  press `f` but there are no markable elements visible, a notification is shown
  telling you so, instead of silently doing nothing.
- Improved: `<space>` now scrolls _about a line less_ than a full page, just
  like Firefox does by default. `d` scroll about _half_ a line less (by
  default), so that pressing `d` twice works like pressing `<space>` once. (See
  the [`scroll.full_page_adjustment` and `scroll.half_page_adjustment`] prefs
  for more information.)
- Improved: `gi` now only selects all text in its text input if you haven’t
  focused a text input yet (allowing you to easily replace pre-filled text),
  instead of _always_ doing so. Otherwise, it now puts the cursor where you left
  off typing the last time.
- Fixed: The `f` commands now put the cursor where you left off typing the last
  time when focusing a text input. Previously, they accidentally selected all
  text in the text input (use `zf` for that behavior).
- Fixed: Yet a scrolling fix. VimFx’s scrolling commands should now “just work”
  on even more sites.
- Fixed: AltGr should now work out of the box on Windows. (See the
  [`ignore_ctrl_alt`] pref for more information.)
- Removed: The el-GR, hu and pl locales were sadly too out of date to be useful,
  and nobody has shown interest in updating them, so they were removed.
- Updated locales: id, de and zh-CN. Thanks to Yoppy Halilintar, @just-barcodes
  and @mozillazg!
- Fixed: Several tiny bugs.

[Reader View]: https://support.mozilla.org/kb/firefox-reader-view-clutter-free-web-pages
[notification]: https://github.com/akhodakivskiy/VimFx/blob/ba9d4675e19ce315e6855b64400aae092e727975/documentation/notifications.md
[`notify_entered_keys`]: https://github.com/akhodakivskiy/VimFx/blob/ba9d4675e19ce315e6855b64400aae092e727975/documentation/options.md#notify_entered_keys
[`scroll.full_page_adjustment` and `scroll.half_page_adjustment`]: https://github.com/akhodakivskiy/VimFx/blob/ba9d4675e19ce315e6855b64400aae092e727975/documentation/options.md#scrollfull_page_adjustment-and-scrollhalf_page_adjustment
[`ignore_ctrl_alt`]: https://github.com/akhodakivskiy/VimFx/blob/ba9d4675e19ce315e6855b64400aae092e727975/documentation/options.md#ignore_ctrl_alt

### 0.9.0 (2015-12-02)

- Fixed: Links with the `onclick` attribute can now be opened in new tabs again.
  (Regression since 0.8.0.)
- Fixed: The text size in VimFx’s Keyboard Shortcuts dialog is now correctly
  resized.
- Added: The `gH` command. It opens the back/forward button context menu in the
  middle of the window, allowing you to choose a history entry with the arrow
  keys and `<enter>`.

### 0.8.0 (2015-12-01)

- Fixed: VimFx now works properly in tabs moved to other windows.
- Fixed: An unreliable check for multi-process mode has been eliminated, fixing
  various problems for some users.
- Fixed: VimFx’s toolbar button now changes color correctly when switching
  between blacklisted and non-blacklisted tabs.
- Fixed: Dead keys now work out of the box on Windows.
- Improved: Links with the `onclick` attribute (abused as buttons) can no longer
  get the same hint as another link.
- Added: The Keyboard Shortcuts dialog (shown by pressing `?`) is now
  searchable.
- Added: The `g/` command. It’s like `/` but searches links only.

- Added: [Marks].

  - Use `ma` to mark the current scroll position and `` `a `` to return to it.
    (You may substitute `a` with any key press.)
  - Use ``` `` ``` to return to the position before the last `gg`, `G`, `0`,
    `$`, `/`, `n`, `N` or `` ` ``. (You can change this mark using the
    [`last_scroll_position_mark`] pref.)

- Added: Window commands.

  - `w`: Open new window.
  - `W`: Open new private window.
  - `gw`: Move tab to new window.
  - `gF`: Follow link in new window.

[Marks]: https://github.com/akhodakivskiy/VimFx/blob/47fc699ce8217ee90af4d12e81f102f2bea09d61/documentation/commands.md#marks-m-and-
[`last_scroll_position_mark`]: https://github.com/akhodakivskiy/VimFx/blob/47fc699ce8217ee90af4d12e81f102f2bea09d61/documentation/options.md#last_scroll_position_mark

### 0.7.3 (2015-11-22)

- Fixed: Scrolling now works correctly in pages in quirks mode (lacking a
  doctype), such as Hackernews.
- Improved: The largest scrollable element is now detected better in frames.
- Fixed: Hints mode now exits correctly when focusing a text input using `af`,
  or `f` with a count.

### 0.7.2 (2015-11-21)

- Fixed: The blinking text caret now always appears correctly when focusing text
  inputs.

### 0.7.1 (2015-11-21)

- Fixed: The scrolling commands should now “just work” when using non-default
  zoom or DPI settings, most notably on Google Groups.

### 0.7.0 (2015-11-19)

- Changed: Instead of using system notifications, which turned out to be a bit
  too intrusive, [notifications] are now similar to the “URL popup” (shown when
  hovering or focusing links) but are placed on the opposite side,.
- Changed: The “Focus next element” and “Focus previous element” commands have
  been removed. The reason they existed was to let `<tab>` and `<s-tab>` only
  cycle between text inputs (as opposed to _all_ focusable elements) after
  you’ve pressed `gi`. Now, `<tab>` and `<s-tab>` are handled specially instead,
  and _only_ after pressing `gi`. The reason for this change is that the now
  removed commands were too intrusive, breaking user habits. One of VimFx’s main
  goal is _not_ to do that. (You can turn the special handling of `<tab>` and
  `<s-tab>` off using the the new [`focus_previous_key` and `focus_next_key`]
  prefs.)
- Fixed: The scrolling commands should now “just work” in a lot more situations,
  most notably on Gmail and Google Groups. More scrollable elements are also
  recognized by the `f` and `zf` commands.
- Improved: The right border of hint markers for scrollable elements is now
  styled to remind of a scroll bar, making them easier to recognize among hints
  for links.
- Improved/Changed: `J` and `gJ` now allow a count on the first tab.
  Consequently, `K` and `gK` now allow a count on the _last_ tab.
- Changed: `gJ` and `gK` can no longer be used to pin or unpin tabs. They now
  only wrap around tabs of the same pinned state. Use `gp` to toggle between
  pinned and non-pinned.
- Fixed: Many elements that got a hint before VimFx 0.6.0 now do again.
- Improved: Comment fields on Facebook can now be focused using `f` and blurred
  using `<escape>`.
- Improved: VimFx’s toolbar button is no greyed out when you focus a text input.
  This is to show that your key presses will be passed into the text input
  rather than activating VimFx commands.
- Added: [`g0`, `g^` and `g$` now accept counts][tab-index-counts], allowing you
  to go to tab number _count._
- Improved: `gi` now finds text inputs inside frames.
- Fixed: “gi mode” is now exited properly when blurring a text input.
- Fixed: `<select>` elements are no longer considered to be text inputs when
  using `<tab>` and `<s-tab>` in “gi mode.”
- Fixed: Using `<force>` or `<late>` in a shortcut no longer applies to _every_
  shortcut for the command, but only that shortcut.
- Fixed: The order of the Previous/Next page patterns is now respected. This
  caused the wrong link to be picked by the `[` and `]` commands on some pages.

[`focus_previous_key` and `focus_next_key`]: https://github.com/akhodakivskiy/VimFx/blob/d70b5bb14be89d9ce52138b0e9abdef1b31ad337/documentation/options.md#focus_previous_key-and-focus_next_key
[notifications]: https://github.com/akhodakivskiy/VimFx/blob/d70b5bb14be89d9ce52138b0e9abdef1b31ad337/documentation/notifications.md
[tab-index-counts]: https://github.com/akhodakivskiy/VimFx/blob/d70b5bb14be89d9ce52138b0e9abdef1b31ad337/documentation/commands.md#g0-g-g

### 0.6.2 (2015-11-11)

- Improved: If the entire page isn’t scrollable, the largest scrollable element
  is scrolled instead.
- Fixed: VimFx’s keyboard shortcuts now works on slowly loading pages.
- Fixed: Numbers may now be used as shortcut keys (overriding counts).
- Fixed: The toolbar button’s icon is now correctly sized in high DPI.
- Fixed: Hint markers are now correctly positioned when zooming using the “Zoom
  text only” option.
- Fixed: The `P` command now works with the InstantFox add-on.

### 0.6.1 (2015-11-10)

- Fixed: If you customized the “esc” command before VimFx 0.6.0 it should now
  work as expected.
- Fixed: `<tab>` now works as expected in the address bar and in the dev tools.
- Fixed: Light-weight themes can no longer make VimFx’s Keyboard Shortcuts help
  dialog and hint markers unreadable.
- Added: The [notifications\_enabled] option.

[notifications\_enabled]: https://github.com/akhodakivskiy/VimFx/blob/56c4b7c514ea8b58d2cdcecf3d2654648c48ca31/documentation/options.md#notifications_enabled

### 0.6.0 (2015-11-09)

##### Most important (breaking) changes

- VimFx now works properly with **any keyboard layout.** Users of **multiple
  layouts** should enable the **[ignore keyboard layout] option.** #249 #259

- Features related to disabling VimFx, and to the [toolbar button]:

  - **Insert Mode** has been renamed to **_Ignore_ mode.**
  - **[Blacklisted][blacklist] sites** now **enter Ignore mode automatically,**
    instead of being specially handled.
  - The feature to click the toolbar button (or press `<a-V>`) to **disable
    VimFx** has been **removed.** Use **Ignore mode** (`i`) and the
    **[blacklist] instead.**
  - The **toolbar button** is now **red in Ignore mode** (which also means that
    it is red on blacklisted sites) and green otherwise (never grey anymore).
  - The toolbar button no longer offers to (un-)blacklist the current domain.
    (Head into VimFx’s settings page in the Add-ons Manager and add
    `*currentdomain.com*` to the [blacklist] option yourself instead.)

  (See [commit 3552282] for more information.)

- **Some default shortcuts have changed,** mostly because they conflicted with
  standard Firefox shortcuts: #308

  - `<c-J>` → `gJ`

  - `<c-K>` → `gK`

  - `g^` and `gH` → `g0`

    `g^` now selects the first _non pinned_ tab instead, while `g0`
    selects the first tab regardless of whether it is pinned or not. #317

  - `<c-e>` (alias for `j`) and `<c-y>` (alias for `k`) have been removed.

  - `<c-f>` → `<space>` and `<c-b>` → `<s-space>`

  - `vf` → `zf`

    This frees up `v` for future shortcuts (instead making `z` a
    “namespace” key, just like in Vim).

  - To **exit Ignore mode:** `<escape>` → `<s-escape>`. This is because Ignore
    mode has replaced the disable feature, as well as the special blacklist
    state (see above). Sites are likely to use `<escape>` but not `<s-escape>`.
    (In a way, this new role of Ignore mode also means that the old (many times
    broken) shortcut to disable VimFx (`<a-V>`) has been replaced by `i`.) #64
    \#375 #432

- VimFx’s Keyboard Shortcuts help dialog is now help only, and more accessible.
  To **customize keyboard shortcuts,** go to VimFx’s settings page **in the
  Add-ons Manager,** just like you would to customize other settings. Also,
  **commas** between every key are **no longer needed:** Type `gJ` instead of
  `g,J`.

- For performance reasons, **Hint markers** are now placed vertically **centered
  instead of at the top** of the element. Don’t be surprised if you see the same
  hint repeated several times**—links that go to the same place now get the same
  hint.** The “Smart hints” option has been removed—hints are _always_ smart
  now, and a lot smarter than before. Finally, hints now also work in the new
  tab page, the Add-ons Manager and the preferences page. If you want to, you
  can read more about [the `f` commands]. \#51 #60 #176 #320 #325 #468 #471 #475

- The **`F`** command now _always_ opens tabs in new **background** tabs, while
  **`gf`** has been added to open tabs in new **foreground** tabs. #227 #464

- **Autofocus prevention** is now **off by default.** One of VimFx’s core
  philosophies is to be nice to your browser habits. Some find autofocus
  prevention too big a change. Turn it on again if you like it! By the way,
  autofocus prevention now works much more reliably and should not cause issues
  with other extensions. #497 #541

- The **“Scroll step”** option has been **removed**. The scrolling commands that
  used it now **work like the arrow keys instead,** and are customized just like
  them. See [scrolling prefs] for more information.

- Speaking of scrolling, **which elements scrolls** when you use VimFx’s
  scrolling commands **has changed.** See [scrolling commands] for more
  information.

##### New features

- New commands:

  - `gp` pins or unpins the current tab. (Also see `g^` and `g0` mentioned
    above.) #121
  - `yt` duplicates the current tab. #121
  - `0` and `^` scroll to the far left, and `$` scrolls to the far right.
  - [`gi`] has finally been implemented. #47
  - [Ignore mode `<s-f1>`] let you run a Normal mode command without exiting
    Ignore mode.

- In Hints mode you can now hold ctrl and alt to change behavior of the matched
  marker. Hold shift to temporarily make the hints see-through. See [the `f`
  commands] for more information. #220 #421 #484

- Some commands now accept [counts]. #374

- It is now possible to create shortcuts that work inside text inputs. See the
  [`<force>`] key for more information. #258

- It is now possible to create shortcuts that the page can override. See the
  [`<late>`] key for more information.

- A number of [advanced options] have been added. Rather than listing everything
  regarding them here, follow that link if you’re interested. #452 #489

- You may now, if you want to, configure VimFx through a [config file], using
  the new [public API]. Customizing VimFx through a config file also gives extra
  abilities, such as [site-specific options][option-overrides] and [disabling
  certain commands on certain sites][key-overrides]. It also allows to add
  [custom commands] \(and other extensions to extend VimFx). #158 #235 #255 #261
  \#300 #408 #445 #490 #515

- It is now easier to customize VimFx through custom [styling]. An example is
  changing the way hint markers look. #220 #233 #424 #432 #465

- VimFx now has [documentation] and a [wiki].

- A few new locales were added:

  - fr. Thanks to Mickaël RAYBAUD-ROIG (@m-r-r)!
  - pt-BR. Thanks to Átila Camurça Alves (@atilacamurca)!
  - sv-SE. Thanks to Andreas Lindhé (@lindhe)!

##### Improvements

- VimFx is now multi-process/Electrolysis/e10s compatible! This means that you
  can run VimFx on a version of Firefox with multi-process enabled without
  issues, and that we’re future proof for the day when Firefox becomes
  multi-process by default. Best of all, it also made VimFx more reliable in
  non-multi-process (“regular”) Firefox. #378

- The `[` and `]` commands are now smarter, recognizing more links to the
  previous/next page correctly. You may read more about [previous/next page
  patterns]. #396

- The `n` and `N` commands now notify you when they wrap around the page, or the
  phrase you searched for could not be found. #398

- _All_ shortcuts in _all modes_ can now be customized. For example, this allows
  you to disable VimFx’s Vim-style `<enter>` behavior in the find bar. #222 #390
  \#421

- The `p` and `P` commands are now smarter regarding whether to treat the
  clipboard contents as a URL or a search, by working exactly like pasting in
  the address bar. They also now read the selection clipboard, if available.
  \#353 #382

- VimFx’s toolbar button is now properly implemented. #303 #349 #383

- Most locales were updated. Thanks to our awesome [translators]!

##### Minor bug fixes

- VimFx now works correctly in tabs dragged to other windows. #57
- The `p` command is no longer broken. #494
- Non-ASCII shortcut keys now work properly. #433
- The Keyboard Shortcuts help dialog can no longer be covered by page elements.
  \#477
- Hint markers can no longer be covered by page elements.
- VimFx no longer causes scripts on icloud.com to get stuck in an infinite loop.
  \#389

[advanced options]: https://github.com/akhodakivskiy/VimFx/blob/c790b0fc1127c66bb7b33ccbaf4c0e8090e5530b/documentation/options.md#advanced-options
[blacklist]: https://github.com/akhodakivskiy/VimFx/blob/c790b0fc1127c66bb7b33ccbaf4c0e8090e5530b/documentation/options.md#blacklist
[ignore keyboard layout]: https://github.com/akhodakivskiy/VimFx/blob/c790b0fc1127c66bb7b33ccbaf4c0e8090e5530b/documentation/options.md#ignore-keyboard-layout
[previous/next page patterns]: https://github.com/akhodakivskiy/VimFx/blob/c790b0fc1127c66bb7b33ccbaf4c0e8090e5530b/documentation/options.md#previousnext-page-patterns
[scrolling prefs]: https://github.com/akhodakivskiy/VimFx/blob/c790b0fc1127c66bb7b33ccbaf4c0e8090e5530b/documentation/options.md#scrolling-prefs
[counts]: https://github.com/akhodakivskiy/VimFx/blob/c790b0fc1127c66bb7b33ccbaf4c0e8090e5530b/documentation/commands.md#counts
[`gi`]: https://github.com/akhodakivskiy/VimFx/blob/c790b0fc1127c66bb7b33ccbaf4c0e8090e5530b/documentation/commands.md#gi-1
[Ignore mode `<s-f1>`]: https://github.com/akhodakivskiy/VimFx/blob/c790b0fc1127c66bb7b33ccbaf4c0e8090e5530b/documentation/commands.md#ignore-mode-s-f1
[scrolling commands]: https://github.com/akhodakivskiy/VimFx/blob/c790b0fc1127c66bb7b33ccbaf4c0e8090e5530b/documentation/commands.md#scrolling-commands-1
[the `f` commands]: https://github.com/akhodakivskiy/VimFx/blob/c790b0fc1127c66bb7b33ccbaf4c0e8090e5530b/documentation/commands.md#the-f-commands-1
[`<force>`]: https://github.com/akhodakivskiy/VimFx/blob/c790b0fc1127c66bb7b33ccbaf4c0e8090e5530b/documentation/shortcuts.md#force
[`<late>`]: https://github.com/akhodakivskiy/VimFx/blob/c790b0fc1127c66bb7b33ccbaf4c0e8090e5530b/documentation/shortcuts.md#late
[config file]: https://github.com/akhodakivskiy/VimFx/blob/c790b0fc1127c66bb7b33ccbaf4c0e8090e5530b/documentation/config-file.md
[public api]: https://github.com/akhodakivskiy/VimFx/blob/c790b0fc1127c66bb7b33ccbaf4c0e8090e5530b/documentation/api.md
[option-overrides]: https://github.com/akhodakivskiy/VimFx/blob/c790b0fc1127c66bb7b33ccbaf4c0e8090e5530b/documentation/api.md#vimfxaddoptionoverridesrules
[key-overrides]: https://github.com/akhodakivskiy/VimFx/blob/c790b0fc1127c66bb7b33ccbaf4c0e8090e5530b/documentation/api.md#vimfxaddkeyoverridesrules
[styling]: https://github.com/akhodakivskiy/VimFx/blob/c790b0fc1127c66bb7b33ccbaf4c0e8090e5530b/documentation/styling.md
[toolbar button]: https://github.com/akhodakivskiy/VimFx/blob/c790b0fc1127c66bb7b33ccbaf4c0e8090e5530b/documentation/styling.md
[translators]: https://github.com/akhodakivskiy/VimFx/blob/c790b0fc1127c66bb7b33ccbaf4c0e8090e5530b/PEOPLE.md#translators
[documentation]: https://github.com/akhodakivskiy/VimFx/blob/c790b0fc1127c66bb7b33ccbaf4c0e8090e5530b/documentation/
[wiki]: https://github.com/akhodakivskiy/VimFx/wiki/
[custom commands]: https://github.com/akhodakivskiy/VimFx/wiki/Custom-Commands
[commit 3552282]: https://github.com/akhodakivskiy/VimFx/commit/355228217d7e7a61f5e1edbb9efbfb0f3e4ef81c

### 0.5.17 (2015-01-23)

- Fixed: The hints generation no longer crashes on some pages (regression since
  version 0.5.15).

### 0.5.16 (2015-01-22)

- Fixed: The toolbar button no longer throws errors. (This fix should have been
  in 0.5.15 but was forgotten. Luckily an AMO reviewer found it.)

### 0.5.15 (2015-01-21)

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

### 0.5.14 (2014-08-16)

- Fixed: Locales should now work properly.
- Improved: Updated the zh-CN locale (@mozillazg).
- Improved: Updated the de locale (@Kambfhase).
- Added: Japanese locale (@pluser).
- Fixed: If you switched to another tab or window while an `<input>` element
  was focused and then switched back, the `<input>` element got blurred, while
  it should have stayed focused. This caused the auto-type feature of KeePassX
  to break.

### 0.5.13 (2014-08-02)

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

### 0.5.12 (2014-06-01)

- Fixed: Autofocus prevention got stuck sometimes, making it impossible to
  focus inputs.

### 0.5.11 (2014-06-01)

- Fixed: The focus search bar command was broken.
- Fixed: Autofocus prevention was broken.
- Fixed: The top bar on YouTube could not be accessed by VimFx.
- Fixed: You can no longer add blank hotkeys.
- Improved: Tab Groups are supported.
- Improved: Matching of previous/next links should be more reliable.
- Improved: A few minor things.

### 0.5.10 (2014-05-07)

- Fixed yet another bug related to the default preferences

### 0.5.9 (2014-05-04)

- Fixed a bug with default preferences not being set
- Fixed gg and G to be faster

### 0.5.8 (2014-04-18)

- AMO Preliminary Review bug fix (sorry for such long delay)

### 0.5.7 (2014-03-03)

- Bug fix

### 0.5.6 (2014-02-26)

- Updated some translations
- Updated pagination patterns and logic

### 0.5.5 (2014-01-03)

- Hotfix release to address a bug that has been introduced in 0.5.4

### 0.5.4 (2014-01-03)

- Fix for popup passthrough mode stucking
- Make toolbar button click depend on current mode
- Higher weight markers should not be overlapped
- Refactor find mode to use Firefox native search bar
- Bump minimum required Firefox version to 25
- Added commands to go in the URL path
- Added commands to navigate previous and next links with customizable link
  patterns
- Use Firefox 24+ native console API
- Update zh-CN localization

### 0.5.3 (2013-10-16)

- Lots of refactoring
- Insert mode (`i` command)
- Follow multiple links with `af` command
- Hint marker rotation with `space` while in hints mode

### 0.5.1 (2013-08-21)

- Fixed regression with stylesheets
- Updated icon

### 0.5 (2013-08-19)

- Added command to focus search bar: `O`
- Added commands to stop loading current page and all pages: `s` and `as`
- Invisible elements will not get hint markers
- Compatibility with Firefox 25
- Simple shortcut customization with UI in Help dialog
- Use Huffman coding algorithm for hint markers generation which results in
  shorter links
- Implemented Bloom filters to achieve shorter hints for those shortcuts that
  are used often
- Reimplemented scrolling - now works with pages where window is not scrollable
- Find disabled on non HTML documents
- Find string is now global for all windows.
- Fixed logic of locale discovery. Now we rely on general.useragent.locale
  Firefox preference for current locale

### 0.4.8 (2013-06-12)

- `embed` and `object` tags will now have their own hints
- Bug fixes related to custom hint chars (@LordJZ)
- Fixed `t` - now it will be nice to other extensions
- Updated Chinese translations (@mozillazg)
- Reenter Normal mode on page reloads to avoid getting stuck in Hints mode
  without any hints
- Search will focus element that contains matching text
- Fixed hint markers for iframes
- Marker bug fixes (@LordJZ)

### 0.4.6 (2013-03-27)

- Reimplemented find mode: CJK support, performance boost
- `a/` or `a.` to highlight all matches of the search string on the page
- Hint markers will now reach into iframes
- Key handling is disabled when a popupmenu or panel are shown
- `yf` will now also focus links and copy values from text/textarea element
- `vf` will show hit markers to focus the underlying element

### 0.4.5 (2013-03-12)

- `:` to open Firefox Developer Toolbar, `Esc` to close it.
- Add Hungarian locale (@thenonameguy).
- Add Polish locale (@grn).
- Don't close pinned tabs when pressing x (@grn).
- Switched to Makefile for building the extension release (@carno).
- Mrakers CSS tweaks (@helmuthdu)

### 0.4.4 (2013-01-30)

- Thanks to @mozillazg and @mcomella for translation contributions.
- Added `gh` command that will navigate to the home page.
- Added `o` command to focus address bar.
- `p` and `P` will parse the contents of the clipboard. If the string in the
  clipboard appears to be a URL then it will navigate to this URL. Otherwise it
  will search for the string in the clipboard using currently selected search
  provider.
- Now hint markers for links will stay on top of all the markers for different
  kinds of elements.
- Esc will now also close the focused default search bar.
- Fixed bugs related to keyboard events handling, XUL documents, and some other
  issues.
- Bug fixed where not all the commands could be disabled via the Help dialog.

### 0.4.3 (2012-12-27)

- Toolbar button bugfix
- Added an option to disable individual commands via the help dialog

### 0.4.1, 0.4.2 (2012-12-12)

- Small tweaks of the find feature.
- Bugfix for keyboard handling on non-english keyboard layouts

### 0.4 (2012-12-09)

- Implemented find with `/` and `n/N`
- Added `ar` and `aR` commands to reload pages in all open tabs.
- Added a preference that enables blurring from any element that has input focus
  in the browser on Esc keydown (on by default)
- Fixed bug where markers and help dialog would blow up some of the pages.
- Marker hints are now sorted with respect to the underlying element area.
  Elements with larger area get shorter hints
- Added *mail.google.com* to the default black list
- Various bug fixed and improvements.

### 0.3.2, 0.3.2, 0.3.3 (2012-11-20)

- Hotfixes for the build script to include localization related files and folders

### 0.3 (2012-11-19)

- Fixed [Desktop](https://addons.mozilla.org/en-us/firefox/addon/desktop/)
  extension compatibility problem
- Removed c-b/c-f for now. c-f is a standard search hotkey. Will put c-f back
  when proper Vim-like search with / is implemented
- Scrolling with G will now reach the bottom of the page
- Implemented localization, currently there is only Russian localization.
  Community is welcome [to contribute your localizations](https://github.com/akhodakivskiy/VimFx/tree/master/extension/locale)!
- Implemented simple smooth scrolling

### 0.2 (2012-11-05)

- document.designMode='on' is now honored. Will also provide hint markers for
  iframes on the page.
- Bug fixed where it would completely reset the toolbar while installing the
  toolbar button.
- Bug fixed where it's not possible to change the text in the blacklisting
  textbox
- Changed u/d to scroll half a page, added c-f/c-b to scroll full page
- Added tab movement commands: c-J and c-K.
- Invisible markers bug fixed.
- Global hotkey to disable the commands (equal to the toolbar button click):
  Alt-Shift V
- ^u and ^d are removed from the command list. ^u is commonly used to show the
  page source code
- Opening new tab with now focuses the Address Bar
- Other small bugs nailed down.

### 0.1.1 (2012-10-27)

- Just to deal with AMO - no changes

### 0.1 (2012-10-26)

- Initial Release
