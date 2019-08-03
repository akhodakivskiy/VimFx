# This file defines all Normal mode commands. Commands that need to interact
# with web page content do so by running `vim._run(name)`, which invokes `name`
# in commands-frame.coffee.

# NOTE: Most tab related commands need to do their actual tab manipulations in
# the next tick (`utils.nextTick`) to work around bug 1200334.

config = require('./config')
help = require('./help')
markableElements = require('./markable-elements')
MarkerContainer = require('./marker-container')
parsePrefs = require('./parse-prefs')
prefs = require('./prefs')
SelectionManager = require('./selection')
translate = require('./translate')
utils = require('./utils')
viewportUtils = require('./viewport')

{ContentClick} = Cu.import('resource:///modules/ContentClick.jsm', {})
{FORWARD, BACKWARD} = SelectionManager

READER_VIEW_PREFIX = 'about:reader?url='
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
  url = vim.window.gBrowser.currentURI.spec
  adjustedUrl =
    if url.startsWith(READER_VIEW_PREFIX)
      decodeURIComponent(url[READER_VIEW_PREFIX.length..])
    else
      url
  utils.writeToClipboard(adjustedUrl)
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



scrollData = {
  nonce: null
  springConstant: null
  lastRepeat: 0
}

helper_scroll = (vim, event, args...) ->
  [
    method, type, directions, amounts
    properties = null, adjustment = 0, name = 'scroll', extra = {}
  ] = args

  elapsed = event.timeStamp - scrollData.lastRepeat

  if event.repeat and elapsed < vim.options['scroll.repeat_timeout']
    return

  scrollData.lastRepeat = event.timeStamp

  options = {
    method, type, directions, amounts, properties, adjustment, extra
    smooth: (
      prefs.root.get('general.smoothScroll') and
      prefs.root.get("general.smoothScroll.#{type}")
    )
  }

  # Temporarily set Firefox’s “spring constant” pref to get the desired smooth
  # scrolling speed. Reset it `reset_timeout` milliseconds after the last
  # scrolling command was invoked.
  scrollData.nonce = nonce = {}
  scrollData.springConstant ?= prefs.root.get(SPRING_CONSTANT_PREF)
  prefs.root.set(
    SPRING_CONSTANT_PREF,
    vim.options["smoothScroll.#{type}.spring-constant"]
  )
  reset = ->
    vim.window.setTimeout((->
      return unless scrollData.nonce == nonce
      prefs.root.set(SPRING_CONSTANT_PREF, scrollData.springConstant)
      scrollData.nonce = null
      scrollData.springConstant = null
    ), vim.options['scroll.reset_timeout'])

  {isUIEvent = vim.isUIEvent(event)} = extra
  helpScroll = help.getHelp(vim.window)?.querySelector('.wrapper')
  if isUIEvent or helpScroll
    activeElement = helpScroll or utils.getActiveElement(vim.window)
    if vim._state.scrollableElements.has(activeElement) or helpScroll
      viewportUtils.scroll(activeElement, options)
      reset()
      return

  vim._run(name, options, reset)


helper_scrollByLinesX = (amount, {vim, event, count = 1}) ->
  distance = prefs.root.get('toolkit.scrollbox.horizontalScrollDistance')
  boost = if event.repeat then vim.options['scroll.horizontal_boost'] else 1
  helper_scroll(
    vim, event, 'scrollBy', 'lines', ['left'],
    [amount * distance * boost * count * 5]
  )

helper_scrollByLinesY = (amount, {vim, event, count = 1}) ->
  distance = prefs.root.get('toolkit.scrollbox.verticalScrollDistance')
  boost = if event.repeat then vim.options['scroll.vertical_boost'] else 1
  helper_scroll(
    vim, event, 'scrollBy', 'lines', ['top'],
    [amount * distance * boost * count * 20]
  )

helper_scrollByPagesY = (amount, type, {vim, event, count = 1}) ->
  adjustment = vim.options["scroll.#{type}_page_adjustment"]
  helper_scroll(
    vim, event, 'scrollBy', 'pages', ['top'], [amount * count],
    ['clientHeight'], adjustment
  )

helper_scrollToX = (amount, {vim, event}) ->
  helper_mark_last_scroll_position(vim)
  helper_scroll(
    vim, event, 'scrollTo', 'other', ['left'], [amount], ['scrollLeftMax']
  )

helper_scrollToY = (amount, {vim, event}) ->
  helper_mark_last_scroll_position(vim)
  helper_scroll(
    vim, event, 'scrollTo', 'other', ['top'], [amount], ['scrollTopMax']
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
  vim._run('mark_scroll_position', {keyStr, notify: false, addToJumpList: true})

commands.mark_scroll_position = ({vim}) ->
  vim._enterMode('marks', (keyStr) ->
    vim._run('mark_scroll_position', {keyStr})
  )
  vim.notify(translate('notification.mark_scroll_position.enter'))

commands.scroll_to_mark = ({vim, event}) ->
  vim._enterMode('marks', (keyStr) ->
    lastPositionMark = vim.options['scroll.last_position_mark']
    helper_scroll(
      vim, event, 'scrollTo', 'other', ['left', 'top'], [0, 0]
      ['scrollLeftMax', 'scrollTopMax'], 0, 'scroll_to_mark'
      {keyStr, lastPositionMark, isUIEvent: false}
    )
    vim.hideNotification()
  )
  vim.notify(translate('notification.scroll_to_mark.enter'))

helper_scroll_to_position = (direction, {vim, event, count = 1}) ->
  lastPositionMark = vim.options['scroll.last_position_mark']
  helper_scroll(
    vim, event, 'scrollTo', 'other', ['left', 'top'], [0, 0]
    ['scrollLeftMax', 'scrollTopMax'], 0, 'scroll_to_position'
    {count, direction, lastPositionMark, isUIEvent: false}
  )

commands.scroll_to_previous_position =
  helper_scroll_to_position.bind(null, 'previous')

commands.scroll_to_next_position =
  helper_scroll_to_position.bind(null, 'next')



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
    Array.prototype.filter.call(
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
    Array.prototype.filter.call(
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



helper_follow = ({name, callback}, {vim, count, callbackOverride = null}) ->
  {window} = vim
  vim.markPageInteraction()
  help.removeHelp(window)

  markerContainer = new MarkerContainer({
    window
    hintChars: vim.options['hints.chars']
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

  chooseCallback = (marker, timesLeft, keyStr) ->
    if callbackOverride
      {type, href = null, elementIndex} = marker.wrapper
      return callbackOverride({type, href, id: elementIndex, timesLeft})
    else
      return callback(marker, timesLeft, keyStr)

  # Enter Hints mode immediately, with an empty set of markers. The user might
  # press keys before any hints have been generated. Those keypresses should be
  # handled in Hints mode, not Normal mode.
  vim._enterMode('hints', {
    markerContainer, count
    callback: chooseCallback
    matchText: vim.options['hints.match_text']
    sleep: vim.options['hints.sleep']
  })

  injectHints = ({wrappers, viewport, pass}) ->
    # See `getComplementaryWrappers` above.
    return unless markerContainer.container

    if wrappers.length == 0
      if pass in ['single', 'second'] and markerContainer.markers.length == 0
        vim.notify(translate('notification.follow.none'))
        vim._enterMode('normal')
    else
      markerContainer.injectHints(wrappers, viewport, pass)

    if pass == 'first'
      vim._run(name, {pass: 'second'}, injectHints)

  vim._run(name, {pass: 'auto'}, injectHints)

helper_follow_clickable = (options, args) ->
  {vim} = args

  callback = (marker, timesLeft, keyStr) ->
    {inTab, inBackground} = options
    {type, elementIndex} = marker.wrapper
    isLast = (timesLeft == 1)
    isLink = (type == 'link')
    {window} = vim

    switch
      when keyStr.startsWith(vim.options['hints.toggle_in_tab'])
        inTab = not inTab
      when keyStr.startsWith(vim.options['hints.toggle_in_background'])
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
          triggeringPrincipal: window.document.nodePrincipal
        }, vim.browser)
        reset()
      )

    # The point of “clicking” scrollable elements is focusing them (which is
    # done above) so that scrolling commands may scroll them. Simulating a click
    # here usually _unfocuses_ the element.
    else if type != 'scrollable'
      vim._run('click_marker_element', {
        elementIndex, type
        browserOffset: vim._getBrowserOffset()
        preventTargetBlank: vim.options.prevent_target_blank
      })

    return not isLast

  name = if options.inTab then 'follow_in_tab' else 'follow'
  helper_follow({name, callback}, args)

commands.follow =
  helper_follow_clickable.bind(null, {inTab: false, inBackground: true})

commands.follow_in_tab =
  helper_follow_clickable.bind(null, {inTab: true, inBackground: true})

commands.follow_in_focused_tab =
  helper_follow_clickable.bind(null, {inTab: true, inBackground: false})

helper_follow_in_window = (options, args) ->
  {vim} = args

  callback = (marker) ->
    vim._focusMarkerElement(marker.wrapper.elementIndex)
    {href} = marker.wrapper
    vim.window.openLinkIn(href, 'window', options) if href
    return false

  helper_follow({name: 'follow_in_tab', callback}, args)

commands.follow_in_window =
  helper_follow_in_window.bind(null, {})

commands.follow_in_private_window =
  helper_follow_in_window.bind(null, {private: true})

commands.follow_multiple = (args) ->
  args.count = Infinity
  commands.follow(args)

commands.follow_copy = (args) ->
  {vim} = args

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

  helper_follow({name: 'follow_copy', callback}, args)

commands.follow_focus = (args) ->
  {vim} = args

  callback = (marker) ->
    vim._focusMarkerElement(marker.wrapper.elementIndex, {select: true})
    return false

  helper_follow({name: 'follow_focus', callback}, args)

commands.open_context_menu = (args) ->
  {vim} = args

  callback = (marker) ->
    {type, elementIndex} = marker.wrapper
    vim._run('click_marker_element', {
      elementIndex, type
      browserOffset: vim._getBrowserOffset()
    })
    return false

  helper_follow({name: 'follow_context', callback}, args)

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
      when utils.isFocusable(element) or element.onclick
        'clickable'

    if complementary
      type = if type then null else 'complementary'

    return unless type

    # `getElementShape(element, -1)` is intentionally _not_ used in the
    # `complementary` run, because it results in tons of useless hints for
    # hidden context menus.
    shape = getElementShape(element)
    return unless shape.nonCoveredPoint

    # The tabs and their close buttons as well as the tab bar scroll arrows get
    # better hints, since switching or closing tabs is the most common use case
    # for the `eb` command.
    isTab = element.classList?.contains('tabbrowser-tab')
    isPrioritized =
      isTab or
      element.classList?.contains('tab-close-button') or
      element.classList?.contains('scrollbutton-up') or
      element.classList?.contains('scrollbutton-down')

    length = markerElements.push(element)
    return {
      type, shape, isTab, isPrioritized,
      combinedArea: shape.area,
      elementIndex: length - 1,
    }

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
          browserOffset = {x: window.screenX, y: window.screenY}
          switch
            when element.localName == 'tab'
              # Only 'mousedown' seems to be able to activate tabs.
              utils.simulateMouseEvents(element, ['mousedown'], browserOffset)
            when element.closest('tab')
              # If `.click()` is used on a tab close button, its tab will be
              # selected first, which might cause the selected tab to change.
              utils.simulateMouseEvents(element, 'click-xul', browserOffset)
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
      hintChars: vim.options['hints.chars']
      adjustZoom: false
      minWeightDiff: 0
      getComplementaryWrappers: (callback) ->
        newWrappers = markableElements.find(
          window, filter.bind(null, {complementary: true})
        )
        callback({wrappers: newWrappers, viewport})
    })
    MarkerContainer.remove(window) # Better safe than sorry.
    markerContainer.container.classList.add('ui')
    window.document.getElementById('main-window').appendChild(
      markerContainer.container
    )

    [firstWrappers, secondWrappers] =
      utils.partition(wrappers, (wrapper) -> wrapper.isPrioritized)

    numChars = markerContainer.alphabet.length
    numPrimary = markerContainer.primaryHintChars.length
    numTabs = firstWrappers.filter(({isTab}) -> isTab).length
    index = 0

    for wrapper in firstWrappers
      if wrapper.isTab
        # Given the hint chars `abc de`, give the tabs weights so that the hints
        # consistently become `a b ca cb cc cd cea ceb cec ced ceea ceeb` and so
        # on. The rule is that the weight of a tab must be larger than the sum
        # of all tabs with a longer hint. We start out at `1` and then use
        # smaller and smaller fractions. This is to make sure that the tabs get
        # consistent hints as the number of tabs or the size of the window
        # changes.
        exponent = (index - numPrimary + 1) // (numChars - 1) + 1
        wrapper.combinedArea = 1 / numChars ** exponent
        index += 1
      else
        # Make sure that the tab close buttons and the tab bar scroll buttons
        # come after all the tabs. Treating them all as the same size is fine.
        # Their sum must be small enough in order not to affect the tab hints.
        # It might look like using `0` is a good idea, but that results in
        # increasingly worse hints the more tab close buttons there are.
        wrapper.combinedArea = 1 / numChars ** numTabs

    # Since most of the best hint characters might be used for the tabs, make
    # sure that all other elements don’t get really bad hints. First, favor
    # larger elements by sorting them. Then, give them all the same weight so
    # that larger elements (such as the location bar, search bar, the web
    # console input and other large areas in the devtools) don’t overpower the
    # smaller ones. The usual “the larger the element, the better the hint” rule
    # doesn’t really apply the same way for browser UI elements as in web pages.
    secondWrappers.sort((a, b) -> b.combinedArea - a.combinedArea)
    for wrapper in secondWrappers
      wrapper.combinedArea = 1

    markerContainer.injectHints(firstWrappers, viewport, 'first')
    markerContainer.injectHints(secondWrappers, viewport, 'second')
    vim._enterMode('hints', {markerContainer, callback, matchText: false})

  else
    vim.notify(translate('notification.follow.none'))

helper_follow_pattern = (type, {vim}) ->
  options = {
    pattern_selector: vim.options.pattern_selector
    pattern_attrs: vim.options.pattern_attrs
    patterns: vim.options["#{type}_patterns"]
  }
  browserOffset = vim._getBrowserOffset()
  vim._run('follow_pattern', {type, browserOffset, options})

commands.follow_previous = helper_follow_pattern.bind(null, 'prev')

commands.follow_next     = helper_follow_pattern.bind(null, 'next')

commands.focus_text_input = ({vim, count}) ->
  vim.markPageInteraction()
  vim._run('focus_text_input', {count})

helper_follow_selectable = ({select}, args) ->
  {vim} = args

  callback = (marker) ->
    vim._run('element_text_select', {
      elementIndex: marker.wrapper.elementIndex
      full: select
      scroll: select
    })
    vim._enterMode('caret', {select})
    return false

  helper_follow({name: 'follow_selectable', callback}, args)

commands.element_text_caret =
  helper_follow_selectable.bind(null, {select: false})

commands.element_text_select =
  helper_follow_selectable.bind(null, {select: true})

commands.element_text_copy = (args) ->
  {vim} = args

  callback = (marker) ->
    helper_copy_marker_element(vim, marker.wrapper.elementIndex, '_selection')
    return false

  helper_follow({name: 'follow_selectable', callback}, args)

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
  if vim.options.find_from_top_of_viewport
    vim._run('find_from_top_of_viewport', {direction}, ->
      callback()
    )
  else
    callback()

helper_find = ({highlight, linksOnly = false}, {vim}) ->
  if findStorage.busy
    # Make sure to enter find mode here, since that’s where `findStorage.busy`
    # is reset to `false` again. Otherwise we can get stuck in the “busy” state.
    vim._enterMode('find')
    return

  helpSearchInput = help.getSearchInput(vim.window)
  if helpSearchInput
    helpSearchInput.select()
    return

  # Important: Enter Find mode immediately. See `onInput` for Find mode.
  findStorage.busy = true
  vim._enterMode('find')

  helper_mark_last_scroll_position(vim)
  vim._run('mark_scroll_position', {
    keyStr: vim.options['scroll.last_find_mark']
    notify: false
  })

  helper_find_from_top_of_viewport(vim, FORWARD, ->
    return unless vim.mode == 'find'
    utils.getFindBar(vim.window.gBrowser).then((findBar) ->
      mode = if linksOnly then findBar.FIND_LINKS else findBar.FIND_NORMAL
      findBar.startFind(mode)
      utils.focusElement(findBar._findField, {select: true})

      return if linksOnly
      return unless highlightButton = findBar.getElement('highlight')
      if highlightButton.checked != highlight
        highlightButton.click()
    )
  )

commands.find = helper_find.bind(null, {highlight: false})

commands.find_highlight_all = helper_find.bind(null, {highlight: true})

commands.find_links_only = helper_find.bind(null, {linksOnly: true})

helper_find_again = (direction, {vim}) ->
  return if findStorage.busy

  utils.getFindBar(vim.window.gBrowser).then((findBar) ->
    if findStorage.lastSearchString.length == 0
      vim.notify(translate('notification.find_again.none'))
      return

    findStorage.busy = true

    helper_mark_last_scroll_position(vim)
    helper_find_from_top_of_viewport(vim, direction, ->
      findBar._findField.value = findStorage.lastSearchString

      # `.onFindResult` is temporarily hacked to be able to know when the
      # asynchronous `.onFindAgainCommand` is done. When PDFs are shown using
      # PDF.js, `.updateControlState` is called instead of `.onFindResult`, so
      # hack that one too.
      originalOnFindResult = findBar.onFindResult
      originalUpdateControlState = findBar.updateControlState

      findBar.onFindResult = (data) ->
        # Prevent the find bar from re-opening if there are no matches.
        data.storeResult = false
        findBar.onFindResult = originalOnFindResult
        findBar.updateControlState = originalUpdateControlState
        findBar.onFindResult(data)
        callback()

      findBar.updateControlState = (args...) ->
        # Firefox inconsistently _doesn’t_ re-open the find bar if there are no
        # matches here, so no need to take care of that in this case.
        findBar.onFindResult = originalOnFindResult
        findBar.updateControlState = originalUpdateControlState
        findBar.updateControlState(args...)
        callback()

      callback = ->
        message = findBar._findStatusDesc.textContent
        vim.notify(message) if message
        findStorage.busy = false

      findBar.onFindAgainCommand(not direction)
    )
  )

commands.find_next     = helper_find_again.bind(null, FORWARD)

commands.find_previous = helper_find_again.bind(null, BACKWARD)



commands.window_new = ({vim}) ->
  vim.window.OpenBrowserWindow()

commands.window_new_private = ({vim}) ->
  vim.window.OpenBrowserWindow({private: true})

commands.enter_mode_ignore = ({vim, blacklist = false}) ->
  type = if blacklist then 'blacklist' else 'explicit'
  vim._enterMode('ignore', {type})

# Quote next keypress (pass it through to the page).
commands.quote = ({vim, count = 1}) ->
  vim._enterMode('ignore', {type: 'explicit', count})

commands.enter_reader_view = ({vim}) ->
  button = vim.window.document.getElementById('reader-mode-button')
  if not button?.hidden
    button.click()
  else
    vim.notify(translate('notification.enter_reader_view.none'))

commands.reload_config_file = ({vim}) ->
  vim._parent.emit('shutdown')
  config.load(vim._parent, {allowDeprecated: false}, (status) -> switch status
    when null
      vim.notify(translate('notification.reload_config_file.none'))
    when true
      vim.notify(translate('notification.reload_config_file.success'))
    else
      vim.notify(translate('notification.reload_config_file.failure'))
  )

commands.edit_blacklist = ({vim}) ->
  url = vim.browser.currentURI.spec
  location = new vim.window.URL(url)
  newPattern = if location.host then "*#{location.host}*" else location.href
  delimiter = '  '
  blacklistString = prefs.get('blacklist')

  if vim._isBlacklisted(url)
    blacklist = parsePrefs.parseSpaceDelimitedString(blacklistString).parsed
    [matching, nonMatching] = utils.partition(blacklist, (string, index) ->
      return vim.options.blacklist[index].test(url)
    )
    newBlacklistString = "
      #{matching.join(delimiter)}\
      #{delimiter.repeat(7)}\
      #{nonMatching.join(delimiter)}
    "
    extraMessage = translate('pref.blacklist.extra.is_blacklisted')
  else
    newBlacklistString = "#{newPattern}#{delimiter}#{blacklistString}"
    extraMessage = translate('pref.blacklist.extra.added', newPattern)

  message = """
    #{translate('pref.blacklist.title')}: #{translate('pref.blacklist.desc')}

    #{extraMessage}
  """

  vim._modal('prompt', [message, newBlacklistString.trim()], (input) ->
    return if input == null
    # Just set the blacklist as if the user had typed it in the Add-ons Manager,
    # and let the regular pref parsing take care of it.
    prefs.set('blacklist', input)
    vim._onLocationChange(url)
  )

commands.help = ({vim}) ->
  help.toggleHelp(vim.window, vim._parent)

commands.esc = ({vim}) ->
  vim._run('esc')
  vim.hideNotification()

  # Firefox does things differently when blurring the location bar, depending on
  # whether the autocomplete popup is open or not. To be consistent, always
  # close the autocomplete popup before blurring.
  vim.window.gURLBar.closePopup()

  utils.blurActiveBrowserElement(vim)
  utils.getFindBar(vim.window.gBrowser).then((findBar) -> findBar.close())

  # Better safe than sorry.
  MarkerContainer.remove(vim.window)
  vim._parent.resetCaretBrowsing()

  unless help.getSearchInput(vim.window)?.getAttribute('focused')
    help.removeHelp(vim.window)

  vim._setFocusType('none') # Better safe than sorry.



module.exports = {
  commands
  findStorage
}
