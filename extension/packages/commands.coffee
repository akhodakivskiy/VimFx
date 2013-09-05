utils = require 'utils'
hints = require 'hints'
help  = require 'help'
find  = require 'find'

{ _ } = require 'l10n'
{ getPref
, setPref
, isPrefSet
, getFirefoxPref } = require 'prefs'

{ classes: Cc, interfaces: Ci, utils: Cu } = Components

# Opens developer toolbar (Default shotrcut: Shift-F2)
command_dev = (vim) ->
  if chromeWindow = utils.getRootWindow vim.window
    chromeWindow.DeveloperToolbar.show(true)
    chromeWindow.DeveloperToolbar.focus()

# Focus the Address Bar
command_focus = (vim) ->
  if chromeWindow = utils.getRootWindow(vim.window)
    chromeWindow.focusAndSelectUrlBar()
    #
# Focus the Search Bar
command_focus_search = (vim) ->
  if chromeWindow = utils.getRootWindow(vim.window)
    if searchBar = chromeWindow.document.getElementById("searchbar")
      searchBar.select()

# Navigate to the address that is currently stored in the system clipboard
command_paste = (vim) ->
  url = utils.readFromClipboard(vim.window)
  postData = null
  if not utils.isURL(url) and submission = utils.browserSearchSubmission(url)
    url = submission.uri.spec
    { postData } = submission

  if chromeWindow = utils.getRootWindow(vim.window)
    chromeWindow.gBrowser.loadURIWithFlags(url, null, null, null, postData)

# Open new tab and navigate to the address that is currently stored in the system clipboard
command_paste_tab = (vim) ->
  url = utils.readFromClipboard(vim.window)
  postData = null
  if not utils.isURL(url) and submission = utils.browserSearchSubmission(url)
    url = submission.uri.spec
    { postData } = submission

  if chromeWindow = utils.getRootWindow vim.window
    chromeWindow.gBrowser.selectedTab = chromeWindow.gBrowser.addTab(url, null, null, postData, null, false)

# Open new tab and focus the address bar
command_open_tab = (vim) ->
  if chromeWindow = utils.getRootWindow(vim.window)
    chromeWindow.BrowserOpenTab()

# Copy element URL to the clipboard
command_marker_yank = (vim) ->
  markers = hints.injectHints(vim.window.document)
  if markers.length > 0
    cb = (marker) ->
      if url = marker.element.href
        marker.element.focus()
        utils.writeToClipboard(vim.window, url)
      else if utils.isTextInputElement(marker.element)
        utils.writeToClipboard(vim.window, marker.element.value)

    vim.enterHintsMode(markers, cb)

# Focus element
command_marker_focus = (vim) ->
  markers = hints.injectHints(vim.window.document)
  if markers.length > 0
    vim.enterHintsMode(markers, (marker) -> marker.element.focus())

# Copy current URL to the clipboard
command_yank = (vim) ->
  utils.writeToClipboard(vim.window, vim.window.location.toString())

# Reload the page, possibly from cache
command_reload = (vim) ->
  vim.window.location.reload(false)

# Reload the page from the server
command_reload_force = (vim) ->
  vim.window.location.reload(true)

# Reload the page, possibly from cache
command_reload_all = (vim) ->
  if rootWindow = utils.getRootWindow(vim.window)
    if tabs = rootWindow.gBrowser.tabContainer
      for i in [0...tabs.itemCount]
        window = tabs.getItemAtIndex(i).linkedBrowser.contentWindow
        window.location.reload(false)

# Reload the page from the server
command_reload_all_force = (vim) ->
  if rootWindow = utils.getRootWindow(vim.window)
    if tabs = rootWindow.gBrowser.tabContainer
      for i in [0...tabs.itemCount]
        window = tabs.getItemAtIndex(i).linkedBrowser.contentWindow
        window.location.reload(true)

command_stop = (vim) ->
  vim.window.stop()

command_stop_all = (vim) ->
  if rootWindow = utils.getRootWindow(vim.window)
    if tabs = rootWindow.gBrowser.tabContainer
      for i in [0...tabs.itemCount]
        window = tabs.getItemAtIndex(i).linkedBrowser.contentWindow
        window.stop()

# Scroll to the top of the page
command_scroll_to_top = (vim) ->
  for i in [0...1000]
    utils.simulateWheel(vim.window, 0, -1, utils.WHEEL_MODE_PAGE)

# Scroll to the bottom of the page
command_scroll_to_bottom = (vim) ->
  for i in [0...1000]
    utils.simulateWheel(vim.window, 0, 1, utils.WHEEL_MODE_PAGE)

# Scroll down a bit
command_scroll_down = (vim) ->
  utils.simulateWheel(vim.window, 0, getPref('scroll_step_lines'), utils.WHEEL_MODE_LINE)

# Scroll up a bit
command_scroll_up = (vim) ->
  utils.simulateWheel(vim.window, 0, -getPref('scroll_step_lines'), utils.WHEEL_MODE_LINE)

# Scroll left a bit
command_scroll_left = (vim) ->
  utils.simulateWheel(vim.window, -getPref('scroll_step_lines'), 0, utils.WHEEL_MODE_LINE)

# Scroll right a bit
command_scroll_right = (vim) ->
  utils.simulateWheel(vim.window, getPref('scroll_step_lines'), 0, utils.WHEEL_MODE_LINE)

# Scroll down half a page
command_scroll_half_page_down = (vim) ->
  utils.simulateWheel(vim.window, 0, 0.5, utils.WHEEL_MODE_PAGE)

# Scroll up half a page
command_scroll_half_page_up = (vim) ->
  utils.simulateWheel(vim.window, 0, -0.5, utils.WHEEL_MODE_PAGE)

# Scroll down full a page
command_scroll_page_down = (vim) ->
  utils.simulateWheel(vim.window, 0, 1, utils.WHEEL_MODE_PAGE)

# Scroll up full a page
command_scroll_page_up = (vim) ->
  utils.simulateWheel(vim.window, 0, -1, utils.WHEEL_MODE_PAGE)

# Activate previous tab
command_tab_prev = (vim) ->
  if rootWindow = utils.getRootWindow(vim.window)
    rootWindow.gBrowser.tabContainer.advanceSelectedTab(-1, true)

# Activate next tab
command_tab_next = (vim) ->
  if rootWindow = utils.getRootWindow(vim.window)
    rootWindow.gBrowser.tabContainer.advanceSelectedTab(1, true)

command_home = (vim) ->
  url = getFirefoxPref('browser.startup.homepage')
  if chromeWindow = utils.getRootWindow(vim.window)
    chromeWindow.gBrowser.loadURIWithFlags(url, null, null, null, null)

# Go to the first tab
command_tab_first = (vim) ->
  if rootWindow = utils.getRootWindow(vim.window)
    rootWindow.gBrowser.tabContainer.selectedIndex = 0

# Go to the last tab
command_tab_last = (vim) ->
  if rootWindow = utils.getRootWindow(vim.window)
    itemCount = rootWindow.gBrowser.tabContainer.itemCount
    rootWindow.gBrowser.tabContainer.selectedIndex = itemCount - 1

# Go back in history
command_back = (vim) ->
  vim.window.history.back()

# Go forward in history
command_forward = (vim) ->
  vim.window.history.forward()

# Close current tab
command_close_tab = (vim) ->
  if rootWindow = utils.getRootWindow(vim.window)
    unless rootWindow.gBrowser.selectedTab.pinned
      rootWindow.gBrowser.removeCurrentTab()

# Restore last closed tab
command_restore_tab = (vim) ->
  if rootWindow = utils.getRootWindow(vim.window)
    ss = utils.getSessionStore()
    if ss and ss.getClosedTabCount(rootWindow) > 0
      ss.undoCloseTab(rootWindow, 0)

# Follow links with hint markers
command_follow = (vim) ->
  if document = vim.window.document
    markers = hints.injectHints(document)
    if markers.length > 0
      # This callback will be called with the selected marker as argument
      cb = (marker) ->
        marker.element.focus()
        utils.simulateClick(marker.element)

      vim.enterHintsMode(markers, cb)

# Follow links in a new Tab with hint markers
command_follow_in_tab = (vim) ->
  markers = hints.injectHints(vim.window.document)
  if markers.length > 0
    # This callback will be called with the selected marker as argument
    cb = (marker) ->
      marker.element.focus()
      utils.simulateClick(marker.element, { metaKey: true, ctrlKey: true })

    vim.enterHintsMode(markers, cb)

# Move current tab to the left
command_tab_move_left = (vim) ->
  if gBrowser = utils.getRootWindow(vim.window)?.gBrowser
    if tab = gBrowser.selectedTab
      index = gBrowser.tabContainer.selectedIndex
      total = gBrowser.tabContainer.itemCount

      # `total` is added to deal with negative offset
      gBrowser.moveTabTo(tab, (total + index - 1) % total)

# Move current tab to the right
command_tab_move_right = (vim) ->
  if gBrowser = utils.getRootWindow(vim.window)?.gBrowser
    if tab = gBrowser.selectedTab
      index = gBrowser.tabContainer.selectedIndex
      total = gBrowser.tabContainer.itemCount

      gBrowser.moveTabTo(tab, (index + 1) % total)

# Display the Help Dialog
command_help = (vim) ->
  help.injectHelp(vim.window.document, commands)

# Switch into find mode
command_find = (vim) ->
  find.injectFind vim.window.document, (findStr, startFindRng) ->
    # Reset region and find string if new find stirng has arrived
    if vim.findStr != findStr
      [vim.findStr, vim.findRng] = [findStr, startFindRng]
    # Perform forward find and store found region
    return vim.findRng = find.find(vim.window, vim.findStr, vim.findRng, find.DIRECTION_FORWARDS)

# Switch into find mode with highlighting
command_find_hl = (vim) ->
  find.injectFind vim.window.document, (findStr) ->
    # Reset region and find string if new find stirng has arrived
    return find.highlight(vim.window, findStr)

# Search for the last pattern
command_find_next = (vim) ->
  if vim.findStr.length > 0
    vim.findRng = find.find(vim.window, vim.findStr, vim.findRng, find.DIRECTION_FORWARDS, true)

# Search for the last pattern backwards
command_find_prev = (vim) ->
  if vim.findStr.length > 0
    vim.findRng = find.find(vim.window, vim.findStr, vim.findRng, find.DIRECTION_BACKWARDS, true)

# Close the Help dialog and cancel the pending hint marker action
command_Esc = (vim) ->
  # Blur active element if it's editable. Other elements
  # aren't blurred - we don't want to interfere with
  # the browser too much
  activeElement = vim.window.document.activeElement
  if utils.isElementEditable(activeElement)
    activeElement.blur()

  #Remove Find input
  find.removeFind(vim.window.document)

  # Remove hints
  hints.removeHints(vim.window.document)

  # Hide help dialog
  help.removeHelp(vim.window.document)

  # Finally enter normal mode
  vim.enterNormalMode()

  if not getPref('leave_dt_on_esc')
    if chromeWindow = utils.getRootWindow(vim.window)
      chromeWindow.DeveloperToolbar.hide()

class Command
  constructor: (@group, @name, @func, keys) ->
    @defaultKeys = keys
    if isPrefSet(@prefName('keys'))
      try @keyValues = JSON.parse(getPref(@prefName('keys')))
    else
      @keyValues = keys

  # Check if this command may match given string if more chars are added
  mayMatch: (value) ->
    return @keys.reduce(((m, v) -> m or v.indexOf(value) == 0), false)

  # Check is this command matches given string
  match: (value) ->
    return @keys.reduce(((m, v) -> m or v == value), false)

  # Name of the preference for a given property
  prefName: (value) -> "commands.#{ @name }.#{ value }"

  assign: (value) ->
    @keys = value or @defaultKeys
    setPref(@prefName('keys'), value and JSON.stringify(value))

  enabled: (value) ->
    if value is undefined
      return getPref(@prefName('enabled'), true)
    else
      setPref(@prefName('enabled'), !!value)

  keys: (value) ->
    if value is undefined
      return @keyValues
    else
      @keyValues = value or @defaultKeyValues
      setPref(@prefName('keys'), value and JSON.stringify(value))

  help: -> _("help_command_#{ @name }")

commands = [
  new Command('urls',   'focus',                  command_focus,                  ['o'])
  new Command('urls',   'focus_search',           command_focus_search,           ['O'])
  new Command('urls',   'paste',                  command_paste,                  ['p'])
  new Command('urls',   'paste_tab',              command_paste_tab,              ['P'])
  new Command('urls',   'marker_yank',            command_marker_yank,            ['y,f'])
  new Command('urls',   'marker_focus',           command_marker_focus,           ['v,f'])
  new Command('urls',   'yank',                   command_yank,                   ['y,y'])
  new Command('urls',   'reload',                 command_reload,                 ['r'])
  new Command('urls',   'reload_force',           command_reload_force,           ['R'])
  new Command('urls',   'reload_all',             command_reload_all,             ['a,r'])
  new Command('urls',   'reload_all_force',       command_reload_all_force,       ['a,R'])
  new Command('urls',   'stop',                   command_stop,                   ['s'])
  new Command('urls',   'stop_all',               command_stop_all,               ['a,s'])

  new Command('nav',    'scroll_to_top',          command_scroll_to_top ,         ['g,g'])
  new Command('nav',    'scroll_to_bottom',       command_scroll_to_bottom,       ['G'])
  new Command('nav',    'scroll_down',            command_scroll_down,            ['j', 'c-e'])
  new Command('nav',    'scroll_up',              command_scroll_up,              ['k', 'c-y'])
  new Command('nav',    'scroll_left',            command_scroll_left,            ['h'])
  new Command('nav',    'scroll_right',           command_scroll_right ,          ['l'])
  new Command('nav',    'scroll_half_page_down',  command_scroll_half_page_down,  ['d'])
  new Command('nav',    'scroll_half_page_up',    command_scroll_half_page_up,    ['u'])
  new Command('nav',    'scroll_page_down',       command_scroll_page_down,       ['c-f'])
  new Command('nav',    'scroll_page_up',         command_scroll_page_up,         ['c-b'])

  new Command('tabs',   'open_tab',               command_open_tab,               ['t'])
  new Command('tabs',   'tab_prev',               command_tab_prev,               ['J', 'g,T'])
  new Command('tabs',   'tab_next',               command_tab_next,               ['K', 'g,t'])
  new Command('tabs',   'tab_move_left',          command_tab_move_left,          ['c-J'])
  new Command('tabs',   'tab_move_right',         command_tab_move_right,         ['c-K'])
  new Command('tabs',   'home',                   command_home,                   ['g,h'])
  new Command('tabs',   'tab_first',              command_tab_first,              ['g,H', 'g,\^'])
  new Command('tabs',   'tab_last',               command_tab_last,               ['g,L', 'g,$'])
  new Command('tabs',   'close_tab',              command_close_tab,              ['x'])
  new Command('tabs',   'restore_tab',            command_restore_tab,            ['X'])

  new Command('browse', 'follow',                 command_follow,                 ['f'])
  new Command('browse', 'follow_in_tab',          command_follow_in_tab,          ['F'])
  new Command('browse', 'back',                   command_back,                   ['H'])
  new Command('browse', 'forward',                command_forward,                ['L'])

  new Command('misc',   'find',                   command_find,                   ['/'])
  new Command('misc',   'find_hl',                command_find_hl,                ['a,/'])
  new Command('misc',   'find_next',              command_find_next,              ['n'])
  new Command('misc',   'find_prev',              command_find_prev,              ['N'])
  new Command('misc',   'help',                   command_help,                   ['?'])
  new Command('misc',   'Esc',                    command_Esc,                    ['Esc'])
  new Command('misc',   'dev',                    command_dev,                    [':'])
]

# Called in hints mode. Will process the char, update and hide/show markers
hintCharHandler = (vim, keyStr) ->
  if keyStr == 'Space'
    rotateOverlappingMarkers(vim.markers, true)
  else if keyStr == 'Shift-Space'
    rotateOverlappingMarkers(vim.markers, false)
  else if keyStr
    # Get char and escape it to avoid problems with String.search
    key = utils.regexpEscape(keyStr)

    # First do a pre match - count how many markers will match with the new character entered
    if vim.markers.reduce(((v, marker) -> v or marker.willMatch(key)), false)
      for marker in vim.markers
        marker.matchHintChar(key)

        if marker.isMatched()
          # Add element features to the bloom filter
          marker.reward()
          vim.cb(marker)
          hints.removeHints(vim.window.document)
          vim.enterNormalMode()
          break

findCommand = (keys) ->
  for i in [0...keys.length]
    str = keys[i..].join(',')
    for cmd in commands
      for key in cmd.keys()
        if key == str and cmd.enabled()
          return cmd

maybeCommand = (keys) ->
  for i in [0...keys.length]
    str = keys[i..].join(',')
    for cmd in commands
      for key in cmd.keys()
        if key.indexOf(str) == 0 and cmd.enabled()
          return true

# Finds all stacks of markers that overlap each other (by using `getStackFor`) (#1), and rotates
# their `z-index`:es (#2), thus alternating which markers are visible.
rotateOverlappingMarkers = (originalMarkers, forward) ->
  # Shallow working copy. This is necessary since `markers` will be mutated and eventually empty.
  markers = originalMarkers[..]

  # (#1)
  stacks = (getStackFor(markers.pop(), markers) while markers.length > 0)

  # (#2)
  # Stacks of length 1 don't participate in any overlapping, and can therefore be skipped.
  for stack in stacks when stack.length > 1
    # This sort is not required, but makes the rotation more predictable.
    stack.sort((a, b) -> a.markerElement.style.zIndex - b.markerElement.style.zIndex)

    # Array of z indices
    indexStack = (m.markerElement.style.zIndex for m in stack)
    # Shift the array of indices one item forward or back
    if forward
      indexStack.unshift(indexStack.pop())
    else
      indexStack.push(indexStack.shift())

    for marker, index in stack
      marker.markerElement.style.setProperty('z-index', indexStack[index], 'important')

# Get an array containing `marker` and all markers that overlap `marker`, if any, which is called a
# "stack". All markers in the returned stack are spliced out from `markers`, thus mutating it.
getStackFor = (marker, markers) ->
  stack = [marker]

  { top, bottom, left, right } = marker.position

  index = 0
  while index < markers.length
    nextMarker = markers[index]

    { top: nextTop, bottom: nextBottom, left: nextLeft, right: nextRight } = nextMarker.position
    overlapsVertically   = (nextBottom >= top  and nextTop  <= bottom)
    overlapsHorizontally = (nextRight  >= left and nextLeft <= right)

    if overlapsVertically and overlapsHorizontally
      # Also get all markers overlapping this one
      markers.splice(index, 1)
      stack = stack.concat(getStackFor(nextMarker, markers))
    else
      # Continue the search
      index++

  return stack

exports.hintCharHandler = hintCharHandler
exports.findCommand     = findCommand
exports.maybeCommand    = maybeCommand
exports.commands        = commands
