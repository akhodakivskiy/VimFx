utils               = require 'utils'
{ getCommand }      = require 'commands'
{ Vim }             = require 'vim'
{ WindowTracker, 
  isBrowserWindow } = require 'window-utils'

{ interfaces: Ci } = Components

vimBucket = new utils.Bucket utils.getWindowId, (obj) -> new Vim obj

suppressEvent = (event) ->
  event.preventDefault()
  event.stopPropagation()

# The following handlers are installed on every top level DOM window
handlers = 
  'keypress': (event) ->
    try
      isEditable =  utils.isElementEditable event.originalTarget
      key = utils.keyboardEventKey event

      # We only handle the key if there is no focused editable element
      # or if it's the *Esc* key, which will remote the focus from 
      # the currently focused element
      if key and (key == 'Esc' or not isEditable)
        if window = utils.getEventTabWindow event
          if vimBucket.get(window)?.keypress key
            suppressEvent event
    catch err
      console.log err

  'TabClose': (event) ->
    if gBrowser = utils.getEventTabBrowser event
      if browser = gBrowser.getBrowserForTab event.originalTarget
        vimBucket.forget browser.contentWindow.wrappedJSObject

  'DOMWindowClose': (event) ->
    if gBrowser = event.originalTarget.gBrowser
      for tab in gBrowser.tabs
        if browser = gBrowser.getBrowserForTab tab
          vimBucket.forget browser.contentWindow.wrappedJSObject

# Delegate for WindowTracker that will add and remove event handlers 
# to the each window that goes through the tracker
delegate = 
  track: (window) -> 
    if isBrowserWindow window
      for name, handler of handlers
        window.addEventListener name, handler, true

  untrack: (window) ->
    if isBrowserWindow window
      for name, handler of handlers
        window.removeEventListener name, handler, true

# Creates and returns an instance of WindowTracker 
# that will attach the passed event handlers to
# each opened top level window.
createWindowEventTracker = -> new WindowTracker delegate

exports.createWindowEventTracker = createWindowEventTracker
