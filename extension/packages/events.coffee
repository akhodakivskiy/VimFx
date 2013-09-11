utils                    = require 'utils'
keyUtils                 = require 'key-utils'
{ Vim }                  = require 'vim'
{ getPref }              = require 'prefs'
{ updateToolbarButton } = require 'button'
{ unload }              = require 'unload'

{ interfaces: Ci } = Components

vimBucket = new utils.Bucket(utils.getWindowId, (obj) -> new Vim(obj))

suppressEvent = (event) ->
  event.preventDefault()
  event.stopPropagation()

# *************************
# NB! TODO! All this shit needs to be redone!!
# *************************

keyStrFromEvent = (event) ->

  { ctrlKey: ctrl, metaKey: meta, altKey: alt, shiftKey: shift } = event

  if !meta and !alt
    if keyChar = keyUtils.keyCharFromCode(event.keyCode, shift)
      keyStr = keyUtils.applyModifiers(keyChar, ctrl, alt, meta)

  return keyStr

# Passthrough mode is activated when VimFx should temporarily stop processking
# keyboard input. For example when a context menu is whown
passthrough = false

logError = (err, eventName) ->
  console.log("#{ err } (in #{ eventName })\n#{ err.stack.replace(/@.+-> /g, '@') }")

# The following listeners are installed on every top level Chrome window
windowsListener =
  keydown: (event) ->
    if passthrough or getPref('disabled')
      return

    try
      isEditable = utils.isElementEditable(event.originalTarget)

      keyStr = keyStrFromEvent(event)

      # We only handle the key if it's recognized by `keyCharFromCode`
      # and if there is no focused editable element or if it's the *Esc* key,
      # which will remove the focus from the currently focused element
      if keyStr and (not isEditable or keyStr == 'Esc')
        if window = utils.getEventCurrentTabWindow(event)
          if vim = vimBucket.get(window)
            if vim.blacklisted
              return

            if vim.handleKeyDown(event, keyStr)
              suppressEvent(event)

            # Also blur active element if preferencess allow (for XUL controls)
            if keyStr == 'Esc' and getPref('blur_on_esc')
              cb = -> event.originalTarget?.ownerDocument?.activeElement?.blur()
              window.setTimeout(cb, 0)

    catch err
      logError(err, 'keydown')

  keypress: (event) ->
    if passthrough or getPref('disabled')
      return

    try
      isEditable = utils.isElementEditable(event.originalTarget)

      # Try to execute keys that were accumulated so far.
      # Suppress event if there is a matching command.
      if window = utils.getEventCurrentTabWindow(event)
        if vim = vimBucket.get(window)
          if vim.blacklisted
            return

          if vim.handleKeyPress(event)
            suppressEvent(event)

    catch err
      logError(err, 'keypress')

  keyup: (event) ->
    if passthrough or getPref('disabled')
      return

    if window = utils.getEventCurrentTabWindow(event)
      if vim = vimBucket.get(window)
        if vim.handleKeyUp(event)
          suppressEvent(event)

  popupshown: (event) ->
    if event.target.tagName in [ 'menupopup', 'panel' ]
      passthrough = true


  popuphidden: (event) ->
    if event.target.tagName in [ 'menupopup', 'panel' ]
      passthrough = false

  # When the top level window closes we should release all Vims that were
  # associated with tabs in this window
  DOMWindowClose: (event) ->
    return unless { gBrowser } = event.originalTarget
    for tab in gBrowser.tabs
      if browser = gBrowser.getBrowserForTab(tab)
        vimBucket.forget(browser.contentWindow)

  TabClose: (event) ->
    return unless { gBrowser } = utils.getEventRootWindow(event) ? {}
    return unless browser = gBrowser.getBrowserForTab(event.originalTarget)
    vimBucket.forget(browser.contentWindow)

  # Update the toolbar button icon to reflect the blacklisted state
  TabSelect: (event) ->
    return unless vim = vimBucket.get(event.originalTarget?.linkedBrowser?.contentDocument?.defaultView)
    return unless rootWindow = utils.getRootWindow(vim.window)
    updateToolbarButton(rootWindow, {blacklisted: vim.blacklisted})

# This listener works on individual tabs within Chrome Window
# User for: listening for location changes and disabling the extension
# on black listed urls
tabsListener =
  onLocationChange: (browser, webProgress, request, location) ->
    return unless vim = vimBucket.get(browser.contentWindow)

    vim.enterNormalMode()

    return unless rootWindow = utils.getRootWindow(vim.window)
    vim.blacklisted = utils.isBlacklisted(location.spec)
    updateToolbarButton(rootWindow, {blacklisted: vim.blacklisted})

addEventListeners = (window) ->
  for name, listener of windowsListener
    window.addEventListener(name, listener, true)

  # Install onLocationChange listener
  window.gBrowser.addTabsProgressListener(tabsListener)

  removeEventListeners = ->
    for name, listener of windowsListener
      window.removeEventListener(name, listener, true)

  unload ->
    removeEventListeners(window)
    window.gBrowser.removeTabsProgressListener(tabsListener)

exports.addEventListeners = addEventListeners
