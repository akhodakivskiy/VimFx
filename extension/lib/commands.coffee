###
# Copyright Anton Khodakivskiy 2012, 2013, 2014.
# Copyright Simon Lydell 2013, 2014, 2015.
# Copyright Wang Zhuochun 2013, 2014.
#
# This file is part of VimFx.
#
# VimFx is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# VimFx is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with VimFx.  If not, see <http://www.gnu.org/licenses/>.
###

# This file defines all Normal mode commands. Commands that need to interact
# with web page content do so by running `vim._run(name)`, which invokes `name`
# in commands-frame.coffee.

# NOTE: Most tab related commands need to do their actual tab manipulations in
# the next tick (`utils.nextTick`) to work around bug 1200334.

help  = require('./help')
hints = require('./hints')
prefs = require('./prefs')
utils = require('./utils')

commands = {}



commands.focus_location_bar = ({vim}) ->
  # This function works even if the Address Bar has been removed.
  vim.window.focusAndSelectUrlBar()

commands.focus_search_bar = ({vim, count}) ->
  # The `.webSearch()` method opens a search engine in a tab if the Search Bar
  # has been removed. Therefore we first check if it exists.
  if vim.window.BrowserSearch.searchBar
    vim.window.BrowserSearch.webSearch()

helper_paste_and_go = (props, {vim}) ->
  {gURLBar} = vim.window
  gURLBar.value = vim.window.readFromClipboard()
  gURLBar.handleCommand(new vim.window.KeyboardEvent('keydown', props))

commands.paste_and_go = helper_paste_and_go.bind(null, null)

commands.paste_and_go_in_tab = helper_paste_and_go.bind(null, {altKey: true})

commands.copy_current_url = ({vim}) ->
  utils.writeToClipboard(vim.window.gBrowser.currentURI.spec)

commands.go_up_path = ({vim, count}) ->
  vim._run('go_up_path', {count})

# Go up to root of the URL hierarchy.
commands.go_to_root = ({vim}) ->
  vim._run('go_to_root')

commands.go_home = ({vim}) ->
  vim.window.BrowserHome()

helper_go_history = (num, {vim, count = 1}) ->
  {SessionStore, gBrowser} = vim.window

  # TODO: When Firefox 43 is released, only use the `.getSessionHistory`
  # version and bump the minimut Firefox version.
  if SessionStore.getSessionHistory
    SessionStore.getSessionHistory(gBrowser.selectedTab, (sessionHistory) ->
      {index} = sessionHistory
      newIndex = index + num * count
      newIndex = Math.max(newIndex, 0)
      newIndex = Math.min(newIndex, sessionHistory.entries.length - 1)
      gBrowser.gotoIndex(newIndex) unless newIndex == index
    )
  else
    # Until then, fall back to a no-count version.
    if num < 0 then gBrowser.goBack() else gBrowser.goForward()

commands.history_back    = helper_go_history.bind(null, -1)

commands.history_forward = helper_go_history.bind(null, +1)

commands.reload = ({vim}) ->
  vim.window.BrowserReload()

commands.reload_force = ({vim}) ->
  vim.window.BrowserReloadSkipCache()

commands.reload_all = ({vim}) ->
  vim.window.gBrowser.reloadAllTabs()

commands.reload_all_force = ({vim}) ->
  for tab in vim.window.gBrowser.visibleTabs
    gBrowser = tab.linkedBrowser
    consts = gBrowser.webNavigation
    flags = consts.LOAD_FLAGS_BYPASS_PROXY | consts.LOAD_FLAGS_BYPASS_CACHE
    gBrowser.reload(flags)
  return

commands.stop = ({vim}) ->
  vim.window.BrowserStop()

commands.stop_all = ({vim}) ->
  for tab in vim.window.gBrowser.visibleTabs
    tab.linkedBrowser.stop()
  return



helper_scroll = (vim, args...) ->
  [method, type, directions, amounts, properties = null, name = 'scroll'] = args
  options = {
    method, type, directions, amounts, properties
    smooth: (prefs.root.get('general.smoothScroll') and
             prefs.root.get("general.smoothScroll.#{type}"))
  }
  reset = prefs.root.tmp(
    'layout.css.scroll-behavior.spring-constant',
    vim.options["smoothScroll.#{type}.spring-constant"]
  )
  vim._run(name, options, reset)

helper_scrollByLinesX = (amount, {vim, count = 1}) ->
  distance = prefs.root.get('toolkit.scrollbox.horizontalScrollDistance')
  helper_scroll(vim, 'scrollBy', 'lines', ['left'],
                [amount * distance * count * 5])

helper_scrollByLinesY = (amount, {vim, count = 1}) ->
  distance = prefs.root.get('toolkit.scrollbox.verticalScrollDistance')
  helper_scroll(vim, 'scrollBy', 'lines', ['top'],
                [amount * distance * count * 20])

helper_scrollByPagesY = (amount, {vim, count = 1}) ->
  helper_scroll(vim, 'scrollBy', 'pages', ['top'],
                [amount * count], ['clientHeight'])

helper_scrollToX = (amount, {vim}) ->
  helper_scroll(vim, 'scrollTo', 'other', ['left'], [amount], ['scrollLeftMax'])

helper_scrollToY = (amount, {vim}) ->
  helper_scroll(vim, 'scrollTo', 'other', ['top'],  [amount], ['scrollTopMax'])

commands.scroll_left           = helper_scrollByLinesX.bind(null, -1)
commands.scroll_right          = helper_scrollByLinesX.bind(null, +1)
commands.scroll_down           = helper_scrollByLinesY.bind(null, +1)
commands.scroll_up             = helper_scrollByLinesY.bind(null, -1)
commands.scroll_page_down      = helper_scrollByPagesY.bind(null, +1)
commands.scroll_page_up        = helper_scrollByPagesY.bind(null, -1)
commands.scroll_half_page_down = helper_scrollByPagesY.bind(null, +0.5)
commands.scroll_half_page_up   = helper_scrollByPagesY.bind(null, -0.5)
commands.scroll_to_top         = helper_scrollToY.bind(null, 0)
commands.scroll_to_bottom      = helper_scrollToY.bind(null, Infinity)
commands.scroll_to_left        = helper_scrollToX.bind(null, 0)
commands.scroll_to_right       = helper_scrollToX.bind(null, Infinity)

commands.mark_scroll_position = ({vim}) ->
  vim.enterMode('marks', (keyStr) -> vim._run('mark_scroll_position', {keyStr}))

commands.scroll_to_mark = ({vim}) ->
  vim.enterMode('marks', (keyStr) ->
    helper_scroll(vim, 'scrollTo', 'other', ['top', 'left'], keyStr,
                  ['scrollTopMax', 'scrollLeftMax'], 'scroll_to_mark')
  )



commands.tab_new = ({vim}) ->
  utils.nextTick(vim.window, ->
    vim.window.BrowserOpenTab()
  )

commands.tab_duplicate = ({vim}) ->
  {gBrowser} = vim.window
  utils.nextTick(vim.window, ->
    gBrowser.duplicateTab(gBrowser.selectedTab)
  )

absoluteTabIndex = (relativeIndex, gBrowser, {pinnedSeparate}) ->
  tabs = gBrowser.visibleTabs
  {selectedTab} = gBrowser

  currentIndex  = tabs.indexOf(selectedTab)
  absoluteIndex = currentIndex + relativeIndex
  numTabsTotal  = tabs.length
  numPinnedTabs = gBrowser._numPinnedTabs

  [numTabs, min] = switch
    when not pinnedSeparate  then [numTabsTotal,  0]
    when selectedTab.pinned  then [numPinnedTabs, 0]
    else [numTabsTotal - numPinnedTabs, numPinnedTabs]

  # Wrap _once_ if at one of the ends of the tab bar and cannot move in the
  # current direction.
  if (relativeIndex < 0 and currentIndex == min) or
     (relativeIndex > 0 and currentIndex == min + numTabs - 1)
    if absoluteIndex < min
      absoluteIndex += numTabs
    else if absoluteIndex >= min + numTabs
      absoluteIndex -= numTabs

  absoluteIndex = Math.max(min, absoluteIndex)
  absoluteIndex = Math.min(absoluteIndex, min + numTabs - 1)

  return absoluteIndex

helper_switch_tab = (direction, {vim, count = 1}) ->
  {gBrowser} = vim.window
  index = absoluteTabIndex(direction * count, gBrowser, {pinnedSeparate: false})
  utils.nextTick(vim.window, ->
    gBrowser.selectTabAtIndex(index)
  )

commands.tab_select_previous = helper_switch_tab.bind(null, -1)

commands.tab_select_next     = helper_switch_tab.bind(null, +1)

helper_move_tab = (direction, {vim, count = 1}) ->
  {gBrowser} = vim.window
  index = absoluteTabIndex(direction * count, gBrowser, {pinnedSeparate: true})
  utils.nextTick(vim.window, ->
    gBrowser.moveTabTo(gBrowser.selectedTab, index)
  )

commands.tab_move_backward = helper_move_tab.bind(null, -1)

commands.tab_move_forward  = helper_move_tab.bind(null, +1)

commands.tab_select_first = ({vim, count = 1}) ->
  utils.nextTick(vim.window, ->
    vim.window.gBrowser.selectTabAtIndex(count - 1)
  )

commands.tab_select_first_non_pinned = ({vim, count = 1}) ->
  firstNonPinned = vim.window.gBrowser._numPinnedTabs
  utils.nextTick(vim.window, ->
    vim.window.gBrowser.selectTabAtIndex(firstNonPinned + count - 1)
  )

commands.tab_select_last = ({vim, count = 1}) ->
  utils.nextTick(vim.window, ->
    vim.window.gBrowser.selectTabAtIndex(-count)
  )

commands.tab_toggle_pinned = ({vim}) ->
  currentTab = vim.window.gBrowser.selectedTab
  if currentTab.pinned
    vim.window.gBrowser.unpinTab(currentTab)
  else
    vim.window.gBrowser.pinTab(currentTab)

commands.tab_close = ({vim, count = 1}) ->
  {gBrowser} = vim.window
  return if gBrowser.selectedTab.pinned
  currentIndex = gBrowser.visibleTabs.indexOf(gBrowser.selectedTab)
  utils.nextTick(vim.window, ->
    for tab in gBrowser.visibleTabs[currentIndex...(currentIndex + count)]
      gBrowser.removeTab(tab)
    return
  )

commands.tab_restore = ({vim, count = 1}) ->
  utils.nextTick(vim.window, ->
    vim.window.undoCloseTab() for [1..count] by 1
    return
  )

commands.tab_close_to_end = ({vim}) ->
  {gBrowser} = vim.window
  gBrowser.removeTabsToTheEndFrom(gBrowser.selectedTab)

commands.tab_close_other = ({vim}) ->
  {gBrowser} = vim.window
  gBrowser.removeAllTabsBut(gBrowser.selectedTab)



helper_follow = (name, vim, callback, count = null) ->
  vim.markPageInteraction()

  # Enter hints mode immediately, with an empty set of markers. The user might
  # press keys before the `vim._run` callback is invoked. Those key presses
  # should be handled in hints mode, not normal mode.
  initialMarkers = []
  storage = vim.enterMode('hints', initialMarkers, callback, count)

  vim._run(name, null, ({wrappers, viewport}) ->
    # The user might have exited hints mode (and perhaps even entered it again)
    # before this callback is invoked. If so, `storage.markers` has been
    # cleared, or set to a new value. Only proceed if it is unchanged.
    return unless storage.markers == initialMarkers

    if wrappers.length > 0
      markers = hints.injectHints(vim.window, wrappers, viewport, vim.options)
      storage.markers = markers
    else
      vim.enterMode('normal')
  )

helper_follow_clickable = ({inTab, inBackground}, {vim, count = 1}) ->
  callback = (marker, timesLeft, keyStr) ->
    {type, elementIndex} = marker.wrapper
    isLast = (timesLeft == 1)
    isLink = (type == 'link')

    switch
      when keyStr.startsWith(vim.options.hints_toggle_in_tab)
        inTab = not inTab
      when keyStr.startsWith(vim.options.hints_toggle_in_background)
        inTab = true
        inBackground = not inBackground
      else
        unless isLast
          inTab = true
          inBackground = true

    inTab = false unless isLink

    if type == 'text' or (isLink and not (inTab and inBackground))
      isLast = true

    vim._focusMarkerElement(elementIndex)

    if inTab
      utils.nextTick(vim.window, ->
        utils.openTab(vim.window, marker.wrapper.href, {
          inBackground
          relatedToCurrent: true
        })
      )
    else
      vim._run('click_marker_element', {
        elementIndex, type
        preventTargetBlank: vim.options.prevent_target_blank
      })

    return not isLast

  name = if inTab then 'follow_in_tab' else 'follow'
  helper_follow(name, vim, callback, count)

# Follow links, focus text inputs and click buttons with hint markers.
commands.follow =
  helper_follow_clickable.bind(null, {inTab: false, inBackground: true})

# Follow links in a new background tab with hint markers.
commands.follow_in_tab =
  helper_follow_clickable.bind(null, {inTab: true, inBackground: true})

# Follow links in a new foreground tab with hint markers.
commands.follow_in_focused_tab =
  helper_follow_clickable.bind(null, {inTab: true, inBackground: false})

# Like command_follow but multiple times.
commands.follow_multiple = (args) ->
  args.count = Infinity
  commands.follow(args)

# Copy the URL or text of a markable element to the system clipboard.
commands.follow_copy = ({vim}) ->
  callback = (marker) ->
    {elementIndex} = marker.wrapper
    property = switch marker.wrapper.type
      when 'link'            then 'href'
      when 'text'            then 'value'
      when 'contenteditable' then 'textContent'
    vim._run('copy_marker_element', {elementIndex, property})
  helper_follow('follow_copy', vim, callback)

# Focus element with hint markers.
commands.follow_focus = ({vim}) ->
  callback = (marker) ->
    vim._focusMarkerElement(marker.wrapper.elementIndex, {select: true})
  return helper_follow('follow_focus', vim, callback)

helper_follow_pattern = (type, {vim}) ->
  options =
    pattern_selector: vim.options.pattern_selector
    pattern_attrs:    vim.options.pattern_attrs
    patterns:         vim.options["#{type}_patterns"]
  vim._run('follow_pattern', {type, options})

commands.follow_previous = helper_follow_pattern.bind(null, 'prev')

commands.follow_next     = helper_follow_pattern.bind(null, 'next')

# Focus last focused or first text input.
commands.focus_text_input = ({vim, count}) ->
  vim.markPageInteraction()
  vim._run('focus_text_input', {count})



findStorage = {lastSearchString: ''}

helper_find = (highlight, {vim}) ->
  findBar = vim.window.gBrowser.getFindBar()

  findBar.onFindCommand()
  utils.focusElement(findBar._findField, {select: true})

  return unless highlightButton = findBar.getElement('highlight')
  if highlightButton.checked != highlight
    highlightButton.click()

# Open the find bar, making sure that hightlighting is off.
commands.find = helper_find.bind(null, false)

# Open the find bar, making sure that hightlighting is on.
commands.find_highlight_all = helper_find.bind(null, true)

helper_find_again = (direction, {vim}) ->
  findBar = vim.window.gBrowser.getFindBar()
  if findStorage.lastSearchString.length > 0
    findBar._findField.value = findStorage.lastSearchString
    findBar.onFindAgainCommand(direction)
    message = findBar._findStatusDesc.textContent
    vim.notify(message) if message

commands.find_next     = helper_find_again.bind(null, false)

commands.find_previous = helper_find_again.bind(null, true)



commands.enter_mode_ignore = ({vim}) ->
  vim.enterMode('ignore')

# Quote next keypress (pass it through to the page).
commands.quote = ({vim, count = 1}) ->
  vim.enterMode('ignore', count)

# Display the Help Dialog.
commands.help = ({vim}) ->
  help.injectHelp(vim.window, vim._parent)

# Open and focus the Developer Toolbar.
commands.dev = ({vim}) ->
  vim.window.DeveloperToolbar.show(true) # `true` to focus.

commands.esc = ({vim}) ->
  vim._run('esc')
  utils.blurActiveBrowserElement(vim)
  help.removeHelp(vim.window)
  vim.window.DeveloperToolbar.hide()
  vim.window.gBrowser.getFindBar().close()
  # TODO: Remove when Tab Groups have been removed.
  vim.window.TabView?.hide()
  hints.removeHints(vim.window) # Better safe than sorry.



module.exports = {
  commands
  findStorage
}
