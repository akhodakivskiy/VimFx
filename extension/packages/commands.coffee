utils = require 'utils'
help  = require 'help'
{ _ } = require 'l10n'
{ getPref
, getComplexPref
, setPref
, isPrefSet
, getFirefoxPref } = require 'prefs'

{ classes: Cc, interfaces: Ci, utils: Cu } = Components

# Open developer toolbar (Default shotrcut: Shift-F2)
command_dev = (vim) ->
  if chromeWindow = utils.getRootWindow vim.window
    chromeWindow.DeveloperToolbar.show(true)
    chromeWindow.DeveloperToolbar.focus()

# Focus the Address Bar
command_focus = (vim) ->
  if chromeWindow = utils.getRootWindow(vim.window)
    chromeWindow.focusAndSelectUrlBar()

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
  callback = (marker) ->
    if url = marker.element.href
      marker.element.focus()
      utils.writeToClipboard(vim.window, url)
    else if utils.isTextInputElement(marker.element)
      utils.writeToClipboard(vim.window, marker.element.value)

  vim.enterMode('hints', callback)

# Focus element
command_marker_focus = (vim) ->
  callback = (marker) -> marker.element.focus()

  vim.enterMode('hints', callback)

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

helper_follow = ({ inTab, multiple }, vim) ->
  callback = (matchedMarker, markers) ->
    matchedMarker.element.focus()
    utils.simulateClick(matchedMarker.element, {metaKey: inTab, ctrlKey: inTab})
    isEditable = utils.isElementEditable(matchedMarker.element)
    if multiple and not isEditable
      # By not resetting immediately one is able to see the last char being matched, which gives
      # some nice visual feedback that you've typed the right char.
      vim.window.setTimeout((-> marker.reset() for marker in markers), 100)
      return true

  vim.enterMode('hints', callback)

# Follow links with hint markers
command_follow = helper_follow.bind(undefined, {inTab: false})

# Follow links in a new Tab with hint markers
command_follow_in_tab = helper_follow.bind(undefined, {inTab: true})

# Follow multiple links with hint markers
command_follow_multiple = helper_follow.bind(undefined, {inTab: true, multiple: true})

helper_follow_pattern = (type, vim) ->
  links = utils.getMarkableElements(vim.window.document, {type: 'action'})
    .filter(utils.isElementVisible)
  patterns = utils.splitListString(getComplexPref("#{ type }_patterns"))
  matchingLink = utils.getBestPatternMatch(patterns, links)

  if matchingLink
    utils.simulateClick(matchingLink, {metaKey: false, ctrlKey: false})

# Follow previous page
command_follow_prev = helper_follow_pattern.bind(undefined, 'prev')

# Follow next page
command_follow_next = helper_follow_pattern.bind(undefined, 'next')

# Go up one level in the URL hierarchy
command_go_up_path = (vim) ->
  path = vim.window.location.pathname
  vim.window.location.pathname = path.replace(/// / [^/]+ /?$ ///, '')

# Go up to root of the URL hierarchy
command_go_to_root = (vim) ->
  vim.window.location.href = vim.window.location.origin

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

findStorage = { lastSearchString: '' }

# Switch into find mode
command_find = (vim, storage) ->
  vim.enterMode('find', { highlight: false })

# Switch into find mode with highlighting
command_find_hl = (vim, storage) ->
  vim.enterMode('find', { highlight: true })

# Search for the last pattern
command_find_next = (vim, storage) ->
  if findBar = utils.getRootWindow(vim.window).gBrowser.getFindBar()
    if findStorage.lastSearchString.length > 0
      findBar._findField.value = findStorage.lastSearchString
      findBar.onFindAgainCommand(false)

# Search for the last pattern backwards
command_find_prev = (vim, storage) ->
  if findBar = utils.getRootWindow(vim.window).gBrowser.getFindBar()
    if findStorage.lastSearchString.length > 0
      findBar._findField.value = findStorage.lastSearchString
      findBar.onFindAgainCommand(true)

command_insert_mode = (vim) ->
  vim.enterMode('insert')

command_Esc = (vim, storage, event) ->
  utils.blurActiveElement(vim.window)

  # Blur active XUL control
  callback = -> event.originalTarget?.ownerDocument?.activeElement?.blur()
  vim.window.setTimeout(callback, 0)

  help.removeHelp(vim.window.document)

  return unless rootWindow = utils.getRootWindow(vim.window)

  rootWindow.DeveloperToolbar.hide()

  rootWindow.gBrowser.getFindBar()?.close()


class Command
  constructor: (@group, @name, @func, keys) ->
    @defaultKeys = keys
    if isPrefSet(@prefName('keys'))
      try @keyValues = JSON.parse(getPref(@prefName('keys')))
    else
      @keyValues = keys

  # Name of the preference for a given property
  prefName: (value) -> "commands.#{ @name }.#{ value }"

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
  new Command('tabs',   'tab_first',              command_tab_first,              ['g,H', 'g,^'])
  new Command('tabs',   'tab_last',               command_tab_last,               ['g,L', 'g,$'])
  new Command('tabs',   'close_tab',              command_close_tab,              ['x'])
  new Command('tabs',   'restore_tab',            command_restore_tab,            ['X'])

  new Command('browse', 'follow',                 command_follow,                 ['f'])
  new Command('browse', 'follow_in_tab',          command_follow_in_tab,          ['F'])
  new Command('browse', 'follow_multiple',        command_follow_multiple,        ['a,f'])
  new Command('browse', 'follow_previous',        command_follow_prev,            ['['])
  new Command('browse', 'follow_next',            command_follow_next,            [']'])
  new Command('browse', 'go_up_path',             command_go_up_path,             ['g,u'])
  new Command('browse', 'go_to_root',             command_go_to_root,             ['g,U'])
  new Command('browse', 'back',                   command_back,                   ['H'])
  new Command('browse', 'forward',                command_forward,                ['L'])

  new Command('misc',   'find',                   command_find,                   ['/'])
  new Command('misc',   'find_hl',                command_find_hl,                ['a,/'])
  new Command('misc',   'find_next',              command_find_next,              ['n'])
  new Command('misc',   'find_prev',              command_find_prev,              ['N'])
  new Command('misc',   'insert_mode',            command_insert_mode,            ['i'])
  new Command('misc',   'help',                   command_help,                   ['?'])
  new Command('misc',   'dev',                    command_dev,                    [':'])

  escapeCommand =
  new Command('misc',   'Esc',                    command_Esc,                    ['Esc'])
]

searchForMatchingCommand = (keys) ->
  for index in [0...keys.length] by 1
    str = keys[index..].join(',')
    for command in commands
      for key in command.keys()
        if key.startsWith(str)
          return {match: true, exact: (key == str), command}

  return {match: false}

isEscCommandKey = (keyStr) -> keyStr in escapeCommand.keys()

isReturnCommandKey = (keyStr) -> keyStr.contains('Return')

exports.commands                  = commands
exports.searchForMatchingCommand  = searchForMatchingCommand
exports.isEscCommandKey           = isEscCommandKey
exports.isReturnCommandKey        = isReturnCommandKey
exports.findStorage               = findStorage
