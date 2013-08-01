utils = require 'utils'
hints = require 'hints'
help  = require 'help'
find  = require 'find'

{ _ } = require 'l10n'
{ getPref
, setPref
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
command_reload_all_foce = (vim) ->
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
command_reload_tab = (vim) ->
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
  help.injectHelp(vim.window.document, commandsHelp)

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

commandGroups =
  'urls':
    'o':        [ command_focus,                  _('help_command_focus') ]
    'p':        [ command_paste,                  _('help_command_paste') ]
    'P':        [ command_paste_tab,              _('help_command_paste_tab') ]
    'y,f':      [ command_marker_yank,            _('help_command_marker_yank') ]
    'v,f':      [ command_marker_focus,           _('help_command_marker_focus') ]
    'y,y':      [ command_yank,                   _('help_command_yank') ]
    'r':        [ command_reload,                 _('help_command_reload') ]
    'R':        [ command_reload_force,           _('help_command_reload_force') ]
    'a,r':      [ command_reload_all,             _('help_command_reload_all') ]
    'a,R':      [ command_reload_all_foce,        _('help_command_reload_all_foce') ]
    's':        [ command_stop,                   _('help_command_stop') ]
    'a,s':      [ command_stop_all,               _('help_command_stop_all') ]
  'nav':
    'g,g':      [ command_scroll_to_top ,         _('help_command_scroll_to_top') ]
    'G':        [ command_scroll_to_bottom,       _('help_command_scroll_to_bottom') ]
    'j|c-e':    [ command_scroll_down,            _('help_command_scroll_down') ]
    'k|c-y':    [ command_scroll_up,              _('help_command_scroll_up') ]
    'h':        [ command_scroll_left,            _('help_command_scroll_left') ]
    'l':        [ command_scroll_right ,          _('help_command_scroll_right') ]
    # Can't use c-u/c-d because  c-u is widely used for viewing sources
    'd':        [ command_scroll_half_page_down,  _('help_command_scroll_half_page_down') ]
    'u':        [ command_scroll_half_page_up,    _('help_command_scroll_half_page_up') ]
    'c-f':      [ command_scroll_page_down,       _('help_command_scroll_page_down') ]
    'c-b':      [ command_scroll_page_up,         _('help_command_scroll_page_up') ]
  'tabs':
    't':        [ command_open_tab,               _('help_command_open_tab') ]
    'J|g,T':    [ command_tab_prev,               _('help_command_tab_prev') ]
    'K|g,t':    [ command_tab_next,               _('help_command_tab_next') ]
    'c-J':      [ command_tab_move_left,          _('help_command_tab_move_left') ]
    'c-K':      [ command_tab_move_right,         _('help_command_tab_move_right') ]
    'g,h':      [ command_home,                   _('help_command_home') ]
    'g,H|g,\^': [ command_tab_first,              _('help_command_tab_first') ]
    'g,L|g,$':  [ command_tab_last,               _('help_command_tab_last') ]
    'x':        [ command_close_tab,              _('help_command_close_tab') ]
    'X':        [ command_reload_tab,             _('help_command_reload_tab') ]
  'browse':
    'f':        [ command_follow,                 _('help_command_follow') ]
    'F':        [ command_follow_in_tab,          _('help_command_follow_in_tab') ]
    'H':        [ command_back,                   _('help_command_back') ]
    'L':        [ command_forward,                _('help_command_forward') ]
  'misc':
    # `.` is added to find command mapping to hack around Russian keyboard layout
    '\.|/':     [ command_find,                   _('help_command_find') ]
    'a,\.|a,/': [ command_find_hl,                _('help_command_find_hl') ]
    'n':        [ command_find_next,              _('help_command_find_next') ]
    'N':        [ command_find_prev,              _('help_command_find_prev') ]
    # `>` is added to help command mapping to hack around Russian keyboard layout
    # See key-utils.coffee for more info
    '?|>':      [ command_help,                   _('help_command_help') ]
    'Esc':      [ command_Esc,                    _('help_command_Esc') ]
    ':':        [ command_dev,                    _('help_command_dev') ]

# Merge groups and split command pipes into individual commands
commands = do (commandGroups) ->
  newCommands = {}
  for group, commandsList of commandGroups
    for keys, command of commandsList
      for key in keys.split('|')
        newCommands[key] = command[0]

  return newCommands

# Extract the help text from the commands preserving groups formation
commandsHelp = do (commandGroups) ->
  helpStrings = {}
  for group, commandsList of commandGroups
    helpGroup = {}
    for keys, command of commandsList
      helpGroup[keys] = command[1]

    helpStrings[group] = helpGroup
  return helpStrings

# Called in hints mode. Will process the char, update and hide/show markers
hintCharHandler = (vim, keyStr, charCode) ->
  if keyStr and charCode > 0
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

exports.hintCharHandler = hintCharHandler
exports.commands        = commands
exports.commandsHelp    = commandsHelp
