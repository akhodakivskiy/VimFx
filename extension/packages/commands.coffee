utils = require 'utils'
help  = require 'help'
{ _ } = require 'l10n'
{ getPref
, getComplexPref
, setPref
, isPrefSet } = require 'prefs'

{ classes: Cc, interfaces: Ci, utils: Cu } = Components

# “Selecting an element” means “focusing and selecting the text, if any, of an
# element”.

# Select the Address Bar.
command_focus = (vim) ->
  # This function works even if the Address Bar has been removed.
  vim.rootWindow.focusAndSelectUrlBar()

# Select the Search Bar.
command_focus_search = (vim) ->
  # The `.webSearch()` method opens a search engine in a tab if the Search Bar
  # has been removed. Therefore we first check if it exists.
  if vim.rootWindow.BrowserSearch.searchBar
    vim.rootWindow.BrowserSearch.webSearch()

helper_paste = (vim) ->
  url = utils.readFromClipboard(vim.window)
  postData = null
  if not utils.isURL(url) and submission = utils.browserSearchSubmission(url)
    url = submission.uri.spec
    { postData } = submission
  return {url, postData}

# Go to or search for the contents of the system clipboard.
command_paste = (vim) ->
  { url, postData } = helper_paste(vim)
  vim.rootWindow.gBrowser.loadURIWithFlags(url, null, null, null, postData)

# Go to or search for the contents of the system clipboard in a new tab.
command_paste_tab = (vim) ->
  { url, postData } = helper_paste(vim)
  vim.rootWindow.gBrowser.selectedTab =
    vim.rootWindow.gBrowser.addTab(url, null, null, postData, null, false)

# Copy the URL or text of a marker element to the system clipboard.
command_marker_yank = (vim) ->
  callback = (marker) ->
    if url = marker.element.href
      marker.element.focus()
      utils.writeToClipboard(url)
    else if utils.isTextInputElement(marker.element)
      utils.writeToClipboard(marker.element.value)

  vim.enterMode('hints', callback)

# Focus element.
command_marker_focus = (vim) ->
  callback = (marker) -> marker.element.focus()

  vim.enterMode('hints', callback)

# Copy the current URL to the system clipboard.
command_yank = (vim) ->
  utils.writeToClipboard(vim.window.location.href)

# Reload the current tab, possibly from cache.
command_reload = (vim) ->
  vim.rootWindow.BrowserReload()

# Reload the current tab, skipping cache.
command_reload_force = (vim) ->
  vim.rootWindow.BrowserReloadSkipCache()

# Reload all tabs, possibly from cache.
command_reload_all = (vim) ->
  vim.rootWindow.gBrowser.reloadAllTabs()

# Reload all tabs, skipping cache.
command_reload_all_force = (vim) ->
  for tab in vim.rootWindow.gBrowser.visibleTabs
    window = tab.linkedBrowser.contentWindow
    window.location.reload(true)

# Stop loading the current tab.
command_stop = (vim) ->
  vim.window.stop()

# Stop loading all tabs.
command_stop_all = (vim) ->
  for tab in vim.rootWindow.gBrowser.visibleTabs
    window = tab.linkedBrowser.contentWindow
    window.stop()

# Scroll to the top of the page.
command_scroll_to_top = (vim) ->
  vim.rootWindow.goDoCommand('cmd_scrollTop')

# Scroll to the bottom of the page.
command_scroll_to_bottom = (vim) ->
  vim.rootWindow.goDoCommand('cmd_scrollBottom')

# Scroll down a bit.
command_scroll_down = (vim, event, count) ->
  step = getPref('scroll_step_lines') * count
  utils.simulateWheel(vim.window, 0, +step, utils.WHEEL_MODE_LINE)

# Scroll up a bit.
command_scroll_up = (vim, event, count) ->
  step = getPref('scroll_step_lines') * count
  utils.simulateWheel(vim.window, 0, -step, utils.WHEEL_MODE_LINE)

# Scroll left a bit.
command_scroll_left = (vim, event, count) ->
  step = getPref('scroll_step_lines') * count
  utils.simulateWheel(vim.window, -step, 0, utils.WHEEL_MODE_LINE)

# Scroll right a bit.
command_scroll_right = (vim, event, count) ->
  step = getPref('scroll_step_lines') * count
  utils.simulateWheel(vim.window, +step, 0, utils.WHEEL_MODE_LINE)

# Scroll down half a page.
command_scroll_half_page_down = (vim) ->
  utils.simulateWheel(vim.window, 0, +0.5, utils.WHEEL_MODE_PAGE)

# Scroll up half a page.
command_scroll_half_page_up = (vim) ->
  utils.simulateWheel(vim.window, 0, -0.5, utils.WHEEL_MODE_PAGE)

# Scroll down full a page.
command_scroll_page_down = (vim) ->
  utils.simulateWheel(vim.window, 0, +1, utils.WHEEL_MODE_PAGE)

# Scroll up full a page.
command_scroll_page_up = (vim) ->
  utils.simulateWheel(vim.window, 0, -1, utils.WHEEL_MODE_PAGE)

# Open a new tab and select the Address Bar.
command_open_tab = (vim) ->
  vim.rootWindow.BrowserOpenTab()

helper_switch_tab = (direction, vim, event, count) ->
  { gBrowser } = vim.rootWindow

  if count == 1
    gBrowser.tabContainer.advanceSelectedTab(direction, wrap = true)
  else
    currentIndex = gBrowser.visibleTabs.indexOf(gBrowser.selectedTab)

    targetIndex = currentIndex + count * direction
    targetIndex = Math.max(0, targetIndex)
    targetIndex = Math.min(targetIndex, gBrowser.visibleTabs.length - 1)

    gBrowser.selectTabAtIndex(targetIndex)

# Switch to the previous tab.
command_tab_prev = helper_switch_tab.bind(undefined, -1)

# Switch to the next tab.
command_tab_next = helper_switch_tab.bind(undefined, +1)

# Move the current tab backward.
command_tab_move_left = (vim) ->
  { gBrowser } = vim.rootWindow
  lastIndex = gBrowser.tabContainer.selectedIndex
  gBrowser.moveTabBackward()
  if gBrowser.tabContainer.selectedIndex == lastIndex
    gBrowser.moveTabToEnd()

# Move the current tab forward.
command_tab_move_right = (vim) ->
  { gBrowser } = vim.rootWindow
  lastIndex = gBrowser.tabContainer.selectedIndex
  gBrowser.moveTabForward()
  if gBrowser.tabContainer.selectedIndex == lastIndex
    gBrowser.moveTabToStart()

# Load the home page.
command_home = (vim) ->
  vim.rootWindow.BrowserHome()

# Switch to the first tab.
command_tab_first = (vim) ->
  vim.rootWindow.gBrowser.selectTabAtIndex(0)

# Switch to the last tab.
command_tab_last = (vim) ->
  vim.rootWindow.gBrowser.selectTabAtIndex(-1)

# Close current tab.
command_close_tab = (vim, event, count) ->
  { gBrowser } = vim.rootWindow
  currentIndex = gBrowser.visibleTabs.indexOf(gBrowser.selectedTab)
  for tab in gBrowser.visibleTabs[currentIndex...(currentIndex + count)]
    gBrowser.removeTab(tab)

# Restore last closed tab.
command_restore_tab = (vim, event, count) ->
  vim.rootWindow.undoCloseTab() for idx in [1..count]

helper_follow = ({ inTab, multiple }, vim, event, count) ->
  callback = (matchedMarker, markers) ->
    if matchedMarker.element.target == '_blank'
      targetReset = matchedMarker.element.target
      matchedMarker.element.target = ''

    matchedMarker.element.focus()

    _inTab = if count > 1 then true else inTab
    utils.simulateClick(matchedMarker.element, {metaKey: _inTab, ctrlKey: _inTab})

    matchedMarker.element.target = targetReset if targetReset

    count -= 1
    isEditable = utils.isElementEditable(matchedMarker.element)
    if (multiple or count > 0) and not isEditable
      # By not resetting immediately one is able to see the last char being
      # matched, which gives some nice visual feedback that you've typed the
      # right char.
      vim.window.setTimeout((-> marker.reset() for marker in markers), 100)
      return true

  vim.enterMode('hints', callback)

# Follow links with hint markers.
command_follow = helper_follow.bind(undefined, {inTab: false})

# Follow links in a new Tab with hint markers.
command_follow_in_tab = helper_follow.bind(undefined, {inTab: true})

# Follow multiple links with hint markers.
command_follow_multiple = helper_follow.bind(undefined, {inTab: true, multiple: true})

helper_follow_pattern = do ->
  # Search for the prev/next patterns in the following attributes of the
  # element. `rel` should be kept as the first attribute, since the standard
  # way of marking up prev/next links (`rel="prev"` and `rel="next"`) should be
  # favored. Even though some of these attributes only allow a fixed set of
  # keywords, we pattern-match them anyways since lots of sites don’t follow
  # the spec and use the attributes arbitrarily.
  attrs = ['rel', 'role', 'data-tooltip', 'aria-label']

  return (type, vim) ->
    links = utils.getMarkableElements(vim.window.document, {type: 'action'})
      .filter(utils.isElementVisible)

    patterns = utils.splitListString(getComplexPref("#{ type }_patterns"))

    if matchingLink = utils.getBestPatternMatch(patterns, attrs, links)
      utils.simulateClick(matchingLink, {metaKey: false, ctrlKey: false})

# Follow previous page.
command_follow_prev = helper_follow_pattern.bind(undefined, 'prev')

# Follow next page.
command_follow_next = helper_follow_pattern.bind(undefined, 'next')

# Go up one level in the URL hierarchy.
command_go_up_path = (vim) ->
  path = vim.window.location.pathname
  vim.window.location.pathname = path.replace(/// / [^/]+ /?$ ///, '')

# Go up to root of the URL hierarchy.
command_go_to_root = (vim) ->
  vim.window.location.href = vim.window.location.origin

# Go back in history.
command_back = (vim) ->
  vim.rootWindow.BrowserBack()

# Go forward in history.
command_forward = (vim) ->
  vim.rootWindow.BrowserForward()

findStorage = {lastSearchString: ''}

helper_find = (highlight, vim) ->
  findBar = vim.rootWindow.gBrowser.getFindBar()

  findBar.onFindCommand()
  findBar._findField.focus()
  findBar._findField.select()

  return unless highlightButton = findBar.getElement('highlight')
  if highlightButton.checked != highlight
    highlightButton.click()

# Open the find bar, making sure that hightlighting is off.
command_find = helper_find.bind(undefined, false)

# Open the find bar, making sure that hightlighting is on.
command_find_hl = helper_find.bind(undefined, true)

helper_find_again = (direction, vim) ->
  findBar = vim.rootWindow.gBrowser.getFindBar()
  if findStorage.lastSearchString.length > 0
    findBar._findField.value = findStorage.lastSearchString
    findBar.onFindAgainCommand(direction)

# Search for the last pattern.
command_find_next = helper_find_again.bind(undefined, false)

# Search for the last pattern backwards.
command_find_prev = helper_find_again.bind(undefined, true)

# Enter insert mode.
command_insert_mode = (vim) ->
  vim.enterMode('insert')

# Display the Help Dialog.
command_help = (vim) ->
  help.injectHelp(vim.window.document, commands)

# Open and select the Developer Toolbar.
command_dev = (vim) ->
  vim.rootWindow.DeveloperToolbar.show(true) # focus

command_Esc = (vim, event) ->
  utils.blurActiveElement(vim.window)

  # Blur active XUL control.
  callback = -> event.originalTarget?.ownerDocument?.activeElement?.blur()
  vim.window.setTimeout(callback, 0)

  help.removeHelp(vim.window.document)

  vim.rootWindow.DeveloperToolbar.hide()

  vim.rootWindow.gBrowser.getFindBar().close()

  vim.rootWindow.TabView.hide()


class Command
  constructor: (@group, @name, @func, keys) ->
    @defaultKeys = keys
    if isPrefSet(@prefName('keys'))
      try @keyValues = JSON.parse(getPref(@prefName('keys')))
    else
      @keyValues = keys

  # Name of the preference for a given property.
  prefName: (value) -> "commands.#{ @name }.#{ value }"

  keys: (value) ->
    if value is undefined
      return @keyValues
    else
      @keyValues = value or @defaultKeyValues
      setPref(@prefName('keys'), value and JSON.stringify(value))

  help: -> _("help_command_#{ @name }")

commands = [
  new Command('urls',   'focus',                 command_focus,                 ['o'])
  new Command('urls',   'focus_search',          command_focus_search,          ['O'])
  new Command('urls',   'paste',                 command_paste,                 ['p'])
  new Command('urls',   'paste_tab',             command_paste_tab,             ['P'])
  new Command('urls',   'marker_yank',           command_marker_yank,           ['y,f'])
  new Command('urls',   'marker_focus',          command_marker_focus,          ['v,f'])
  new Command('urls',   'yank',                  command_yank,                  ['y,y'])
  new Command('urls',   'reload',                command_reload,                ['r'])
  new Command('urls',   'reload_force',          command_reload_force,          ['R'])
  new Command('urls',   'reload_all',            command_reload_all,            ['a,r'])
  new Command('urls',   'reload_all_force',      command_reload_all_force,      ['a,R'])
  new Command('urls',   'stop',                  command_stop,                  ['s'])
  new Command('urls',   'stop_all',              command_stop_all,              ['a,s'])

  new Command('nav',    'scroll_to_top',         command_scroll_to_top ,        ['g,g'])
  new Command('nav',    'scroll_to_bottom',      command_scroll_to_bottom,      ['G'])
  new Command('nav',    'scroll_down',           command_scroll_down,           ['j', 'c-e'])
  new Command('nav',    'scroll_up',             command_scroll_up,             ['k', 'c-y'])
  new Command('nav',    'scroll_left',           command_scroll_left,           ['h'])
  new Command('nav',    'scroll_right',          command_scroll_right ,         ['l'])
  new Command('nav',    'scroll_half_page_down', command_scroll_half_page_down, ['d'])
  new Command('nav',    'scroll_half_page_up',   command_scroll_half_page_up,   ['u'])
  new Command('nav',    'scroll_page_down',      command_scroll_page_down,      ['c-f'])
  new Command('nav',    'scroll_page_up',        command_scroll_page_up,        ['c-b'])

  new Command('tabs',   'open_tab',              command_open_tab,              ['t'])
  new Command('tabs',   'tab_prev',              command_tab_prev,              ['J', 'g,T'])
  new Command('tabs',   'tab_next',              command_tab_next,              ['K', 'g,t'])
  new Command('tabs',   'tab_move_left',         command_tab_move_left,         ['c-J'])
  new Command('tabs',   'tab_move_right',        command_tab_move_right,        ['c-K'])
  new Command('tabs',   'home',                  command_home,                  ['g,h'])
  new Command('tabs',   'tab_first',             command_tab_first,             ['g,H', 'g,^'])
  new Command('tabs',   'tab_last',              command_tab_last,              ['g,L', 'g,$'])
  new Command('tabs',   'close_tab',             command_close_tab,             ['x'])
  new Command('tabs',   'restore_tab',           command_restore_tab,           ['X'])

  new Command('browse', 'follow',                command_follow,                ['f'])
  new Command('browse', 'follow_in_tab',         command_follow_in_tab,         ['F'])
  new Command('browse', 'follow_multiple',       command_follow_multiple,       ['a,f'])
  new Command('browse', 'follow_previous',       command_follow_prev,           ['['])
  new Command('browse', 'follow_next',           command_follow_next,           [']'])
  new Command('browse', 'go_up_path',            command_go_up_path,            ['g,u'])
  new Command('browse', 'go_to_root',            command_go_to_root,            ['g,U'])
  new Command('browse', 'back',                  command_back,                  ['H'])
  new Command('browse', 'forward',               command_forward,               ['L'])

  new Command('misc',   'find',                  command_find,                  ['/'])
  new Command('misc',   'find_hl',               command_find_hl,               ['a,/'])
  new Command('misc',   'find_next',             command_find_next,             ['n'])
  new Command('misc',   'find_prev',             command_find_prev,             ['N'])
  new Command('misc',   'insert_mode',           command_insert_mode,           ['i'])
  new Command('misc',   'help',                  command_help,                  ['?'])
  new Command('misc',   'dev',                   command_dev,                   [':'])

  escapeCommand =
  new Command('misc',   'Esc',                   command_Esc,                   ['Esc'])
]

searchForMatchingCommand = (keys) ->
  for index in [0...keys.length] by 1
    str = keys[index..].join(',')
    for command in commands
      for key in command.keys()
        # The following hack is a workaround for the issue where letter `c` is
        # considered a start of command with control modifier `c-xxx`.
        if "#{ key },".startsWith("#{ str },")
          numbers = keys[0..index].join('').match(/[1-9]\d*/g)

          # When letter `0` follows after a number, it is considered as number `0`
          # instead of a valid command.
          continue if key == '0' and numbers

          count = parseInt(numbers[numbers.length - 1], 10) if numbers
          count = if count > 1 then count else 1

          return {match: true, exact: (key == str), command, count}

  return {match: false}

isEscCommandKey = (keyStr) -> keyStr in escapeCommand.keys()

exports.commands                  = commands
exports.searchForMatchingCommand  = searchForMatchingCommand
exports.isEscCommandKey           = isEscCommandKey
exports.findStorage               = findStorage
