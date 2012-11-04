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
    vim.window.scrollTo(0, document.body.scrollHeight)

# Scroll down a bit
command_j_ce = (vim) -> 
  vim.window.scrollBy(0, getPref 'scroll_step')

# Scroll up a bit
command_k_cy = (vim) -> 
  vim.window.scrollBy(0, - getPref 'scroll_step')

# Scroll left a bit
command_h = (vim) -> 
  vim.window.scrollBy(- getPref 'scroll_step', 0)

# Scroll right a bit
command_l = (vim) -> 
  vim.window.scrollBy(getPref 'scroll_step', 0)

# Scroll down a page
command_d = (vim) ->
  vim.window.scrollBy(0, vim.window.innerHeight)

# Scroll up a page
command_u = (vim) ->
  vim.window.scrollBy(0, -vim.window.innerHeight)

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
      console.log index, total, (total + index - 1) % total, 'left'
      gBrowser.moveTabTo tab, (total + index - 1) % total
  
# Move current tab to the right
command_cK = (vim) ->
  if gBrowser = utils.getRootWindow(vim.window)?.gBrowser
    if tab = gBrowser.selectedTab
      index = gBrowser.tabContainer.selectedIndex
      total = gBrowser.tabContainer.itemCount

      console.log index, total, (index + 1) % total, 'right'
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
    'p':        [ command_p,      "Navigate to the address in the clipboard" ]
    'P':        [ command_P,      "Open new tab and navigate to the address in the clipboard" ]
    'y,f':      [ command_yf,     "Copy link url to the clipboard" ]
    'y,y':      [ command_yy,     "Copy current page link to the clipboard" ]
    'r':        [ command_r,      "Reload current page" ]
    'R':        [ command_R,      "Reload current page and all the assets (js, css, etc.)" ]
  'nav':
    'g,g':      [ command_gg ,    "Scroll to the Top of the page" ]
    'G':        [ command_G,      "Scroll to the Bottom of the page" ]
    'j|c-e':    [ command_j_ce,   "Scroll Down" ]
    'k|c-y':    [ command_k_cy,   "Scroll Up" ]
    'h':        [ command_h,      "Scroll Left" ]
    'l':        [ command_l ,     "Scroll Right" ]
    'd':        [ command_d,      "Scroll a Page Down" ]
    'u':        [ command_u,      "Scroll a Page Up" ]
  'tabs':
    't':        [ command_t,      "Open New Blank tab" ]
    'J|g,T':    [ command_J_gT,   "Go to the Previous tab" ]
    'K|g,t':    [ command_K_gt,   "Go to the Next tab" ]
    'c-J':      [ command_cJ,     "Move current tab to the left" ]
    'c-K':      [ command_cK,     "Move current tab to the right" ]
    'g,H|g,0':  [ command_gH_g0,  "Go to the First tab" ]
    'g,L|g,$':  [ command_gL_g$,  "Go to the Last tab" ]
    'x':        [ command_x,      "Close current tab" ]
    'X':        [ command_X,      "Restore last closed tab" ]
  'browse':
    'f':        [ command_f,      "Follow a link on the current page" ]
    'F':        [ command_F,      "Follow a link on the current page in a new tab" ]
    'H':        [ command_H,      "Go Back in history" ]
    'L':        [ command_L,      "Go Forward in history" ]
  'misc':
    '?':        [ command_help,   "Show Help Dialog" ]
    'Esc':      [ command_Esc,    "Close this dialog and cancel hint markers" ]
    
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
      key = keys.replace(',', '').replace('|', ', ')
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
