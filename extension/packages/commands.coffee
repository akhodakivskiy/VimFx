{ classes: Cc, interfaces: Ci, utils: Cu } = Components

utils = require 'utils'
hints = require 'hints'
help  = require 'help'
find  = require 'find'

{ getPref } = require 'prefs'

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
      # Get the default url for the new tab
      newtab_url = Services.prefs.getCharPref 'browser.newtab.url'
      gBrowser.selectedTab = gBrowser.addTab newtab_url
      # Focus the address bar
      chromeWindow.focusAndSelectUrlBar()

# Copy current URL to the clipboard
command_yf = (vim) ->
  markers = hints.injectHints vim.window.document
  if markers.length > 0
    # This callback will be called with the selected marker as argument
    cb = (marker) ->
      if url = marker.element.href
        utils.writeToClipboard vim.window, url

    vim.enterHintsMode(markers, cb)

# Copy current URL to the clipboard
command_yy = (vim) ->
  utils.writeToClipboard vim.window, vim.window.location.toString()

# Reload the page, possibly from cache
command_r = (vim) ->
  vim.window.location.reload(false)

# Reload the page from the server
command_R = (vim) ->
  vim.window.location.reload(true)
  
# Reload the page, possibly from cache
command_ar = (vim) ->
  if rootWindow = utils.getRootWindow vim.window
    if tabs = rootWindow.gBrowser.tabContainer
      for i in [0...tabs.itemCount]
        window = tabs.getItemAtIndex(i).linkedBrowser.contentWindow
        window.location.reload(false)

# Reload the page from the server
command_aR = (vim) ->
  if rootWindow = utils.getRootWindow vim.window
    if tabs = rootWindow.gBrowser.tabContainer
      for i in [0...tabs.itemCount]
        window = tabs.getItemAtIndex(i).linkedBrowser.contentWindow
        window.location.reload(true)

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
  step = (vim.window.innerHeight - (getPref 'scroll_step'))
  utils.smoothScroll vim.window, 0, step, getPref 'scroll_time'

# Scroll up full a page
command_cb = (vim) ->
  step = - (vim.window.innerHeight - (getPref 'scroll_step'))
  utils.smoothScroll vim.window, 0, step, getPref 'scroll_time'

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
    markers = hints.injectHints document
    if markers.length > 0
      # This callback will be called with the selected marker as argument
      cb = (marker) ->
        marker.element.focus()
        utils.simulateClick marker.element

      vim.enterHintsMode markers, cb
  
# Follow links in a new Tab with hint markers
command_F = (vim) ->
  markers = hints.injectHints vim.window.document
  if markers.length > 0
    # This callback will be called with the selected marker as argument
    cb = (marker) ->
      marker.element.focus()
      utils.simulateClick marker.element, { metaKey: true, ctrlKey: true }

    vim.enterHintsMode markers, cb

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
  help.injectHelp vim.window.document, commandsHelp

# Switch into find mode
command_find = (vim) ->
  vim.enterFindMode()
  vim.findStr = ""

  find.injectFind vim.window.document

# Search for the last pattern
command_n = (vim) ->
  if vim.findStr.length > 0
    if not find.find vim.window, vim.findStr, false
      find.flashFind vim.window.document, "#{ vim.findStr } (Not Found)"
  
# Search for the last pattern backwards
command_N = (vim) ->
  if vim.findStr.length > 0
    if not find.find vim.window, vim.findStr, true
      find.flashFind vim.window.document, "#{ vim.findStr } (Not Found)"

# Close the Help dialog and cancel the pending hint marker action
command_Esc = (vim) ->
  # Blur active element if it's editable. Other elements
  # aren't blurred - we don't want to interfere with 
  # the browser too much
  activeElement = vim.window.document.activeElement
  if utils.isElementEditable activeElement
    activeElement.blur()

  #Remove Find input
  find.removeFind vim.window.document

  # Remove hints
  hints.removeHints vim.window.document

  # Hide help dialog
  help.removeHelp vim.window.document

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
    'a,r':      [ command_ar,     _('help_command_ar') ]
    'a,R':      [ command_aR,     _('help_command_aR') ]
  'nav':
    'g,g':      [ command_gg ,    _('help_command_gg') ]
    'G':        [ command_G,      _('help_command_G') ]
    'j|c-e':    [ command_j_ce,   _('help_command_j_ce') ]
    'k|c-y':    [ command_k_cy,   _('help_command_k_cy') ]
    'h':        [ command_h,      _('help_command_h') ]
    'l':        [ command_l ,     _('help_command_l') ]
    # Can't use c-u/c-d because it's widely used for viewing sources
    'd':        [ command_d,      _('help_command_d') ]
    'u':        [ command_u,      _('help_command_u') ]
    'c-f':      [ command_cf,     _('help_command_cf') ]
    'c-b':      [ command_cb,     _('help_command_cb') ]
  'tabs':
    't':        [ command_t,      _('help_command_t') ]
    'J|g,T':    [ command_J_gT,   _('help_command_J_gT') ]
    'K|g,t':    [ command_K_gt,   _('help_command_K_gt') ]
    'c-J':      [ command_cJ,     _('help_command_cJ') ]
    'c-K':      [ command_cK,     _('help_command_cK') ]
    "g,H|g,\^": [ command_gH_g0,  _('help_command_gH_g0') ]
    'g,L|g,$':  [ command_gL_g$,  _('help_command_gL_g$') ]
    'x':        [ command_x,      _('help_command_x') ]
    'X':        [ command_X,      _('help_command_X') ]
  'browse':
    'f':        [ command_f,      _('help_command_f') ]
    'F':        [ command_F,      _('help_command_F') ]
    'H':        [ command_H,      _('help_command_H') ]
    'L':        [ command_L,      _('help_command_L') ]
  'misc': 
    '/':        [ command_find,   _('help_command_find') ]
    'n':        [ command_n,      _('help_command_n') ]
    'N':        [ command_N,      _('help_command_N') ]
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
  helpStrings = {}
  for group, commandsList of commandGroups
    helpGroup = {}
    for keys, command of commandsList
      key = keys.replace(/,/g, '').replace('|', ', ')
      helpGroup[key] = command[1]

    helpStrings[group] = helpGroup
  return helpStrings

# Called in hints mode. Will process the char, update and hide/show markers 
hintCharHandler = (vim, keyStr, charCode) ->
  if charCode > 0
    # Get char and escape it to avoid problems with String.search
    key = utils.regexpEscape keyStr

    # First do a pre match - count how many markers will match with the new character entered
    if vim.markers.reduce ((v, marker) -> v + marker.willMatch key), 0
      for marker in vim.markers
        marker.matchHintChar key

        if marker.isMatched()
          vim.cb marker
          hints.removeHints vim.window.document
          vim.enterNormalMode()
          break

# Called in find mode. Will process charCode, update find, or close the 
findCharHandler = (vim, keyStr, charCode) ->
  backwards = false

  toNormalMode = ->
    find.removeFind vim.window.document 
    vim.enterNormalMode()

  if keyStr and keyStr.match(/.*Return/)
    return toNormalMode()
  else if keyStr == 'Backspace'
    # Delete last available character from the query string 
    if vim.findStr.length > 0
      vim.findStr = vim.findStr.substr(0, vim.findStr.length - 1)
    # Leave Find Mode the query string is already empty
    else
      return toNormalMode()
  else if charCode > 0
    vim.findStr += String.fromCharCode(charCode)
  else
    return

  # Update the interface string

  # Clear selection to avoid jumping between matching search results
  vim.window.getSelection().removeAllRanges()

  # Search only if the query string isn't emply.
  # Otherwise it will pop up Find dialog
  if find.find vim.window, vim.findStr, backwards
    find.setFindStr vim.window.document, vim.findStr
  else
    find.setFindStr vim.window.document, "#{ vim.findStr } (Not Found)"



exports.hintCharHandler = hintCharHandler
exports.findCharHandler = findCharHandler
exports.commands        = commands
exports.commandsHelp    = commandsHelp
