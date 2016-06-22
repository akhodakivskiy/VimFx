###
# Copyright Anton Khodakivskiy 2012, 2013, 2014.
# Copyright Simon Lydell 2013, 2014, 2015, 2016.
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

config = require('./config')
help = require('./help')
markableElements = require('./markable-elements')
MarkerContainer = require('./marker-container')
prefs = require('./prefs')
SelectionManager = require('./selection')
translate = require('./translate')
utils = require('./utils')
viewportUtils = require('./viewport')

{ContentClick} = Cu.import('resource:///modules/ContentClick.jsm', {})
{FORWARD, BACKWARD} = SelectionManager

SPRING_CONSTANT_PREF = 'layout.css.scroll-behavior.spring-constant'

commands = {}



commands.focus_location_bar = ({vim}) ->
  vim.window.focusAndSelectUrlBar()

commands.focus_search_bar = ({vim, count}) ->
  # The `.webSearch()` method opens a search engine in a tab if the search bar
  # has been removed. Therefore we first check if it exists.
  if vim.window.BrowserSearch.searchBar
    vim.window.BrowserSearch.webSearch()
  else
    vim.notify(translate('notification.focus_search_bar.none'))

helper_paste_and_go = (props, {vim}) ->
  {gURLBar} = vim.window
  gURLBar.value = vim.window.readFromClipboard()
  gURLBar.handleCommand(new vim.window.KeyboardEvent('keydown', props))

commands.paste_and_go = helper_paste_and_go.bind(null, null)

commands.paste_and_go_in_tab = helper_paste_and_go.bind(null, {altKey: true})

commands.copy_current_url = ({vim}) ->
  utils.writeToClipboard(vim.window.gBrowser.currentURI.spec)
  vim.notify(translate('notification.copy_current_url.success'))

commands.go_up_path = ({vim, count}) ->
  vim._run('go_up_path', {count})

commands.go_to_root = ({vim}) ->
  vim._run('go_to_root')

commands.go_home = ({vim}) ->
  vim.window.BrowserHome()

helper_go_history = (direction, {vim, count = 1}) ->
  {window} = vim
  {SessionStore, gBrowser} = window

  if (direction == 'back'    and not gBrowser.canGoBack) or
     (direction == 'forward' and not gBrowser.canGoForward)
    vim.notify(translate("notification.history_#{direction}.limit"))
    return

  # `SessionStore.getSessionHistory()` (used below to support counts) starts
  # lots of asynchronous tasks internally, which is a bit unreliable, it has
  # turned out. The primary use of the `history_back` and `history_forward`
  # commands is to go _one_ step back or forward, though, so those cases are
  # optimized to use more reliable ways of going back and forward. Also, some
  # extensions override the following functions, so calling them also gives
  # better interoperability.
  if count == 1
    if direction == 'back'
      window.BrowserBack()
    else
      window.BrowserForward()
    return

  SessionStore.getSessionHistory(gBrowser.selectedTab, (sessionHistory) ->
    {index} = sessionHistory
    newIndex = index + count * (if direction == 'back' then -1 else 1)
    newIndex = Math.max(newIndex, 0)
    newIndex = Math.min(newIndex, sessionHistory.entries.length - 1)
    gBrowser.gotoIndex(newIndex)
  )

commands.history_back    = helper_go_history.bind(null, 'back')

commands.history_forward = helper_go_history.bind(null, 'forward')

commands.history_list = ({vim}) ->
  menu = vim.window.document.getElementById('backForwardMenu')
  utils.openPopup(menu)
  if menu.childElementCount == 0
    vim.notify(translate('notification.history_list.none'))

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



springConstant = {
  nonce: null
  value: null
}

helper_scroll = (vim, uiEvent, args...) ->
  [
    method, type, directions, amounts
    properties = null, adjustment = 0, name = 'scroll'
  ] = args
  options = {
    method, type, directions, amounts, properties, adjustment
    smooth: (
      prefs.root.get('general.smoothScroll') and
      prefs.root.get("general.smoothScroll.#{type}")
    )
  }

  # Temporarily set Firefox’s “spring constant” pref to get the desired smooth
  # scrolling speed. Reset it `reset_timeout` milliseconds after the last
  # scrolling command was invoked.
  springConstant.nonce = nonce = {}
  springConstant.value ?= prefs.root.get(SPRING_CONSTANT_PREF)
  prefs.root.set(
    SPRING_CONSTANT_PREF,
    vim.options["smoothScroll.#{type}.spring-constant"]
  )
  reset = ->
    vim.window.setTimeout((->
      return unless springConstant.nonce == nonce
      prefs.root.set(SPRING_CONSTANT_PREF, springConstant.value)
      springConstant.nonce = null
      springConstant.value = null
    ), vim.options['scroll.reset_timeout'])

  helpScroll = help.getHelp(vim.window)?.querySelector('.wrapper')
  if uiEvent or helpScroll
    activeElement = helpScroll or utils.getActiveElement(vim.window)
    if vim._state.scrollableElements.has(activeElement) or helpScroll
      viewportUtils.scroll(activeElement, options)
      reset()
      return

  vim._run(name, options, reset)


helper_scrollByLinesX = (amount, {vim, uiEvent, count = 1}) ->
  distance = prefs.root.get('toolkit.scrollbox.horizontalScrollDistance')
  helper_scroll(
    vim, uiEvent, 'scrollBy', 'lines', ['left'], [amount * distance * count * 5]
  )

helper_scrollByLinesY = (amount, {vim, uiEvent, count = 1}) ->
  distance = prefs.root.get('toolkit.scrollbox.verticalScrollDistance')
  helper_scroll(
    vim, uiEvent, 'scrollBy', 'lines', ['top'], [amount * distance * count * 20]
  )

helper_scrollByPagesY = (amount, type, {vim, uiEvent, count = 1}) ->
  adjustment = vim.options["scroll.#{type}_page_adjustment"]
  helper_scroll(
    vim, uiEvent, 'scrollBy', 'pages', ['top'], [amount * count],
    ['clientHeight'], adjustment
  )

helper_scrollToX = (amount, {vim, uiEvent}) ->
  helper_mark_last_scroll_position(vim)
  helper_scroll(
    vim, uiEvent, 'scrollTo', 'other', ['left'], [amount], ['scrollLeftMax']
  )

helper_scrollToY = (amount, {vim, uiEvent}) ->
  helper_mark_last_scroll_position(vim)
  helper_scroll(
    vim, uiEvent, 'scrollTo', 'other', ['top'], [amount], ['scrollTopMax']
  )

commands.scroll_left           = helper_scrollByLinesX.bind(null, -1)
commands.scroll_right          = helper_scrollByLinesX.bind(null, +1)
commands.scroll_down           = helper_scrollByLinesY.bind(null, +1)
commands.scroll_up             = helper_scrollByLinesY.bind(null, -1)
commands.scroll_page_down      = helper_scrollByPagesY.bind(null, +1,   'full')
commands.scroll_page_up        = helper_scrollByPagesY.bind(null, -1,   'full')
commands.scroll_half_page_down = helper_scrollByPagesY.bind(null, +0.5, 'half')
commands.scroll_half_page_up   = helper_scrollByPagesY.bind(null, -0.5, 'half')
commands.scroll_to_top         = helper_scrollToY.bind(null, 0)
commands.scroll_to_bottom      = helper_scrollToY.bind(null, Infinity)
commands.scroll_to_left        = helper_scrollToX.bind(null, 0)
commands.scroll_to_right       = helper_scrollToX.bind(null, Infinity)

helper_mark_last_scroll_position = (vim) ->
  keyStr = vim.options['scroll.last_position_mark']
  vim._run('mark_scroll_position', {keyStr, notify: false})

commands.mark_scroll_position = ({vim}) ->
  vim.enterMode('marks', (keyStr) -> vim._run('mark_scroll_position', {keyStr}))
  vim.notify(translate('notification.mark_scroll_position.enter'))

commands.scroll_to_mark = ({vim}) ->
  vim.enterMode('marks', (keyStr) ->
    unless keyStr == vim.options['scroll.last_position_mark']
      helper_mark_last_scroll_position(vim)
    helper_scroll(
      vim, null, 'scrollTo', 'other', ['top', 'left'], keyStr,
      ['scrollTopMax', 'scrollLeftMax'], 0, 'scroll_to_mark'
    )
  )
  vim.notify(translate('notification.scroll_to_mark.enter'))



commands.tab_new = ({vim}) ->
  utils.nextTick(vim.window, ->
    vim.window.BrowserOpenTab()
  )

commands.tab_new_after_current = ({vim}) ->
  {window} = vim
  newTabPosition = window.gBrowser.selectedTab._tPos + 1
  utils.nextTick(window, ->
    utils.listenOnce(window, 'TabOpen', (event) ->
      newTab = event.originalTarget
      window.gBrowser.moveTabTo(newTab, newTabPosition)
    )
    window.BrowserOpenTab()
  )

commands.tab_duplicate = ({vim}) ->
  {gBrowser} = vim.window
  utils.nextTick(vim.window, ->
    gBrowser.duplicateTab(gBrowser.selectedTab)
  )

absoluteTabIndex = (relativeIndex, gBrowser, {pinnedSeparate}) ->
  tabs = gBrowser.visibleTabs
  {selectedTab} = gBrowser

  currentIndex = tabs.indexOf(selectedTab)
  absoluteIndex = currentIndex + relativeIndex
  numTabsTotal = tabs.length
  numPinnedTabs = gBrowser._numPinnedTabs

  [numTabs, min] = switch
    when not pinnedSeparate
      [numTabsTotal,  0]
    when selectedTab.pinned
      [numPinnedTabs, 0]
    else
      [numTabsTotal - numPinnedTabs, numPinnedTabs]

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

helper_is_visited = (tab) ->
  return tab.getAttribute('VimFx-visited') or not tab.getAttribute('unread')

commands.tab_select_most_recent = ({vim, count = 1}) ->
  {gBrowser} = vim.window
  tabsSorted =
    Array.filter(
      gBrowser.tabs,
      (tab) -> not tab.closing and helper_is_visited(tab)
    ).sort((a, b) -> b.lastAccessed - a.lastAccessed)[1..] # Remove current tab.
  tab = tabsSorted[Math.min(count - 1, tabsSorted.length - 1)]
  if tab
    gBrowser.selectedTab = tab
  else
    vim.notify(translate('notification.tab_select_most_recent.none'))

commands.tab_select_oldest_unvisited = ({vim, count = 1}) ->
  {gBrowser} = vim.window
  tabsSorted =
    Array.filter(
      gBrowser.tabs,
      (tab) -> not tab.closing and not helper_is_visited(tab)
    ).sort((a, b) -> a.lastAccessed - b.lastAccessed)
  tab = tabsSorted[Math.min(count - 1, tabsSorted.length - 1)]
  if tab
    gBrowser.selectedTab = tab
  else
    vim.notify(translate('notification.tab_select_oldest_unvisited.none'))

helper_move_tab = (direction, {vim, count = 1}) ->
  {gBrowser} = vim.window
  index = absoluteTabIndex(direction * count, gBrowser, {pinnedSeparate: true})
  utils.nextTick(vim.window, ->
    gBrowser.moveTabTo(gBrowser.selectedTab, index)
  )

commands.tab_move_backward = helper_move_tab.bind(null, -1)

commands.tab_move_forward  = helper_move_tab.bind(null, +1)

commands.tab_move_to_window = ({vim}) ->
  {gBrowser} = vim.window
  gBrowser.replaceTabWithWindow(gBrowser.selectedTab)

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
    for index in [0...count] by 1
      restoredTab = vim.window.undoCloseTab()
      if not restoredTab and index == 0
        vim.notify(translate('notification.tab_restore.none'))
        break
    return
  )

commands.tab_restore_list = ({vim}) ->
  {window} = vim
  fragment = window.RecentlyClosedTabsAndWindowsMenuUtils.getTabsFragment(
    window, 'menuitem'
  )
  if fragment.childElementCount == 0
    vim.notify(translate('notification.tab_restore.none'))
  else
    utils.openPopup(utils.injectTemporaryPopup(window.document, fragment))

commands.tab_close_to_end = ({vim}) ->
  {gBrowser} = vim.window
  gBrowser.removeTabsToTheEndFrom(gBrowser.selectedTab)

commands.tab_close_other = ({vim}) ->
  {gBrowser} = vim.window
  gBrowser.removeAllTabsBut(gBrowser.selectedTab)



helper_follow = (name, vim, callback, count = null) ->
  {window} = vim
  vim.markPageInteraction()
  help.removeHelp(window)

  markerContainer = new MarkerContainer({
    window
    hintChars: vim.options.hint_chars
    getComplementaryWrappers: (callback) ->
      vim._run(name, {pass: 'complementary'}, ({wrappers, viewport}) ->
        # `markerContainer.container` is `null`ed out when leaving Hints mode.
        # If this callback is called after we’ve left Hints mode (and perhaps
        # even entered it again), simply discard the result.
        return unless markerContainer.container
        if wrappers.length == 0
          vim.notify(translate('notification.follow.none'))
        callback({wrappers, viewport})
      )
  })
  MarkerContainer.remove(window) # Better safe than sorry.
  window.gBrowser.selectedBrowser.parentNode.appendChild(
    markerContainer.container
  )

  # Enter Hints mode immediately, with an empty set of markers. The user might
  # press keys before any hints have been generated. Those key presses should be
  # handled in Hints mode, not Normal mode.
  vim.enterMode('hints', {
    markerContainer, callback, count
    sleep: vim.options.hints_sleep
  })

  injectHints = ({wrappers, viewport, pass}) ->
    # See `getComplementaryWrappers` above.
    return unless markerContainer.container

    if wrappers.length == 0
      if pass in ['single', 'second'] and markerContainer.markers.length == 0
        vim.notify(translate('notification.follow.none'))
        vim.enterMode('normal')
    else
      markerContainer.injectHints(wrappers, viewport, pass)

    if pass == 'first'
      vim._run(name, {pass: 'second'}, injectHints)

  vim._run(name, {pass: 'auto'}, injectHints)

helper_follow_clickable = (options, {vim, count = 1}) ->
  callback = (marker, timesLeft, keyStr) ->
    {inTab, inBackground} = options
    {type, elementIndex} = marker.wrapper
    isLast = (timesLeft == 1)
    isLink = (type == 'link')
    {window} = vim

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
      utils.nextTick(window, ->
        # `ContentClick.contentAreaClick` is what Firefox invokes when you click
        # links using the mouse. Using that instead of simply
        # `gBrowser.loadOneTab(url, options)` gives better interoperability with
        # other add-ons, such as Tree Style Tab and BackTrack Tab History.
        reset = prefs.root.tmp('browser.tabs.loadInBackground', true)
        ContentClick.contentAreaClick({
          href: marker.wrapper.href
          shiftKey: not inBackground
          ctrlKey: true
          metaKey: true
          originAttributes: window.document.nodePrincipal?.originAttributes ? {}
        }, vim.browser)
        reset()
      )
    else
      vim._run('click_marker_element', {
        elementIndex, type
        preventTargetBlank: vim.options.prevent_target_blank
      })

    return not isLast

  name = if options.inTab then 'follow_in_tab' else 'follow'
  helper_follow(name, vim, callback, count)

commands.follow =
  helper_follow_clickable.bind(null, {inTab: false, inBackground: true})

commands.follow_in_tab =
  helper_follow_clickable.bind(null, {inTab: true, inBackground: true})

commands.follow_in_focused_tab =
  helper_follow_clickable.bind(null, {inTab: true, inBackground: false})

commands.follow_in_window = ({vim}) ->
  callback = (marker) ->
    vim._focusMarkerElement(marker.wrapper.elementIndex)
    {href} = marker.wrapper
    vim.window.openLinkIn(href, 'window', {}) if href
    return false
  helper_follow('follow_in_tab', vim, callback)

commands.follow_multiple = (args) ->
  args.count = Infinity
  commands.follow(args)

commands.follow_copy = ({vim}) ->
  callback = (marker) ->
    property = switch marker.wrapper.type
      when 'link'
        'href'
      when 'text'
        'value'
      when 'contenteditable', 'complementary'
        '_selection'
    helper_copy_marker_element(vim, marker.wrapper.elementIndex, property)
    return false
  helper_follow('follow_copy', vim, callback)

commands.follow_focus = ({vim}) ->
  callback = (marker) ->
    vim._focusMarkerElement(marker.wrapper.elementIndex, {select: true})
    return false
  helper_follow('follow_focus', vim, callback)

commands.click_browser_element = ({vim}) ->
  {window} = vim
  markerElements = []

  getButtonMenu = (element) ->
    if element.localName == 'dropmarker' and
       element.parentNode?.localName == 'toolbarbutton'
      return element.parentNode.querySelector('menupopup')
    else
      return null

  filter = ({complementary}, element, getElementShape) ->
    type = switch
      when vim._state.scrollableElements.has(element)
        'scrollable'
      when getButtonMenu(element)
        'dropmarker'
      when utils.isFocusable(element) or
           (element.onclick and element.localName != 'statuspanel')
        'clickable'

    if complementary
      type = if type then null else 'complementary'

    return unless type

    # `getElementShape(element, -1)` is intentionally _not_ used in the
    # `complementary` run, because it results in tons of useless hints for
    # hidden context menus.
    shape = getElementShape(element)
    return unless shape.nonCoveredPoint

    length = markerElements.push(element)
    return {type, shape, elementIndex: length - 1}

  callback = (marker) ->
    element = markerElements[marker.wrapper.elementIndex]
    switch marker.wrapper.type
      when 'scrollable'
        utils.focusElement(element, {flag: 'FLAG_BYKEY'})
      when 'dropmarker'
        getButtonMenu(element).openPopup(
          element.parentNode, # Anchor node.
          'after_end', # Position.
          0, 0, # Offset.
          false, # Isn’t a context menu.
          true, # Allow the 'position' attribute to override the above position.
        )
      when 'clickable', 'complementary'
        # VimFx’s own button won’t trigger unless the click is simulated in the
        # next tick. This might be true for other buttons as well.
        utils.nextTick(window, ->
          utils.focusElement(element)
          switch
            when element.localName == 'tab'
              # Only 'mousedown' seems to be able to activate tabs.
              utils.simulateMouseEvents(element, ['mousedown'])
            when element.closest('tab')
              # If `.click()` is used on a tab close button, its tab will be
              # selected first, which might cause the selected tab to change.
              utils.simulateMouseEvents(element, 'click-xul')
            else
              # `.click()` seems to trigger more buttons (such as NoScript’s
              # button and Firefox’s “hamburger” menu button) than simulating
              # 'click-xul'.
              element.click()
              utils.openDropdown(element)
        )
    return false

  wrappers = markableElements.find(
    window, filter.bind(null, {complementary: false})
  )

  if wrappers.length > 0
    viewport = viewportUtils.getWindowViewport(window)

    markerContainer = new MarkerContainer({
      window
      hintChars: vim.options.hint_chars
      adjustZoom: false
      getComplementaryWrappers: (callback) ->
        newWrappers = markableElements.find(
          window, filter.bind(null, {complementary: true})
        )
        callback({wrappers: newWrappers, viewport})
    })
    MarkerContainer.remove(window) # Better safe than sorry.
    markerContainer.container.classList.add('ui')
    window.document.getElementById('browser-panel').appendChild(
      markerContainer.container
    )

    markerContainer.injectHints(wrappers, viewport, 'single')
    vim.enterMode('hints', {markerContainer, callback})

  else
    vim.notify(translate('notification.follow.none'))

helper_follow_pattern = (type, {vim}) ->
  options = {
    pattern_selector: vim.options.pattern_selector
    pattern_attrs: vim.options.pattern_attrs
    patterns: vim.options["#{type}_patterns"]
  }
  vim._run('follow_pattern', {type, options})

commands.follow_previous = helper_follow_pattern.bind(null, 'prev')

commands.follow_next     = helper_follow_pattern.bind(null, 'next')

commands.focus_text_input = ({vim, count}) ->
  vim.markPageInteraction()
  vim._run('focus_text_input', {count})

helper_follow_selectable = ({select}, {vim}) ->
  callback = (marker) ->
    vim._run('element_text_select', {
      elementIndex: marker.wrapper.elementIndex
      full: select
      scroll: select
    })
    vim.enterMode('caret', select)
    return false
  helper_follow('follow_selectable', vim, callback)

commands.element_text_caret =
  helper_follow_selectable.bind(null, {select: false})

commands.element_text_select =
  helper_follow_selectable.bind(null, {select: true})

commands.element_text_copy = ({vim}) ->
  callback = (marker) ->
    helper_copy_marker_element(vim, marker.wrapper.elementIndex, '_selection')
    return false
  helper_follow('follow_selectable', vim, callback)

helper_copy_marker_element = (vim, elementIndex, property) ->
  if property == '_selection'
    # Selecting the text and then copying that selection is better than copying
    # `.textContent`. Slack uses markdown-style backtick syntax for code spans
    # and then includes those backticks in the compiled output (!), in hidden
    # `<span>`s, so `.textContent` would copy those too. In `contenteditable`
    # elements, text selection gives better whitespace than `.textContent`.
    vim._run('element_text_select', {elementIndex, full: true}, ->
      vim.window.goDoCommand('cmd_copy') # See `caret.copy_selection_and_exit`.
      vim._run('clear_selection')
    )
  else
    vim._run('copy_marker_element', {elementIndex, property})



findStorage = {
  lastSearchString: ''
  busy: false
}

helper_find_from_top_of_viewport = (vim, direction, callback) ->
  return if findStorage.busy
  if vim.options.find_from_top_of_viewport
    findStorage.busy = true
    vim._run('find_from_top_of_viewport', {direction}, ->
      findStorage.busy = false
      callback()
    )
  else
    callback()

helper_find = ({highlight, linksOnly = false}, {vim}) ->
  helpSearchInput = help.getSearchInput(vim.window)
  if helpSearchInput
    helpSearchInput.select()
    return

  # In case `helper_find_from_top_of_viewport` is slow, make sure that keys
  # pressed before the find bar input is focsued doesn’t trigger commands.
  vim.enterMode('find')

  helper_mark_last_scroll_position(vim)
  helper_find_from_top_of_viewport(vim, FORWARD, ->
    return unless vim.mode == 'find'
    findBar = vim.window.gBrowser.getFindBar()

    mode = if linksOnly then findBar.FIND_LINKS else findBar.FIND_NORMAL
    findBar.startFind(mode)
    utils.focusElement(findBar._findField, {select: true})

    return if linksOnly
    return unless highlightButton = findBar.getElement('highlight')
    if highlightButton.checked != highlight
      highlightButton.click()
  )

commands.find = helper_find.bind(null, {highlight: false})

commands.find_highlight_all = helper_find.bind(null, {highlight: true})

commands.find_links_only = helper_find.bind(null, {linksOnly: true})

helper_find_again = (direction, {vim}) ->
  findBar = vim.window.gBrowser.getFindBar()
  if findStorage.lastSearchString.length == 0
    vim.notify(translate('notification.find_again.none'))
    return

  helper_mark_last_scroll_position(vim)
  helper_find_from_top_of_viewport(vim, direction, ->
    findBar._findField.value = findStorage.lastSearchString

    # Temporarily hack `.onFindResult` to be able to know when the asynchronous
    # `.onFindAgainCommand` is done.
    originalOnFindResult = findBar.onFindResult
    findBar.onFindResult = (data) ->
      # Prevent the find bar from re-opening if there are no matches.
      data.storeResult = false
      findBar.onFindResult = originalOnFindResult
      findBar.onFindResult(data)
      message = findBar._findStatusDesc.textContent
      vim.notify(message) if message

    findBar.onFindAgainCommand(not direction)
  )

commands.find_next     = helper_find_again.bind(null, FORWARD)

commands.find_previous = helper_find_again.bind(null, BACKWARD)



commands.window_new = ({vim}) ->
  vim.window.OpenBrowserWindow()

commands.window_new_private = ({vim}) ->
  vim.window.OpenBrowserWindow({private: true})

commands.enter_mode_ignore = ({vim}) ->
  vim.enterMode('ignore', {type: 'explicit'})

# Quote next keypress (pass it through to the page).
commands.quote = ({vim, count = 1}) ->
  vim.enterMode('ignore', {type: 'explicit', count})

commands.enter_reader_view = ({vim}) ->
  button = vim.window.document.getElementById('reader-mode-button')
  if not button?.hidden
    button.click()
  else
    vim.notify(translate('notification.enter_reader_view.none'))

commands.reload_config_file = ({vim}) ->
  vim._parent.emit('shutdown')
  config.load(vim._parent, (status) -> switch status
    when null
      vim.notify(translate('notification.reload_config_file.none'))
    when true
      vim.notify(translate('notification.reload_config_file.success'))
    else
      vim.notify(translate('notification.reload_config_file.failure'))
  )

commands.help = ({vim}) ->
  help.toggleHelp(vim.window, vim._parent)

commands.dev = ({vim}) ->
  vim.window.DeveloperToolbar.show(true) # `true` to focus.

commands.esc = ({vim}) ->
  vim._run('esc')
  utils.blurActiveBrowserElement(vim)
  vim.window.gBrowser.getFindBar().close()
  MarkerContainer.remove(vim.window) # Better safe than sorry.

  # Calling `.hide()` when the toolbar is not open can destroy it for the rest
  # of the Firefox session. The code here is taken from the `.toggle()` method.
  {DeveloperToolbar} = vim.window
  if DeveloperToolbar.visible
    DeveloperToolbar.hide().catch(console.error)

  unless help.getSearchInput(vim.window)?.getAttribute('focused')
    help.removeHelp(vim.window)



module.exports = {
  commands
  findStorage
}
