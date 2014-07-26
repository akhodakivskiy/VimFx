utils                   = require 'utils'
keyUtils                = require 'key-utils'
{ Vim }                 = require 'vim'
{ getPref }             = require 'prefs'
{ updateToolbarButton } = require 'button'
{ unload }              = require 'unload'

{ interfaces: Ci } = Components

HTMLDocument = Ci.nsIDOMHTMLDocument

vimBucket = new utils.Bucket((window) -> new Vim(window))

keyStrFromEvent = (event) ->
  { ctrlKey: ctrl, metaKey: meta, altKey: alt, shiftKey: shift } = event

  if !meta and !alt
    return unless keyChar = keyUtils.keyCharFromCode(event.key, shift)
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

# This function may be run several times, because:
#
# - It is assigned to several events. Whichever is fired first should mark
#   `vim` as loaded.
# - The events are fired for each frame of the document. Only the first of those
#   should mark `vim` as loaded. (This is very noticeable on amazon.com.)
#
# If we’d updated `vim.lastLoad` each time, too many focus events might be
# considered to be autofocus events and thus blurred, even though the user
# might have focused something on his own.
markVimLoaded = (event) ->
  target = event.originalTarget
  return unless target instanceof HTMLDocument
  return unless vim = getVimFromEvent(event)

  unless vim.loaded
    vim.loaded = true
    vim.lastLoad = Date.now()

markVimUnloaded = (event) ->
  target = event.originalTarget
  return unless target instanceof HTMLDocument
  return unless vim = getVimFromEvent(event)

  # Only mark `vim` as unloaded if the main document is the target, not some
  # frame inside the main document.
  if target == vim.window.document
    vim.loaded = false


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

  # `DOMContentLoaded` does not fire when going back and forward in the history
  # (nor does the `load` event), but `pageshow` does. Therefore we assign
  # `markVimLoaded` to both events. The reason we do not simply only use
  # `pageshow` is that it fires later than `DOMContentLoaded`: just after the
  # `load` event, which is a a bit too late, causing too many focus events to
  # be considered as autofocus events and thus blurred. But it fires quick
  # enough when going back and forward in the history, since then an in-memory
  # cache is used.
  DOMContentLoaded: markVimLoaded
  pageshow:         markVimLoaded

  # It is tempting to mark a `vim` instance as unloaded in the
  # `onLocationChange` event. However, if `history.pushState()` is used,
  # `onLocationChange` will fire, but load events such as `DOMContentLoaded`
  # and `pageshow` won’t. That means that the `vim` instance won’t be marked as
  # loaded again, which will cause _all_ focus events to be considered as
  # autofocus events, making it impossible to focus inputs.
  #
  # Therefore we use the `pagehide` event instead. It fires when the user
  # navigates away from the page (clicks a link, goes back and forward in the
  # history, enters something in the location bar etc.), but not when
  # `history.pushState()` is used.
  #
  # However, we still want to disable autofocus after a `history.pushState()`
  # call. Therefore we set `vim.lastLoad` in the `onLocationChange` event, so
  # that all focus events within one second after that get blurred.
  # `history.pushState()` is usually used together with a quick AJAX call, so
  # that second should be enough (as opposed to a full page request where
  # several seconds may pass between the location change and the actual page
  # load).
  pagehide: markVimUnloaded

  focus: (event) ->
    return unless getPref('prevent_autofocus')

    target = event.originalTarget
    return unless target.ownerDocument instanceof HTMLDocument

    # We only prevent autofocus from editable elements, that is, elements that
    # can “steal” the keystrokes, in order not to interfere too much.
    return unless utils.isElementEditable(target)

    return unless vim = getVimFromEvent(event)

    # Focus events can occur before DOMContentLoaded, both when the `autofocus`
    # attribute is used, and when a script contains `element.focus()`. So if
    # the `vim` instance isn’t marked as loaded, all focus events should be
    # blurred. Autofocus events can occur later, too. How much later? One
    # second seems to be a good compromise.
    if !vim.loaded or Date.now() - vim.lastLoad < 1000
      target.blur()

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

    vim.lastLoad = Date.now() # See the `pagehide` event.

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
