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

commands = 
  # Navigate to the address that is currently stored in the system clipboard
  'p':  (vim) ->
    vim.window.location.assign utils.readFromClipboard()
    
  # Open new tab and navigate to the address that is currently stored in the system clipboard
  'P':  (vim) ->
    if chromeWindow = utils.getRootWindow vim.window
      if gBrowser = chromeWindow.gBrowser
        gBrowser.selectedTab = gBrowser.addTab utils.readFromClipboard()
        #
  # Open new tab and focus the address bar
  't':  (vim) ->
    if chromeWindow = utils.getRootWindow vim.window
      if gBrowser = chromeWindow.gBrowser
        gBrowser.selectedTab = chromeWindow.gBrowser.addTab()

  # Copy current URL to the clipboard
  'y,f': (vim) ->
    vim.markers = injectHints vim.window.document
    if vim.markers.length > 0
      # This callback will be called with the selected marker as argument
      vim.cb = (marker) ->
        if url = marker.element.href
          utils.writeToClipboard url

      vim.enterHintsMode()

  # Copy current URL to the clipboard
  'y,y': (vim) ->
    utils.writeToClipboard vim.window.location.toString()

  # Reload the page, possibly from cache
  'r': (vim) ->
    vim.window.location.reload(false)
    #
  # Reload the page from the server
  'R': (vim) ->
    vim.window.location.reload(false)

  # Scroll to the top of the page
  'g,g': (vim) ->
    vim.window.scrollTo(0, 0)

  # Scroll to the bottom of the page
  'G': (vim) ->
    vim.window.scrollTo(0, vim.window.document.body.scrollHeight)

  # Scroll down a bit
  'j|c-e': (vim) -> 
    scroll_step = getPref 'scroll_step'
    vim.window.scrollBy(0, scroll_step)

  # Scroll up a bit
  'k|c-y': (vim) -> 
    scroll_step = getPref 'scroll_step'
    vim.window.scrollBy(0, -scroll_step)

  # Scroll down a page
  'd|c-d': (vim) ->
    vim.window.scrollBy(0, vim.window.innerHeight)

  # Scroll up a page
  'u|c-u': (vim) ->
    vim.window.scrollBy(0, -vim.window.innerHeight)

  # Activate previous tab
  'J|g,T': (vim) ->
    if rootWindow = utils.getRootWindow vim.window
      rootWindow.gBrowser.tabContainer.advanceSelectedTab(-1, true);

  # Activate next tab
  'K|g,t': (vim) ->
    if rootWindow = utils.getRootWindow vim.window
      rootWindow.gBrowser.tabContainer.advanceSelectedTab(1, true);

  # Go to the first tab
  'g,H|g,0': (vim) ->
    if rootWindow = utils.getRootWindow vim.window
      rootWindow.gBrowser.tabContainer.selectedIndex = 0;
      #
  # Go to the last tab
  'g,L|g,$': (vim) ->
    if rootWindow = utils.getRootWindow vim.window
      itemCount = rootWindow.gBrowser.tabContainer.itemCount;
      rootWindow.gBrowser.tabContainer.selectedIndex = itemCount - 1;

  # Go back in history
  'H': (vim) ->
    vim.window.history.back()
    
  # Go forward in history
  'L': (vim) ->
    vim.window.history.forward()

  # Close current tab
  'x': (vim) ->
    if rootWindow = utils.getRootWindow vim.window
      rootWindow.gBrowser.removeCurrentTab()

  # Restore last closed tab
  'X': (vim) ->
    if rootWindow = utils.getRootWindow vim.window
      ss = utils.getSessionStore()
      if ss and ss.getClosedTabCount(rootWindow) > 0
        ss.undoCloseTab rootWindow, 0

  # Follow links with hint markers
  'f': (vim) ->
    vim.markers = injectHints vim.window.document
    if vim.markers.length > 0
      # This callback will be called with the selected marker as argument
      vim.cb = (marker) ->
        marker.element.focus()
        utils.simulateClick marker.element

      vim.enterHintsMode()
    
  # Follow links in a new Tab with hint markers
  'F': (vim) ->
    vim.markers = injectHints vim.window.document
    if vim.markers.length > 0
      # This callback will be called with the selected marker as argument
      vim.cb = (marker) ->
        marker.element.focus()
        utils.simulateClick marker.element, metaKey: true

      vim.enterHintsMode()

  # Show Help
  '?': (vim) ->
    showHelp vim.window.document

  'Esc': (vim) ->
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

    
# Split command pipes into individual commands
commands = do (commands) ->
  newCommands = {}
  for keys, command of commands
    for key in keys.split '|'
      newCommands[key] = command
  return newCommands

# Called in hints mode. Will process the char, update and hide/show markers 
hintCharHandler = (vim, char) ->
  for marker in vim.markers
    marker.matchHintChar char

    if marker.isMatched()
      vim.cb marker
      removeHints vim.window.document
      vim.enterNormalMode()
      break

exports.hintCharHandler   = hintCharHandler
exports.commands          = commands
