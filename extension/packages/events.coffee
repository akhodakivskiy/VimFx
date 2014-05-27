utils                   = require 'utils'
keyUtils                = require 'key-utils'
{ Vim }                 = require 'vim'
{ getPref }             = require 'prefs'
{ updateToolbarButton } = require 'button'
{ unload }              = require 'unload'

{ interfaces: Ci } = Components

HTMLDocument = Ci.nsIDOMHTMLDocument

vimBucket = new utils.Bucket(utils.getWindowId, (w) -> new Vim(w))

keyStrFromEvent = (event) ->
  { ctrlKey: ctrl, metaKey: meta, altKey: alt, shiftKey: shift } = event

  if !meta and !alt
    return unless keyChar = keyUtils.keyCharFromCode(event.keyCode, shift)
    keyStr = keyUtils.applyModifiers(keyChar, ctrl, alt, meta)
    return keyStr

  return null

# When a menu or panel is shown VimFx should temporarily stop processing keyboard input, allowing
# accesskeys to be used.
popupPassthrough = false
checkPassthrough = (event) ->
  if event.target.nodeName in ['menupopup', 'panel']
    popupPassthrough = switch event.type
      when 'popupshown'  then true
      when 'popuphidden' then false

suppress = false
suppressEvent = (event) ->
  event.preventDefault()
  event.stopPropagation()

# Returns the appropriate vim instance for `event`, but only if it’s okay to do
# so. VimFx must not be disabled or blacklisted.
getVimFromEvent = (event) ->
  return if getPref('disabled')
  return unless window = utils.getEventCurrentTabWindow(event)
  return unless vim = vimBucket.get(window)
  return if vim.blacklisted

  return vim

removeVimFromTab = (tab, gBrowser) ->
  return unless browser = gBrowser.getBrowserForTab(tab)
  vimBucket.forget(browser.contentWindow)

updateButton = (vim) ->
  updateToolbarButton(vim.rootWindow, {blacklisted: vim.blacklisted, insertMode: vim.mode == 'insert'})

# The following listeners are installed on every top level Chrome window
windowsListeners =
  keydown: (event) ->
    try
      # No matter what, always reset the `suppress` flag, so we don't suppress more than intended.
      suppress = false

      if popupPassthrough
        # The `popupPassthrough` flag is set a bit unreliably. Sometimes it can be stuck as `true`
        # even though no popup is shown, effectively disabling the extension. Therefore we check
        # if there actually _are_ any open popups before stopping processing keyboard input. This is
        # only done when popups (might) be open (not on every keystroke) of performance reasons.
        return unless rootWindow = utils.getEventRootWindow(event)
        popups = rootWindow.document.querySelectorAll('menupopup, panel')
        for popup in popups
          return if popup.state == 'open'
        popupPassthrough = false # No popup was actually open: Reset the flag.

      return unless vim = getVimFromEvent(event)
      return unless keyStr = keyStrFromEvent(event)
      suppress = vim.onInput(keyStr, event)

      suppressEvent(event) if suppress

    catch error
      console.error("#{ error }\n#{ error.stack?.replace(/@.+-> /g, '@') }")

  # Note that the below event listeners can suppress the event even in blacklisted sites. That's
  # intentional. For example, if you press 'x' to close the current tab, it will close before keyup
  # fires. So keyup (and perhaps keypress) will fire in another tab. Even if that particular tab is
  # blacklisted, we must suppress the event, so that 'x' isn't sent to the page. The rule is simple:
  # If the `suppress` flag is `true`, the event should be suppressed, no matter what. It has the
  # highest priority.
  keypress: (event) -> suppressEvent(event) if suppress
  keyup: (event) -> suppressEvent(event) if suppress

  popupshown:  checkPassthrough
  popuphidden: checkPassthrough

  focus: (event) ->
    return unless getPref('prevent_autofocus')

    target = event.originalTarget
    return unless target.ownerDocument instanceof HTMLDocument

    # We only prevent autofocus from editable elements, that is, elements that
    # can “steal” the keystrokes, in order not to interfere too much.
    return unless utils.isElementEditable(target)

    return unless vim = getVimFromEvent(event)

    # Focus events can occur before DOMContentLoaded, both when the `autofocus`
    # attribute is used, and when a script contains `element.focus()`. If so,
    # `vim.lastLoad` isn’t set yet and we should blur the target. If
    # DOMContentLoaded already has fired we blur only if the focus happens
    # within a second after it.
    if !vim.lastLoad or Date.now() - vim.lastLoad < 1000
      target.blur()

  # Record when the page was loaded. This is used by the autofocus prevention feature.
  DOMContentLoaded: (event) ->
    target = event.originalTarget
    return unless target instanceof HTMLDocument
    return unless vim = getVimFromEvent(event)

    # Some pages (at least amazon.com) loads weirdly, firing DOMContentLoaded
    # many times. Therefore we only set `vim.lastLoad` if it wasn’t set
    # already. Otherwise too many focus events might be considered to be
    # autofocus events and thus blurred, even though the user might have
    # focused something on his own.
    if !vim.lastLoad
      vim.lastLoad = Date.now()
    return

  # When the top level window closes we should release all Vims that were
  # associated with tabs in this window
  DOMWindowClose: (event) ->
    { gBrowser } = event.originalTarget
    return unless gBrowser
    for tab in gBrowser.tabs
      removeVimFromTab(tab, gBrowser)

  TabClose: (event) ->
    { gBrowser } = utils.getEventRootWindow(event) ? {}
    return unless gBrowser
    tab = event.originalTarget
    removeVimFromTab(tab, gBrowser)

  # Update the toolbar button icon to reflect the blacklisted state
  TabSelect: (event) ->
    return unless window = event.originalTarget?.linkedBrowser?.contentDocument?.defaultView
    return unless vim = vimBucket.get(window)
    updateButton(vim)


# This listener works on individual tabs within Chrome Window
tabsListener =
  onLocationChange: (browser, webProgress, request, location) ->
    return unless vim = vimBucket.get(browser.contentWindow)

    # Mark the new location as not loaded yet.
    vim.lastLoad = null

    # If the location changes when in hints mode (for example because the reload button has been
    # clicked), we're going to end up in hints mode without any markers. So switch back to normal
    # mode in that case.
    if vim.mode == 'hints'
      vim.enterMode('normal')

    # Update the blacklist state.
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
