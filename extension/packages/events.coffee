utils                           = require 'utils'
keyUtils                        = require 'key-utils'
{ getCommand }                  = require 'commands'
{ Vim }                         = require 'vim'
{ getPref }                     = require 'prefs'
{ setWindowBlacklisted }        = require 'button'

{ interfaces: Ci } = Components

vimBucket = new utils.Bucket utils.getWindowId, (obj) -> new Vim obj

suppressEvent = (event) ->
  event.preventDefault()
  event.stopPropagation()

# The following listeners are installed on every top level Chrome window
windowsListener = 
  'keydown': (event) ->

    if getPref 'disabled'
      return

    try
      isEditable =  utils.isElementEditable event.originalTarget

      { ctrlKey: ctrl, metaKey: meta, altKey: alt, shiftKey: shift } = event 

      # any keys modified with meta or alt should be ignored
      if meta or alt
        return 

      # Extract keyChar from keyCode and apply modifiers
      if keyChar = keyUtils.keyCharFromCode(event.keyCode, shift)
        keyStr = keyUtils.applyModifiers(keyChar, ctrl, alt, meta)

      # We only handle the key if it's recognized by `keyCharFromCode`
      # and if there is no focused editable element # or if it's the *Esc* key, 
      # which will remove the focus from the currently focused element
      if keyStr and (not isEditable or keyStr == 'Esc')
        if window = utils.getCurrentTabWindow event
          if vim = vimBucket.get(window)
            # No action if blacklisted
            if vim.blacklisted
              return

            if vim.handleKeyDown(event, keyStr)
              if keyStr != 'Esc'
                suppressEvent event
    catch err
      console.log err, 'keydown'

  'keypress': (event) ->
    if getPref 'disabled'
      return

    try
      # Try to execute keys that were accumulated so far.
      # Suppress event if there is a matching command.
      if window = utils.getCurrentTabWindow event
        if vim = vimBucket.get(window)
          # No action on blacklisted locations
          if vim.blacklisted
            return
          
          lastKeyStr = vim.keys[vim.keys.length - 1]

          # Blur from any active element on Esc. Calling before `handleKeyPress` 
          # because `vim.keys` will be reset afterwards`
          blur_on_esc = lastKeyStr == 'Esc' and getPref 'blur_on_esc'

          if vim.handleKeyPress event
            if lastKeyStr != 'Esc'
              suppressEvent event

          # Calling after the command has been executed
          if blur_on_esc
            event.originalTarget?.ownerDocument?.activeElement?.blur()

    catch err
      console.log err, 'keypress'

  # When the top level window closes we should release all Vims that were 
  # associated with tabs in this window
  'DOMWindowClose': (event) ->
    if gBrowser = event.originalTarget.gBrowser
      for tab in gBrowser.tabs
        if browser = gBrowser.getBrowserForTab tab
          vimBucket.forget browser.contentWindow

  'TabClose': (event) ->
    if gBrowser = utils.getEventTabBrowser event
      if browser = gBrowser.getBrowserForTab event.originalTarget
        vimBucket.forget browser.contentWindow

  # Update the toolbar button icon to reflect the blacklisted state
  'TabSelect': (event) ->
    if vim = vimBucket.get event.originalTarget?.linkedBrowser?.contentDocument?.defaultView
      if rootWindow = utils.getRootWindow vim.window
        setWindowBlacklisted rootWindow, vim.blacklisted

# This listener works on individual tabs within Chrome Window
# User for: listening for location changes and disabling the extension
# on black listed urls
tabsListener = 
  onLocationChange: (browser, webProgress, request, location) ->
    blacklisted = utils.isBlacklisted location.spec, getPref 'black_list'
    if vim = vimBucket.get(browser.contentWindow)
      vim.blacklisted = blacklisted
      if rootWindow = utils.getRootWindow vim.window
        setWindowBlacklisted rootWindow, vim.blacklisted

addEventListeners = (window) ->
  for name, listener of windowsListener
    window.addEventListener name, listener, true

  # Install onLocationChange listener
  window.gBrowser.addTabsProgressListener tabsListener

  removeEventListeners = ->
    for name, listener of windowsListener
      window.removeEventListener name, listener, true

  unload -> 
    removeEventListeners window
    window.gBrowser.removeTabsProgressListener tabsListener

exports.addEventListeners = addEventListeners
