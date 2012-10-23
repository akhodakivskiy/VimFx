utils           = require 'utils'
keyUtils        = require 'key-utils'
{ getCommand }  = require 'commands'
{ Vim }         = require 'vim'
{ getPref }     = require 'prefs'

{ interfaces: Ci } = Components

vimBucket = new utils.Bucket utils.getWindowId, (obj) -> new Vim obj

suppressEvent = (event) ->
  event.preventDefault()
  event.stopPropagation()

# The following handlers are installed on every top level DOM window
handlers = 
  'keydown': (event) ->

    if getPref 'disabled'
      return

    try
      isEditable =  utils.isElementEditable event.originalTarget

      { ctrlKey: ctrl, metaKey: meta, altKey: alt, shiftKey: shift } = event 
      console.log ctrl, meta, alt, shift

      # any keys modified with meta or alt should be ignored
      if meta or alt
        return 

      # Extract keyChar from keyCode and apply modifiers
      keyChar = keyUtils.keyCharFromCode(event.keyCode, shift)
      keyStr = keyUtils.applyModifiers(keyChar, ctrl, alt, meta)

      console.log keyStr
      # We only handle the key if there is no focused editable element
      # or if it's the *Esc* key, which will remove the focus from 
      # the currently focused element
      if not isEditable or keyStr == 'Esc'
        if window = utils.getCurrentTabWindow event
          if vimBucket.get(window)?.pushKey keyStr
            # We don't really want to suppress the Esc key, 
            # but we want to handle it
            if keyStr != 'Esc'
              suppressEvent event
    catch err
      console.log err

  'keypress': (event) ->
    if getPref 'disabled'
      return

    try
      # Try to execute keys that were accumulated so far.
      # Suppress event if there is a matching command.
      if window = utils.getCurrentTabWindow event
        if vimBucket.get(window)?.execKeys()
          suppressEvent event
    catch err
      console.log err

  'TabClose': (event) ->
    if gBrowser = utils.getEventTabBrowser event
      if browser = gBrowser.getBrowserForTab event.originalTarget
        vimBucket.forget browser.contentWindow.wrappedJSObject

  # When the top level window closes we should release all Vims that were 
  # associated with tabs in this window
  'DOMWindowClose': (event) ->
    if gBrowser = event.originalTarget.gBrowser
      for tab in gBrowser.tabs
        if browser = gBrowser.getBrowserForTab tab
          vimBucket.forget browser.contentWindow.wrappedJSObject

addEventListeners = (window) ->
  for name, handler of handlers
    window.addEventListener name, handler, true

  removeEventListeners = ->
    for name, handler of handlers
      window.removeEventListener name, handler, true

  unload -> removeEventListeners window

exports.addEventListeners = addEventListeners
