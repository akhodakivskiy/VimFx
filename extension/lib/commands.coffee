###
# Copyright Anton Khodakivskiy 2012, 2013, 2014.
# Copyright Simon Lydell 2013, 2014.
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

notation   = require('vim-like-key-notation')
{ Marker } = require('./marker')
legacy     = require('./legacy')
utils      = require('./utils')
help       = require('./help')
_          = require('./l10n')
{ getPref
, setPref
, isPrefSet } = require('./prefs')

{ isProperLink, isTextInputElement, isContentEditable, isDataApp } = utils

{ classes: Cc, interfaces: Ci, utils: Cu } = Components

XULDocument  = Ci.nsIDOMXULDocument

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
  url = vim.rootWindow.readFromClipboard()
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
command_scroll_half_page_down = (vim, event, count) ->
  utils.simulateWheel(vim.window, 0, +0.5 * count, utils.WHEEL_MODE_PAGE)

# Scroll up half a page.
command_scroll_half_page_up = (vim, event, count) ->
  utils.simulateWheel(vim.window, 0, -0.5 * count, utils.WHEEL_MODE_PAGE)

# Scroll down full a page.
command_scroll_page_down = (vim, event, count) ->
  utils.simulateWheel(vim.window, 0, +1 * count, utils.WHEEL_MODE_PAGE)

# Scroll up full a page.
command_scroll_page_up = (vim, event, count) ->
  utils.simulateWheel(vim.window, 0, -1 * count, utils.WHEEL_MODE_PAGE)

# Open a new tab and select the Address Bar.
command_open_tab = (vim) ->
  vim.rootWindow.BrowserOpenTab()

absoluteTabIndex = (relativeIndex, gBrowser) ->
  tabs = gBrowser.visibleTabs
  { selectedTab } = gBrowser

  currentIndex  = tabs.indexOf(selectedTab)
  absoluteIndex = currentIndex + relativeIndex
  numTabs       = tabs.length

  wrap = (Math.abs(relativeIndex) == 1)
  if wrap
    absoluteIndex %%= numTabs
  else
    absoluteIndex = Math.max(0, absoluteIndex)
    absoluteIndex = Math.min(absoluteIndex, numTabs - 1)

  return absoluteIndex

helper_switch_tab = (direction, vim, event, count) ->
  { gBrowser } = vim.rootWindow
  gBrowser.selectTabAtIndex(absoluteTabIndex(direction * count, gBrowser))

# Switch to the previous tab.
command_tab_prev = helper_switch_tab.bind(undefined, -1)

# Switch to the next tab.
command_tab_next = helper_switch_tab.bind(undefined, +1)

helper_move_tab = (direction, vim, event, count) ->
  { gBrowser }    = vim.rootWindow
  { selectedTab } = gBrowser
  { pinned }      = selectedTab

  index = absoluteTabIndex(direction * count, gBrowser)

  if index < gBrowser._numPinnedTabs
    gBrowser.pinTab(selectedTab) unless pinned
  else
    gBrowser.unpinTab(selectedTab) if pinned

  gBrowser.moveTabTo(selectedTab, index)

# Move the current tab backward.
command_tab_move_left = helper_move_tab.bind(undefined, -1)

# Move the current tab forward.
command_tab_move_right = helper_move_tab.bind(undefined, +1)

# Load the home page.
command_home = (vim) ->
  vim.rootWindow.BrowserHome()

# Switch to the first tab.
command_tab_first = (vim) ->
  vim.rootWindow.gBrowser.selectTabAtIndex(0)

# Switch to the first non-pinned tab.
command_tab_first_non_pinned = (vim) ->
  firstNonPinned = vim.rootWindow.gBrowser._numPinnedTabs
  vim.rootWindow.gBrowser.selectTabAtIndex(firstNonPinned)

# Switch to the last tab.
command_tab_last = (vim) ->
  vim.rootWindow.gBrowser.selectTabAtIndex(-1)

# Toggle Pin Tab.
command_toggle_pin_tab = (vim) ->
  currentTab = vim.rootWindow.gBrowser.selectedTab

  if currentTab.pinned
    vim.rootWindow.gBrowser.unpinTab(currentTab)
  else
    vim.rootWindow.gBrowser.pinTab(currentTab)

# Duplicate current tab.
command_duplicate_tab = (vim) ->
  { gBrowser } = vim.rootWindow
  gBrowser.duplicateTab(gBrowser.selectedTab)

# Close all tabs from current to the end.
command_close_tabs_to_end = (vim) ->
  { gBrowser } = vim.rootWindow
  gBrowser.removeTabsToTheEndFrom(gBrowser.selectedTab)

# Close all tabs except the current.
command_close_other_tabs = (vim) ->
  { gBrowser } = vim.rootWindow
  gBrowser.removeAllTabsBut(gBrowser.selectedTab)

# Close current tab.
command_close_tab = (vim, event, count) ->
  { gBrowser } = vim.rootWindow
  return if gBrowser.selectedTab.pinned
  currentIndex = gBrowser.visibleTabs.indexOf(gBrowser.selectedTab)
  for tab in gBrowser.visibleTabs[currentIndex...(currentIndex + count)]
    gBrowser.removeTab(tab)

# Restore last closed tab.
command_restore_tab = (vim, event, count) ->
  vim.rootWindow.undoCloseTab() for [1..count]

# Combine links with the same href.
combine = (hrefs, marker) ->
  if marker.type == 'link'
    { href } = marker.element
    if href of hrefs
      parent = hrefs[href]
      marker.parent = parent
      parent.weight += marker.weight
      parent.numChildren++
    else
      hrefs[href] = marker
  return marker

# Follow links, focus text inputs and click buttons with hint markers.
command_follow = (vim, event, count, newTab, inBackground) ->
  hrefs = {}
  filter = (element, getElementShape) ->
    document = element.ownerDocument
    isXUL = (document instanceof XULDocument)
    semantic = true
    switch
      when isProperLink(element)
        type = 'link'
      when isTextInputElement(element) or isContentEditable(element)
        type = 'text'
      when element.tabIndex > -1 and
           not (isXUL and element.nodeName.endsWith('box'))
        type = 'clickable'
        unless isXUL or element.nodeName in ['A', 'INPUT', 'BUTTON']
          semantic = false
      when element != vim.state.largestScrollableElement and
           vim.state.scrollableElements.has(element)
        type = 'scrollable'
      when element.hasAttribute('onclick') or
           element.hasAttribute('onmousedown') or
           element.hasAttribute('onmouseup') or
           element.hasAttribute('oncommand') or
           element.getAttribute('role') in ['link', 'button'] or
           # Twitter special-case.
           element.classList.contains('js-new-tweets-bar') or
           # Feedly special-case.
           isDataApp(element)
        type = 'clickable'
        semantic = false
      # Putting markers on `<label>` elements is generally redundant, because
      # its `<input>` gets one. However, some sites hide the actual `<input>`
      # but keeps the `<label>` to click, either for styling purposes or to keep
      # the `<input>` hidden until it is used. In those cases we should add a
      # marker for the `<label>`.
      when element.nodeName == 'LABEL'
        if element.htmlFor
          input = document.getElementById(element.htmlFor)
          if input and not getElementShape(input)
            type = 'clickable'
      # Elements that have “button” somewhere in the class might be clickable,
      # unless they contain a real link or button in which case they likely are
      # “button-wrapper”s. (`<SVG element>.className` is not a string!)
      when not isXUL and typeof element.className == 'string' and
           element.className.toLowerCase().contains('button')
        unless element.querySelector('a, button')
          type = 'clickable'
          semantic = false
      # When viewing an image it should get a marker to toggle zoom.
      when document.body?.childElementCount == 1 and
           element.nodeName == 'IMG' and
           (element.classList.contains('overflowing') or
            element.classList.contains('shrinkToFit'))
        type = 'clickable'
    return unless type
    return unless shape = getElementShape(element)
    return combine(hrefs, new Marker(element, shape, {semantic, type}))

  callback = (marker) ->
    { element } = marker
    element.focus()
    last = (count == 1)
    if not last and marker.type == 'link' or newTab
      utils.openTab(vim.rootWindow, element.href, {
        inBackground: inBackground
        relatedToCurrent: true
      })
    else
      if element.target == '_blank'
        targetReset = element.target
        element.target = ''
      utils.simulateClick(element)
      element.target = targetReset if targetReset
    count--
    return (not last and marker.type != 'text')

  vim.enterMode('hints', filter, callback)

# Like command_follow but multiple times.
command_follow_multiple = (vim, event) ->
  command_follow(vim, event, Infinity)

# Follow links in a new background tab with hint markers.
command_follow_in_tab = (vim, event, count) ->
  command_follow(vim, event, count, true, true)

# Follow links in a new foreground tab with hint markers.
command_follow_in_focused_tab = (vim, event, count) ->
  command_follow(vim, event, count, true, false)

# Copy the URL or text of a markable element to the system clipboard.
command_marker_yank = (vim) ->
  hrefs = {}
  filter = (element, getElementShape) ->
    type = switch
      when isProperLink(element)       then 'link'
      when isDataApp(element)          then 'clickable'
      when isTextInputElement(element) then 'textInput'
      when isContentEditable(element)  then 'contenteditable'
    return unless type
    return unless shape = getElementShape(element)
    return combine(hrefs, new Marker(element, shape, {semantic: true, type}))

  callback = (marker) ->
    { element } = marker
    text = switch marker.type
      when 'link'            then element.href
      when 'textInput'       then element.value
      when 'contenteditable' then element.textContent
    utils.writeToClipboard(text)

  vim.enterMode('hints', filter, callback)

# Focus element with hint markers.
command_marker_focus = (vim) ->
  filter = (element, getElementShape) ->
    type = switch
      when element.tabIndex > -1
        'focusable'
      when element != vim.state.largestScrollableElement and
           vim.state.scrollableElements.has(element)
        'scrollable'
    return unless type
    return unless shape = getElementShape(element)
    return new Marker(element, shape, {semantic: true, type})

  callback = (marker) ->
    { element } = marker
    element.focus()
    element.select?()

  vim.enterMode('hints', filter, callback)

# Search for the prev/next patterns in the following attributes of the element.
# `rel` should be kept as the first attribute, since the standard way of marking
# up prev/next links (`rel="prev"` and `rel="next"`) should be favored. Even
# though some of these attributes only allow a fixed set of keywords, we
# pattern-match them anyways since lots of sites don’t follow the spec and use
# the attributes arbitrarily.
attrs = ['rel', 'role', 'data-tooltip', 'aria-label']
helper_follow_pattern = (type, vim) ->
  { document } = vim.window

  # If there’s a `<link rel=prev/next>` element we use that.
  for link in document.head.getElementsByTagName('link')
    # Also support `rel=previous`, just like Google.
    if type == link.rel.toLowerCase().replace(/^previous$/, 'prev')
      vim.rootWindow.gBrowser.loadURI(link.href)
      return

  # Otherwise we look for a link or button on the page that seems to go to the
  # previous or next page.
  candidates = document.querySelectorAll('a, button')
  patterns = utils.splitListString(getPref("#{ type }_patterns"))
  if matchingLink = utils.getBestPatternMatch(patterns, attrs, candidates)
    utils.simulateClick(matchingLink)

# Follow previous page.
command_follow_prev = helper_follow_pattern.bind(undefined, 'prev')

# Follow next page.
command_follow_next = helper_follow_pattern.bind(undefined, 'next')

# Go up one level in the URL hierarchy.
command_go_up_path = (vim, event, count) ->
  { pathname } = vim.window.location
  vim.window.location.pathname = pathname.replace(
    /// (?: /[^/]+ ){1,#{ count }} /?$ ///, ''
  )

# Go up to root of the URL hierarchy.
command_go_to_root = (vim) ->
  vim.window.location.href = vim.window.location.origin

helper_go_history = (num, vim, event, count) ->
  { index } = vim.rootWindow.getWebNavigation().sessionHistory
  { history } = vim.window
  num *= count
  num = Math.max(num, -index)
  num = Math.min(num, history.length - 1 - index)
  return if num == 0
  history.go(num)

# Go back in history.
command_back = helper_go_history.bind(undefined, -1)

# Go forward in history.
command_forward = helper_go_history.bind(undefined, +1)

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

# Quote next keypress (pass it through to the page).
command_quote = (vim, event, count) ->
  vim.enterMode('insert', count)

# Display the Help Dialog.
command_help = (vim) ->
  help.injectHelp(vim.window.document, require('./modes'))

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

  { document } = vim.window
  if document.exitFullscreen
    document.exitFullscreen()
  else
    document.mozCancelFullScreen()


class Command
  constructor: (@group, @name, @func, keys) ->
    @prefName = "commands.#{ @name }.keys"
    @keyValues =
      if isPrefSet(@prefName)
        try JSON.parse(getPref(@prefName))
        catch then []
      else
        keys
    for key, index in @keyValues when typeof key == 'string'
      @keyValues[index] = legacy.convertKey(key)

  keys: (value) ->
    if value == undefined
      return @keyValues
    else
      @keyValues = value
      setPref(@prefName, JSON.stringify(value))

  help: -> _("help_command_#{ @name }")

  match: (str, numbers = null) ->
    for key in @keys()
      key = utils.normalizedKey(key)
      if key.startsWith(str)
        # When letter 0 follows after a number, it is considered as number 0
        # instead of a valid command.
        continue if key == '0' and numbers

        count = parseInt(numbers[numbers.length - 1], 10) if numbers
        count = if count > 1 then count else 1

        return {match: true, exact: (key == str), command: this, count}


# coffeelint: disable=max_line_length
commands = [
  new Command('urls',   'focus',                 command_focus,                 [['o']])
  new Command('urls',   'focus_search',          command_focus_search,          [['O']])
  new Command('urls',   'paste',                 command_paste,                 [['p']])
  new Command('urls',   'paste_tab',             command_paste_tab,             [['P']])
  new Command('urls',   'marker_yank',           command_marker_yank,           [['y', 'f']])
  new Command('urls',   'marker_focus',          command_marker_focus,          [['v', 'f']])
  new Command('urls',   'yank',                  command_yank,                  [['y', 'y']])
  new Command('urls',   'reload',                command_reload,                [['r']])
  new Command('urls',   'reload_force',          command_reload_force,          [['R']])
  new Command('urls',   'reload_all',            command_reload_all,            [['a', 'r']])
  new Command('urls',   'reload_all_force',      command_reload_all_force,      [['a', 'R']])
  new Command('urls',   'stop',                  command_stop,                  [['s']])
  new Command('urls',   'stop_all',              command_stop_all,              [['a', 's']])

  new Command('nav',    'scroll_to_top',         command_scroll_to_top ,        [['g', 'g']])
  new Command('nav',    'scroll_to_bottom',      command_scroll_to_bottom,      [['G']])
  new Command('nav',    'scroll_down',           command_scroll_down,           [['j']])
  new Command('nav',    'scroll_up',             command_scroll_up,             [['k']])
  new Command('nav',    'scroll_left',           command_scroll_left,           [['h']])
  new Command('nav',    'scroll_right',          command_scroll_right ,         [['l']])
  new Command('nav',    'scroll_half_page_down', command_scroll_half_page_down, [['d']])
  new Command('nav',    'scroll_half_page_up',   command_scroll_half_page_up,   [['u']])
  new Command('nav',    'scroll_page_down',      command_scroll_page_down,      [['<space>']])
  new Command('nav',    'scroll_page_up',        command_scroll_page_up,        [['<s-space>']])

  new Command('tabs',   'open_tab',              command_open_tab,              [['t']])
  new Command('tabs',   'tab_prev',              command_tab_prev,              [['J'], ['g', 'T']])
  new Command('tabs',   'tab_next',              command_tab_next,              [['K'], ['g', 't']])
  new Command('tabs',   'tab_move_left',         command_tab_move_left,         [['g', 'J']])
  new Command('tabs',   'tab_move_right',        command_tab_move_right,        [['g', 'K']])
  new Command('tabs',   'home',                  command_home,                  [['g', 'h']])
  new Command('tabs',   'tab_first',             command_tab_first,             [['g', 'H'], ['g', '0']])
  new Command('tabs',   'tab_first_non_pinned',  command_tab_first_non_pinned,  [['g', '^']])
  new Command('tabs',   'tab_last',              command_tab_last,              [['g', 'L'], ['g', '$']])
  new Command('tabs',   'toggle_pin_tab',        command_toggle_pin_tab,        [['g', 'p']])
  new Command('tabs',   'duplicate_tab',         command_duplicate_tab,         [['y', 't']])
  new Command('tabs',   'close_tabs_to_end',     command_close_tabs_to_end,     [['g', 'x', '$']])
  new Command('tabs',   'close_other_tabs',      command_close_other_tabs,      [['g', 'x', 'a']])
  new Command('tabs',   'close_tab',             command_close_tab,             [['x']])
  new Command('tabs',   'restore_tab',           command_restore_tab,           [['X']])

  new Command('browse', 'follow',                command_follow,                [['f']])
  new Command('browse', 'follow_in_tab',         command_follow_in_tab,         [['F']])
  new Command('browse', 'follow_in_focused_tab', command_follow_in_focused_tab, [['g', 'f']])
  new Command('browse', 'follow_multiple',       command_follow_multiple,       [['a', 'f']])
  new Command('browse', 'follow_previous',       command_follow_prev,           [['[']])
  new Command('browse', 'follow_next',           command_follow_next,           [[']']])
  new Command('browse', 'go_up_path',            command_go_up_path,            [['g', 'u']])
  new Command('browse', 'go_to_root',            command_go_to_root,            [['g', 'U']])
  new Command('browse', 'back',                  command_back,                  [['H']])
  new Command('browse', 'forward',               command_forward,               [['L']])

  new Command('misc',   'find',                  command_find,                  [['/']])
  new Command('misc',   'find_hl',               command_find_hl,               [['a', '/']])
  new Command('misc',   'find_next',             command_find_next,             [['n']])
  new Command('misc',   'find_prev',             command_find_prev,             [['N']])
  new Command('misc',   'insert_mode',           command_insert_mode,           [['i']])
  new Command('misc',   'quote',                 command_quote,                 [['I']])
  new Command('misc',   'help',                  command_help,                  [['?']])
  new Command('misc',   'dev',                   command_dev,                   [[':']])

  escapeCommand =
  new Command('misc',   'Esc',                   command_Esc,                   [['<escape>']])
]
# coffeelint: enable=max_line_length

searchForMatchingCommand = (keys) ->
  for index in [0...keys.length] by 1
    str = keys[index..].join('')
    numbers = keys[0..index].join('').match(/[1-9]\d*/g)
    for command in commands
      return match if match = command.match(str, numbers)
  return {match: false}

exports.commands                  = commands
exports.searchForMatchingCommand  = searchForMatchingCommand
exports.escapeCommand             = escapeCommand
exports.Command                   = Command
exports.findStorage               = findStorage
