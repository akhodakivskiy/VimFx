{ classes: Cc, interfaces: Ci, utils: Cu } = Components

utils = require 'utils'
{ getPref } = require 'prefs'

{ handleHintChar
, injectHints
, removeHints
} = require 'hints'

{ showHelp
, hideHelp
} = require 'help'

# Navigate to the address that is currently stored in the system clipboard
command_p = (vim) -> 
  vim.window.location.assign utils.readFromClipboard(vim.window)

# Open new tab and navigate to the address that is currently stored in the system clipboard
command_P = (vim) ->
  if chromeWindow = utils.getRootWindow vim.window
    if gBrowser = chromeWindow.gBrowser
      gBrowser.selectedTab = gBrowser.addTab utils.readFromClipboard(vim.window)

# Open new tab and focus the address bar
command_t = (vim) ->
  if chromeWindow = utils.getRootWindow vim.window
    if gBrowser = chromeWindow.gBrowser
      gBrowser.selectedTab = chromeWindow.gBrowser.addTab()
      if urlbar = chromeWindow.document.getElementById('urlbar')
        urlbar.focus()

# Copy current URL to the clipboard
command_yf = (vim) ->
  vim.markers = injectHints vim.window.document
  if vim.markers.length > 0
    # This callback will be called with the selected marker as argument
    vim.cb = (marker) ->
      if url = marker.element.href
        utils.writeToClipboard vim.window, url

    vim.enterHintsMode()

# Copy current URL to the clipboard
command_yy = (vim) ->
  utils.writeToClipboard vim.window, vim.window.location.toString()

# Reload the page, possibly from cache
command_r = (vim) ->
  vim.window.location.reload(false)

# Reload the page from the server
command_R = (vim) ->
  vim.window.location.reload(true)

# Scroll to the top of the page
command_gg = (vim) ->
  vim.window.scrollTo(0, 0)

# Scroll to the bottom of the page
command_G = (vim) ->
  if document = vim.window.document
    # Workaround the pages where body isn't the scrollable element.
    # In this case we try to scroll 100k pixels
    vim.window.scrollTo(0, Math.max(document.body.scrollHeight, 100000))

# Scroll down a bit
command_j_ce = (vim) -> 
  utils.smoothScroll vim.window, 0, (getPref 'scroll_step'), getPref 'scroll_time'

# Scroll up a bit
command_k_cy = (vim) -> 
  utils.smoothScroll vim.window, 0, -(getPref 'scroll_step'), getPref 'scroll_time'

# Scroll left a bit
command_h = (vim) -> 
  utils.smoothScroll vim.window, -(getPref 'scroll_step'), 0, getPref 'scroll_time'

# Scroll right a bit
command_l = (vim) -> 
  utils.smoothScroll vim.window, (getPref 'scroll_step'), 0, getPref 'scroll_time'

# Scroll down half a page
command_d = (vim) ->
  utils.smoothScroll vim.window, 0, vim.window.innerHeight / 2, getPref 'scroll_time'

# Scroll up half a page
command_u = (vim) ->
  utils.smoothScroll vim.window, 0, -vim.window.innerHeight / 2, getPref 'scroll_time'
  
# Scroll down full a page
command_cf = (vim) ->
  vim.window.scrollByPages(1)

# Scroll up full a page
command_cb = (vim) ->
  vim.window.scrollByPages(-1)

# Activate previous tab
command_J_gT = (vim) ->
  if rootWindow = utils.getRootWindow vim.window
    rootWindow.gBrowser.tabContainer.advanceSelectedTab(-1, true);

# Activate next tab
command_K_gt = (vim) ->
  if rootWindow = utils.getRootWindow vim.window
    rootWindow.gBrowser.tabContainer.advanceSelectedTab(1, true);

# Go to the first tab
command_gH_g0 = (vim) ->
  if rootWindow = utils.getRootWindow vim.window
    rootWindow.gBrowser.tabContainer.selectedIndex = 0;

# Go to the last tab
command_gL_g$ = (vim) ->
  if rootWindow = utils.getRootWindow vim.window
    itemCount = rootWindow.gBrowser.tabContainer.itemCount;
    rootWindow.gBrowser.tabContainer.selectedIndex = itemCount - 1;

# Go back in history
command_H = (vim) ->
  vim.window.history.back()
    
# Go forward in history
command_L = (vim) ->
  vim.window.history.forward()

# Close current tab
command_x = (vim) ->
  if rootWindow = utils.getRootWindow vim.window
    rootWindow.gBrowser.removeCurrentTab()

# Restore last closed tab
command_X = (vim) -> 
  if rootWindow = utils.getRootWindow vim.window
    ss = utils.getSessionStore()
    if ss and ss.getClosedTabCount(rootWindow) > 0
      ss.undoCloseTab rootWindow, 0

# Follow links with hint markers
command_f = (vim) ->
  if document = vim.window.document
    vim.markers = injectHints document
    if vim.markers.length > 0
      # This callback will be called with the selected marker as argument
      vim.cb = (marker) ->
        marker.element.focus()
        utils.simulateClick marker.element

      vim.enterHintsMode()
  
# Follow links in a new Tab with hint markers
command_F = (vim) ->
  vim.markers = injectHints vim.window.document
  if vim.markers.length > 0
    # This callback will be called with the selected marker as argument
    vim.cb = (marker) ->
      marker.element.focus()
      utils.simulateClick marker.element, { metaKey: true, ctrlKey: true }

    vim.enterHintsMode()

# Move current tab to the left
command_cJ = (vim) ->
  if gBrowser = utils.getRootWindow(vim.window)?.gBrowser
    if tab = gBrowser.selectedTab
      index = gBrowser.tabContainer.selectedIndex
      total = gBrowser.tabContainer.itemCount

      # `total` is added to deal with negative offset
      gBrowser.moveTabTo tab, (total + index - 1) % total
  
# Move current tab to the right
command_cK = (vim) ->
  if gBrowser = utils.getRootWindow(vim.window)?.gBrowser
    if tab = gBrowser.selectedTab
      index = gBrowser.tabContainer.selectedIndex
      total = gBrowser.tabContainer.itemCount

      gBrowser.moveTabTo tab, (index + 1) % total

# Display the Help Dialog
command_help = (vim) ->
  showHelp vim.window.document, commandsHelp

# Close the Help dialog and cancel the pending hint marker action
command_Esc = (vim) ->
  # Blur active element if it's editable. Other elements
  # aren't blurred - we don't want to interfere with 
  # the browser too much
  activeElement = vim.window.document.activeElement
  if utils.isElementEditable activeElement
    activeElement.blur()

  # Remove hints
  removeHints vim.window.document
  # Hide help dialog
  hideHelp vim.window.document
  # Finally enter normal mode
  vim.enterNormalMode()

commandGroups = 
  'urls':
    'p':        [ command_p,      _('help_command_p') ]
    'P':        [ command_P,      _('help_command_P') ]
    'y,f':      [ command_yf,     _('help_command_yf') ]
    'y,y':      [ command_yy,     _('help_command_yy') ]
    'r':        [ command_r,      _('help_command_r') ]
    'R':        [ command_R,      _('help_command_R') ]
  'nav':
    'g,g':      [ command_gg ,    _('help_command_gg') ]
    'G':        [ command_G,      _('help_command_G') ]
    'j|c-e':    [ command_j_ce,   _('help_command_j_ce') ]
    'k|c-y':    [ command_k_cy,   _('help_command_k_cy') ]
    'h':        [ command_h,      _('help_command_h') ]
    'l':        [ command_l ,     _('help_command_l') ]
    'd|c-d':    [ command_d,      _('help_command_d') ]
    'u|c-u':    [ command_u,      _('help_command_u') ]
    'c-f':      [ command_cf,     _('help_command_cf') ]
    'c-b':      [ command_cb,     _('help_command_cb') ]
  'tabs':
    't':        [ command_t,      _('help_command_t') ]
    'J|g,T':    [ command_J_gT,   _('help_command_J_gT') ]
    'K|g,t':    [ command_K_gt,   _('help_command_K_gt') ]
    'c-J':      [ command_cJ,     _('help_command_cJ') ]
    'c-K':      [ command_cK,     _('help_command_cK') ]
    'g,H|g,0':  [ command_gH_g0,  _('help_command_gH_g0') ]
    'g,L|g,$':  [ command_gL_g$,  _('help_command_gL_g$') ]
    'x':        [ command_x,      _('help_command_x') ]
    'X':        [ command_X,      _('help_command_X') ]
  'browse':
    'f':        [ command_f,      _('help_command_f') ]
    'F':        [ command_F,      _('help_command_F') ]
    'H':        [ command_H,      _('help_command_H') ]
    'L':        [ command_L,      _('help_command_L') ]
  'misc': 
    # `>` is added to help command mapping to hack around russian keyboard layout
    # See key-utils.coffee for more info
    '?|>':      [ command_help,   _('help_command_help') ]
    'Esc':      [ command_Esc,    _('help_command_Esc') ]
    
# Merge groups and split command pipes into individual commands
commands = do (commandGroups) ->
  newCommands = {}
  for group, commandsList of commandGroups
    for keys, command of commandsList
      for key in keys.split '|'
        newCommands[key] = command[0]

  return newCommands

# Extract the help text from the commands preserving groups formation
commandsHelp = do (commandGroups) ->
  help = {}
  for group, commandsList of commandGroups
    helpGroup = {}
    for keys, command of commandsList
      key = keys.replace(/,/g, '').replace('|', ', ')
      helpGroup[key] = command[1]

    help[group] = helpGroup
  return help

# Called in hints mode. Will process the char, update and hide/show markers 
hintCharHandler = (vim, char) ->
  # First count how many markers will match with the new character entered
  preMatch = vim.markers.reduce ((v, marker) -> v + marker.willMatch char), 0

  # If prematch is greater than 0, then proceed with matching, else ignore the new char
  if preMatch > 0
    for marker in vim.markers
      marker.matchHintChar char

      if marker.isMatched()
        vim.cb marker
        removeHints vim.window.document
        vim.enterNormalMode()
        break

exports.hintCharHandler = hintCharHandler
exports.commands        = commands
exports.commandsHelp    = commandsHelp
