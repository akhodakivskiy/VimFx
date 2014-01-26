utils                   = require 'utils'
keyUtils                = require 'key-utils'
{ Vim }                 = require 'vim'
{ getPref }             = require 'prefs'
{ updateToolbarButton } = require 'button'
{ unload }              = require 'unload'

{ interfaces: Ci } = Components

vimBucket = new utils.Bucket(utils.getWindowId, (w) -> new Vim(w))

keyStrFromEvent = (event) ->
  { ctrlKey: ctrl, metaKey: meta, altKey: alt, shiftKey: shift } = event

  if !meta and !alt
    return unless keyChar = keyUtils.keyCharFromCode(event.keyCode, shift)
    keyStr = keyUtils.applyModifiers(keyChar, ctrl, alt, meta)
    return keyStr

  return null

# Passthrough mode is activated when VimFx should temporarily stop processing keyboard input, for
# example when a menu is shown.
popupPassthrough = false
checkPassthrough = (event) ->
  if event.target.nodeName in ['menupopup', 'panel']
    popupPassthrough = switch event.type
      when 'popupshown'  then true
      when 'popuphidden' then false

suppress = false
suppressEvent = (event) ->
  if suppress
    event.preventDefault()
    event.stopPropagation()

removeVimFromTab = (tab, gBrowser) ->
  return unless browser = gBrowser.getBrowserForTab(tab)
  vimBucket.forget(browser.contentWindow)

updateButton = (vim) ->
  return unless rootWindow = utils.getRootWindow(vim.window)
  updateToolbarButton(rootWindow, {blacklisted: vim.blacklisted, insertMode: vim.mode == 'insert'})

# The following listeners are installed on every top level Chrome window
windowsListeners =
  keydown: (event) ->
    try
      # No matter what, always reset the `suppress` flag, so we don't suppress more than intended.
      suppress = false

      # Suppress popup passthrough mode if there is no passthrough mode on the root document
      return if popupPassthrough and !!utils.getEventRootWindow(event).document.popupNode
      return if getPref('disabled')

      return unless window = utils.getEventCurrentTabWindow(event)
      return unless vim = vimBucket.get(window)

      return if vim.blacklisted

      return unless keyStr = keyStrFromEvent(event)
      suppress = vim.onInput(keyStr, event)

      suppressEvent(event)

    catch error
      console.error("#{ error }\n#{ error.stack?.replace(/@.+-> /g, '@') }")

  # Note that the below event listeners can suppress the event even in blacklisted sites. That's
  # intentional. For example, if you press 'x' to close the current tab, it will close before keyup
  # fires. So keyup (and perhaps keypress) will fire in another tab. Even if that particular tab is
  # blacklisted, we must suppress the event, so that 'x' isn't sent to the page. The rule is simple:
  # If the `suppress` flag is `true`, the event should be suppressed, no matter what. It has the
  # highest priority.
  keypress: suppressEvent
  keyup:    suppressEvent

  popupshown:  checkPassthrough
  popuphidden: checkPassthrough

  # When the top level window closes we should release all Vims that were
  # associated with tabs in this window
  DOMWindowClose: (event) ->
    return unless { gBrowser } = event.originalTarget
    for tab in gBrowser.tabs
      removeVimFromTab(tab, gBrowser)

  TabClose: (event) ->
    return unless { gBrowser } = utils.getEventRootWindow(event) ? {}
    tab = event.originalTarget
    removeVimFromTab(tab, gBrowser)

  # Update the toolbar button icon to reflect the blacklisted state
  TabSelect: (event) ->
    return unless window = event.originalTarget?.linkedBrowser?.contentDocument?.defaultView
    return unless vim = vimBucket.get(window)
    updateButton(vim)

# This listener works on individual tabs within Chrome Window
tabsListener =
  # Listenfor location changes and disable the extension on blacklisted urls
  onLocationChange: (browser, webProgress, request, location) ->
    return unless vim = vimBucket.get(browser.contentWindow)

    # If the location changes when in hints mode (for example because the reload button has been
    # clicked), we're going to end up in hints mode without any markers. So switch back to normal
    # mode in that case.
    if vim.mode == 'hints'
      vim.enterMode('normal')

    vim.blacklisted = utils.isBlacklisted(location.spec)
    updateButton(vim)

addEventListeners = (window) ->
  for name, listener of windowsListeners
    window.addEventListener(name, listener, true)

  window.gBrowser.addTabsProgressListener(tabsListener)

  unload ->
    for name, listener of windowsListeners
      window.removeEventListener(name, listener, true)

    window.gBrowser.removeTabsProgressListener(tabsListener)

exports.addEventListeners = addEventListeners
exports.vimBucket         = vimBucket
