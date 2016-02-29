###
# Copyright Anton Khodakivskiy 2012, 2013, 2014.
# Copyright Simon Lydell 2013, 2014, 2015, 2016.
# Copyright Wang Zhuochun 2013.
#
# This file is part of VimFx.
#
# VimFx is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# VimFx is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with VimFx.  If not, see <http://www.gnu.org/licenses/>.
###

# This file contains lots of different helper functions.

{OS} = Components.utils.import('resource://gre/modules/osfile.jsm')

nsIClipboardHelper = Cc['@mozilla.org/widget/clipboardhelper;1']
  .getService(Ci.nsIClipboardHelper)
nsIDomUtils = Cc['@mozilla.org/inspector/dom-utils;1']
  .getService(Ci.inIDOMUtils)
nsIEventListenerService = Cc['@mozilla.org/eventlistenerservice;1']
  .getService(Ci.nsIEventListenerService)
nsIFocusManager = Cc['@mozilla.org/focus-manager;1']
  .getService(Ci.nsIFocusManager)
nsIStyleSheetService = Cc['@mozilla.org/content/style-sheet-service;1']
  .getService(Ci.nsIStyleSheetService)
nsIWindowMediator = Cc['@mozilla.org/appshell/window-mediator;1']
  .getService(Ci.nsIWindowMediator)

# For XUL, `instanceof` checks are often better than `.localName` checks,
# because some of the below interfaces are extended by many elements.
XULDocument = Ci.nsIDOMXULDocument
XULButtonElement = Ci.nsIDOMXULButtonElement
XULControlElement = Ci.nsIDOMXULControlElement
XULMenuListElement = Ci.nsIDOMXULMenuListElement
XULTextBoxElement = Ci.nsIDOMXULTextBoxElement

# Full chains of events for different mouse actions. ('command' is for XUL
# elements.)
EVENTS_CLICK       = ['mousedown', 'mouseup', 'click', 'command']
EVENTS_HOVER_START = ['mouseover', 'mouseenter', 'mousemove']
EVENTS_HOVER_END   = ['mouseout',  'mouseleave']



# Element classification helpers

isActivatable = (element) ->
  return element.localName in ['a', 'button'] or
         (element.localName == 'input' and element.type in [
           'button', 'submit', 'reset', 'image'
         ]) or
         element instanceof XULButtonElement

isAdjustable = (element) ->
  return element.localName == 'input' and element.type in [
           'checkbox', 'radio', 'file', 'color'
           'date', 'time', 'datetime', 'datetime-local', 'month', 'week'
         ] or
         element.localName in ['video', 'audio', 'embed', 'object'] or
         element instanceof XULControlElement or
         # Youtube special case.
         element.classList?.contains('html5-video-player') or
         element.classList?.contains('ytp-button') or
         # Allow navigating object inspection trees in th devtools with the
         # arrow keys, even if the arrow keys are used as VimFx shortcuts.
         element.ownerGlobal?.DevTools

isContentEditable = (element) ->
  return element.isContentEditable or
         isIframeEditor(element) or
         # Google.
         element.getAttribute?('g_editable') == 'true' or
         element.ownerDocument?.body?.getAttribute?('g_editable') == 'true' or
         # Codeacademy terminals.
         element.classList?.contains('real-terminal')

isIframeEditor = (element) ->
  return false unless element.localName == 'body'
  return \
         # Etherpad.
         element.id == 'innerdocbody' or
         # XpressEditor.
         (element.classList?.contains('xe_content') and
          element.classList?.contains('editable')) or
         # vBulletin.
         element.classList?.contains('wysiwyg') or
         # The wasavi extension.
         element.hasAttribute?('data-wasavi-state')

isIgnoreModeFocusType = (element) ->
  return \
    # The wasavi extension.
    element.hasAttribute?('data-wasavi-state') or
    element.closest?('#wasavi_container') or
    # CodeMirror in Vim mode.
    (element.localName == 'textarea' and
     element.closest?('.CodeMirror') and _hasVimEventListener(element))

# CodeMirror’s Vim mode is really sucky to detect. The only way seems to be to
# check if the there are any event listener functions with Vim-y words in them.
_hasVimEventListener = (element) ->
  for listener in nsIEventListenerService.getListenerInfoFor(element)
    if listener.listenerObject and
       /\bvim\b|insertmode/i.test(String(listener.listenerObject))
      return true
  return false

isProperLink = (element) ->
  # `.getAttribute` is used below instead of `.hasAttribute` to exclude `<a
  # href="">`s used as buttons on some sites.
  return element.getAttribute?('href') and
         (element.localName == 'a' or
          element.ownerDocument instanceof XULDocument) and
         not element.href?.endsWith?('#') and
         not element.href?.endsWith?('#?') and
         not element.href?.startsWith?('javascript:')

isTextInputElement = (element) ->
  return (element.localName == 'input' and element.type in [
           'text', 'search', 'tel', 'url', 'email', 'password', 'number'
         ]) or
         element.localName == 'textarea' or
         element instanceof XULTextBoxElement or
         isContentEditable(element)

isTypingElement = (element) ->
  return isTextInputElement(element) or
         # `<select>` elements can also receive text input: You may type the
         # text of an item to select it.
         element.localName == 'select' or
         element instanceof XULMenuListElement



# Active/focused element helpers

# NOTE: In frame scripts, `document.activeElement` may be `null` when the page
# is loading. Therefore always check if anything was returned, such as:
#
#     return unless activeElement = utils.getActiveElement(window)
getActiveElement = (window) ->
  {activeElement} = window.document
  return null unless activeElement
  # If the active element is a frame, recurse into it. The easiest way to detect
  # a frame that works both in browser UI and in web page content is to check
  # for the presence of `.contentWindow`. However, in non-multi-process
  # `<browser>` (sometimes `<xul:browser>`) elements have a `.contentWindow`
  # pointing to the web page content `window`, which we don’t want to recurse
  # into. This seems to be the only way to detect such elements.
  if activeElement.localName != 'browser' and activeElement.contentWindow
    return getActiveElement(activeElement.contentWindow)
  else
    return activeElement

blurActiveElement = (window) ->
  # Blurring a frame element also blurs any active elements inside it. Recursing
  # into the frames and blurring the “real” active element directly would give
  # focus to the `<body>` of its containing frame, while blurring the top-most
  # frame gives focus to the top-most `<body>`. This allows to blur fancy text
  # editors which use an `<iframe>` as their text area.
  window.document.activeElement?.blur()

blurActiveBrowserElement = (vim) ->
  # - Blurring in the next tick allows to pass `<escape>` to the location bar to
  #   reset it, for example.
  # - Focusing the current browser afterwards allows to pass `<escape>` as well
  #   as unbound keys to the page. However, focusing the browser also triggers
  #   focus events on `document` and `window` in the current page. Many pages
  #   re-focus some text input on those events, making it impossible to blur
  #   those! Therefore we tell the frame script to suppress those events.
  {window} = vim
  activeElement = getActiveElement(window)
  vim._send('browserRefocus')
  nextTick(window, ->
    activeElement.blur()
    window.gBrowser.selectedBrowser.focus()
  )

# Focus an element and tell Firefox that the focus happened because of a user
# action (not just because some random programmatic focus). `.FLAG_BYKEY` might
# look more appropriate, but it unconditionally selects all text, which
# `.FLAG_BYMOUSE` does not.
focusElement = (element, options = {}) ->
  nsIFocusManager.setFocus(element, options.flag ? 'FLAG_BYMOUSE')
  element.select?() if options.select

getFocusType = (element) -> switch
  when isIgnoreModeFocusType(element)
    'ignore'
  when isTypingElement(element)
    'editable'
  when isActivatable(element)
    'activatable'
  when isAdjustable(element)
    'adjustable'
  # TODO: Remove when Tab Groups have been removed.
  when element.ownerGlobal?.TabView?.isVisible?()
    'other'
  else
    'none'



# Event helpers

listen = (element, eventName, listener, useCapture = true) ->
  element.addEventListener(eventName, listener, useCapture)
  module.onShutdown(->
    element.removeEventListener(eventName, listener, useCapture)
  )

listenOnce = (element, eventName, listener, useCapture = true) ->
  fn = (event) ->
    listener(event)
    element.removeEventListener(eventName, fn, useCapture)
  listen(element, eventName, fn, useCapture)

onRemoved = (window, element, fn) ->
  mutationObserver = new window.MutationObserver((changes) ->
    for change in changes then for removedElement in change.removedNodes
      if removedElement == element
        mutationObserver.disconnect()
        fn()
        return
  )
  mutationObserver.observe(element.parentNode, {childList: true})
  module.onShutdown(mutationObserver.disconnect.bind(mutationObserver))

suppressEvent = (event) ->
  event.preventDefault()
  event.stopPropagation()

simulateMouseEvents = (element, sequenceType) ->
  window = element.ownerGlobal
  rect = element.getBoundingClientRect()

  eventSequence = switch sequenceType
    when 'click'
      EVENTS_CLICK
    when 'hover-start'
      EVENTS_HOVER_START
    when 'hover-end'
      EVENTS_HOVER_END

  for type in eventSequence
    buttonNum = if type in EVENTS_CLICK then 1 else 0
    mouseEvent = new window.MouseEvent(type, {
      # Let the event bubble in order to trigger delegated event listeners.
      bubbles: type not in ['mouseenter', 'mouseleave']
      # Make the event cancelable so that `<a href="#">` can be used as a
      # JavaScript-powered button without scrolling to the top of the page.
      cancelable: type not in ['mouseenter', 'mouseleave']
      # These properties are just here for mimicing a real click as much as
      # possible.
      buttons: buttonNum
      detail: buttonNum
      view: window
      # `page{X,Y}` are set automatically to the correct values when setting
      # `client{X,Y}`. `{offset,layer,movement}{X,Y}` are not worth the trouble
      # to set.
      clientX: rect.left
      clientY: rect.top
      # To exactly calculate `screen{X,Y}` one has to to check where the web
      # page content area is inside the browser chrome and go through all parent
      # frames as well. This is good enough. YAGNI for now.
      screenX: window.screenX + rect.left
      screenY: window.screenY + rect.top
    })
    element.dispatchEvent(mouseEvent)

  return



# DOM helpers

area = (element) ->
  return element.clientWidth * element.clientHeight

containsDeep = (parent, element) ->
  parentWindow = parent.ownerGlobal
  elementWindow = element.ownerGlobal

  # Owner windows might be missing when opening the devtools.
  while elementWindow and parentWindow and
        elementWindow != parentWindow and elementWindow.top != elementWindow
    element = elementWindow.frameElement
    elementWindow = element.ownerGlobal

  return parent.contains(element)

createBox = (document, className = '', parent = null, text = null) ->
  box = document.createElement('box')
  box.className = "#{className} vimfx-box"
  box.textContent = text if text?
  parent.appendChild(box) if parent?
  return box

# Returns the minimum of `element.clientHeight` and the height of the viewport,
# taking fixed headers and footers into account. Adapted from Firefox’s source
# code for `<space>` scrolling (which is where the arbitrary constants below
# come from).
#
# coffeelint: disable=max_line_length
# <https://hg.mozilla.org/mozilla-central/file/4d75bd6fd234/layout/generic/nsGfxScrollFrame.cpp#l3829>
# coffeelint: enable=max_line_length
getViewportCappedClientHeight = (element) ->
  window = element.ownerGlobal
  viewport = getWindowViewport(window)
  headerBottom = viewport.top
  footerTop = viewport.bottom
  maxHeight = viewport.height / 3
  minWidth = Math.min(viewport.width / 2, 800)

  # Restricting the candidates for headers and footers to the most likely set of
  # elements results in a noticeable performance boost.
  candidates = window.document.querySelectorAll(
    'div, ul, nav, header, footer, section'
  )

  for candidate in candidates
    rect = candidate.getBoundingClientRect()
    continue unless rect.height <= maxHeight and rect.width >= minWidth
    # Checking for `position: fixed;` is the absolutely most expensive
    # operation, so that is done last.
    switch
      when rect.top <= headerBottom and rect.bottom > headerBottom and
           isPositionFixed(candidate)
        headerBottom = rect.bottom
      when rect.bottom >= footerTop and rect.top < footerTop and
           isPositionFixed(candidate)
        footerTop = rect.top

  return Math.min(element.clientHeight, footerTop - headerBottom)

getWindowViewport = (window) ->
  {
    clientWidth, clientHeight # Viewport size excluding scrollbars, usually.
    scrollWidth, scrollHeight
  } = window.document.documentElement
  {innerWidth, innerHeight} = window # Viewport size including scrollbars.
  # We don’t want markers to cover the scrollbars, so we should use
  # `clientWidth` and `clientHeight`. However, when there are no scrollbars
  # those might be too small. Then we use `innerWidth` and `innerHeight`.
  width  = if scrollWidth  > innerWidth  then clientWidth  else innerWidth
  height = if scrollHeight > innerHeight then clientHeight else innerHeight
  return {
    left: 0
    top: 0
    right: width
    bottom: height
    width
    height
  }

injectTemporaryPopup = (document, contents) ->
  popup = document.createElement('menupopup')
  popup.appendChild(contents)
  document.getElementById('mainPopupSet').appendChild(popup)
  listenOnce(popup, 'popuphidden', popup.remove.bind(popup))
  return popup

insertText = (input, value) ->
  {selectionStart, selectionEnd} = input
  input.value =
    input.value[0...selectionStart] + value + input.value[selectionEnd..]
  input.selectionStart = input.selectionEnd = selectionStart + value.length

isPositionFixed = (element) ->
  computedStyle = element.ownerGlobal.getComputedStyle(element)
  return computedStyle?.getPropertyValue('position') == 'fixed'

querySelectorAllDeep = (window, selector) ->
  elements = Array.from(window.document.querySelectorAll(selector))
  for frame in window.frames
    elements.push(querySelectorAllDeep(frame, selector)...)
  return elements

scroll = (element, args) ->
  {method, type, directions, amounts, properties, adjustment, smooth} = args
  options = {}
  for direction, index in directions
    amount = amounts[index]
    options[direction] = -Math.sign(amount) * adjustment + switch type
      when 'lines'
        amount
      when 'pages'
        amount *
          if properties[index] == 'clientHeight'
            getViewportCappedClientHeight(element)
          else
            element[properties[index]]
      when 'other'
        Math.min(amount, element[properties[index]])
  options.behavior = 'smooth' if smooth
  element[method](options)

setAttributes = (element, attributes) ->
  for attribute, value of attributes
    element.setAttribute(attribute, value)
  return

setHover = (element, hover) ->
  method = if hover then 'addPseudoClassLock' else 'removePseudoClassLock'
  while element.parentElement
    nsIDomUtils[method](element, ':hover')
    element = element.parentElement
  return



# Language helpers

class Counter
  constructor: ({start: @value = 0, @step = 1}) ->
  tick: -> @value += @step

class EventEmitter
  constructor: ->
    @listeners = {}

  on: (event, listener) ->
    (@listeners[event] ?= new Set()).add(listener)

  off: (event, listener) ->
    @listeners[event]?.delete(listener)

  emit: (event, data) ->
    @listeners[event]?.forEach((listener) ->
      listener(data)
    )

has = (obj, prop) -> Object::hasOwnProperty.call(obj, prop)

# Check if `search` exists in `string` (case insensitively). Returns `false` if
# `string` doesn’t exist or isn’t a string, such as `<SVG element>.className`.
includes = (string, search) ->
  return false unless typeof string == 'string'
  return string.toLowerCase().includes(search)


nextTick = (window, fn) -> window.setTimeout((-> fn()) , 0)

regexEscape = (s) -> s.replace(/[|\\{}()[\]^$+*?.]/g, '\\$&')

removeDuplicates = (array) -> Array.from(new Set(array))

# Remove duplicate characters from string (case insensitive).
removeDuplicateCharacters = (str) ->
  return removeDuplicates( str.toLowerCase().split('') ).join('')

# Calls `fn` repeatedly, with at least `interval` ms between each call.
interval = (window, interval, fn) ->
  stopped = false
  currentIntervalId = null
  next = ->
    return if stopped
    currentIntervalId = window.setTimeout((-> fn(next)), interval)
  clearInterval = ->
    stopped = true
    window.clearTimeout(currentIntervalId)
  next()
  return clearInterval



# Misc helpers

expandPath = (path) ->
  if path.startsWith('~/') or path.startsWith('~\\')
    return OS.Constants.Path.homeDir + path[1..]
  else
    return path

formatError = (error) ->
  stack = String(error.stack?.formattedStack ? error.stack ? '')
    .split('\n')
    .filter((line) -> line.includes('.xpi!'))
    .map((line) -> '  ' + line.replace(/(?:\/<)*@.+\.xpi!/g, '@'))
    .join('\n')
  return "#{error}\n#{stack}"

getCurrentLocation = ->
  window = getCurrentWindow()
  return new window.URL(window.gBrowser.selectedBrowser.currentURI.spec)

getCurrentWindow = -> nsIWindowMediator.getMostRecentWindow('navigator:browser')

hasEventListeners = (element, type) ->
  for listener in nsIEventListenerService.getListenerInfoFor(element)
    if listener.listenerObject and listener.type == type
      return true
  return false

loadCss = (uriString) ->
  uri = Services.io.newURI(uriString, null, null)
  method = nsIStyleSheetService.AUTHOR_SHEET
  unless nsIStyleSheetService.sheetRegistered(uri, method)
    nsIStyleSheetService.loadAndRegisterSheet(uri, method)
  module.onShutdown(->
    nsIStyleSheetService.unregisterSheet(uri, method)
  )

observe = (topic, observer) ->
  observer = {observe: observer} if typeof observer == 'function'
  Services.obs.addObserver(observer, topic, false)
  module.onShutdown(->
    Services.obs.removeObserver(observer, topic, false)
  )

openPopup = (popup) ->
  window = popup.ownerGlobal
  # Show the popup so it gets a height and width.
  popup.openPopupAtScreen(0, 0)
  # Center the popup inside the window.
  popup.moveTo(
    window.screenX + window.outerWidth  / 2 - popup.clientWidth  / 2,
    window.screenY + window.outerHeight / 2 - popup.clientHeight / 2
  )

openTab = (window, url, options) ->
  {gBrowser} = window
  window.TreeStyleTabService?.readyToOpenChildTab(gBrowser.selectedTab)
  gBrowser.loadOneTab(url, options)

writeToClipboard = (text) -> nsIClipboardHelper.copyString(text)



module.exports = {
  isActivatable
  isAdjustable
  isContentEditable
  isIframeEditor
  isIgnoreModeFocusType
  isProperLink
  isTextInputElement
  isTypingElement

  getActiveElement
  blurActiveElement
  blurActiveBrowserElement
  focusElement
  getFocusType

  listen
  listenOnce
  onRemoved
  suppressEvent
  simulateMouseEvents

  area
  containsDeep
  createBox
  getViewportCappedClientHeight
  getWindowViewport
  injectTemporaryPopup
  insertText
  isPositionFixed
  querySelectorAllDeep
  scroll
  setAttributes
  setHover

  Counter
  EventEmitter
  has
  includes
  nextTick
  regexEscape
  removeDuplicates
  removeDuplicateCharacters
  interval

  expandPath
  formatError
  getCurrentLocation
  getCurrentWindow
  hasEventListeners
  loadCss
  observe
  openPopup
  openTab
  writeToClipboard
}
