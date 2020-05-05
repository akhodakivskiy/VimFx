# This file contains lots of different helper functions.

{OS} = Components.utils.import('resource://gre/modules/osfile.jsm', {})

nsIClipboardHelper = Cc['@mozilla.org/widget/clipboardhelper;1']
  .getService(Ci.nsIClipboardHelper)
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
XULButtonElement = Ci.nsIDOMXULButtonElement
XULControlElement = Ci.nsIDOMXULControlElement
XULMenuListElement = Ci.nsIDOMXULMenuListElement

# Traverse the DOM upwards until we hit its containing document (most likely an
# HTMLDocument or (<=fx68) XULDocument) or the ShadowRoot.
getDocument = (e) -> if e.parentNode? then arguments.callee(e.parentNode) else e

isInShadowRoot = (element) ->
  ShadowRoot? and getDocument(element) instanceof ShadowRoot

isXULElement = (element) ->
  XUL_NS = 'http://www.mozilla.org/keymaster/gatekeeper/there.is.only.xul'
  element.namespaceURI == XUL_NS

# Full chains of events for different mouse actions. Note: 'click' is fired
# by Firefox automatically after 'mousedown' and 'mouseup'. Similarly,
# 'command' is fired automatically after 'click' on xul pages.
EVENTS_CLICK       = ['mousedown', 'mouseup']
EVENTS_CLICK_XUL   = ['click']
EVENTS_CONTEXT     = ['contextmenu']
EVENTS_HOVER_START = ['mouseover', 'mouseenter', 'mousemove']
EVENTS_HOVER_END   = ['mouseout',  'mouseleave']



# Element classification helpers

hasMarkableTextNode = (element) ->
  return Array.prototype.some.call(element.childNodes, (node) ->
    # Ignore whitespace-only text nodes, and single-letter ones (which are
    # common in many syntax highlighters).
    return node.nodeType == 3 and node.data.trim().length > 1
  )

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
         # Custom video players.
         includes(element.className, 'video') or
         includes(element.className, 'player') or
         # Youtube special case.
         element.classList?.contains('ytp-button') or
         # Allow navigating object inspection trees in th devtools with the
         # arrow keys, even if the arrow keys are used as VimFx shortcuts.
         isDevtoolsElement(element)

isContentEditable = (element) ->
  return element.isContentEditable or
         isIframeEditor(element) or
         # Google.
         element.getAttribute?('g_editable') == 'true' or
         element.ownerDocument?.body?.getAttribute?('g_editable') == 'true' or
         # Codeacademy terminals.
         element.classList?.contains('real-terminal')

isDevtoolsElement = (element) ->
  return false unless element.ownerGlobal
  return Array.prototype.some.call(
    element.ownerGlobal.top.frames, isDevtoolsWindow
   )

isDevtoolsWindow = (window) ->
  # Note: this function is called for each frame by isDevtoolsElement. When
  # called on an out-of-process iframe, accessing .href will fail with
  # SecurityError; the `try` around it makes it `undefined` in such a case.
  return (try window.location?.href) in [
    'about:devtools-toolbox'
    'chrome://devtools/content/framework/toolbox.xul'
    'chrome://devtools/content/framework/toolbox.xhtml' # fx72+
  ]

# Note: this is possibly a bit overzealous, but Works For Now™.
isDockedDevtoolsElement = (element) ->
  return element.ownerDocument.URL.startsWith('chrome://devtools/content/')

isFocusable = (element) ->
  # Focusable elements have `.tabIndex > 1` (but not necessarily a
  # `tabindex="…"` attribute) …
  return (element.tabIndex > -1 or
          # … or an explicit `tabindex="-1"` attribute (which means that it is
          # focusable, but not reachable with `<tab>`).
          element.getAttribute?('tabindex') == '-1') and
         not (element.localName?.endsWith?('box') and
              element.localName != 'checkbox') and
         not (element.localName == 'toolbarbutton' and
              element.parentNode?.localName == 'toolbarbutton') and
         element.localName not in ['tabs', 'menuitem', 'menuseparator']

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
         # TYPO3 CMS.
         element.classList?.contains('htmlarea-content-body') or
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
           (isXULElement(element) and
            element.localName == 'label' and
            element.getAttribute('is') == 'text-link')) and
         not element.href?.endsWith?('#') and
         not element.href?.endsWith?('#?') and
         not element.href?.startsWith?('javascript:')

isTextInputElement = (element) ->
  return (element.localName == 'input' and element.type in [
           'text', 'search', 'tel', 'url', 'email', 'password', 'number'
         ]) or
         element.localName in [ 'textarea', 'textbox' ] or
         isContentEditable(element)

isTypingElement = (element) ->
  return isTextInputElement(element) or
         # `<select>` elements can also receive text input: You may type the
         # text of an item to select it.
         element.localName == 'select' or
         element instanceof XULMenuListElement



# Active/focused element helpers

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
  activeElement.closest('tabmodalprompt')?.abortPrompt()
  vim._send('browserRefocus')
  nextTick(window, ->
    activeElement.blur()
    window.gBrowser.selectedBrowser.focus()
  )

blurActiveElement = (window) ->
  # Blurring a frame element also blurs any active elements inside it. Recursing
  # into the frames and blurring the “real” active element directly would give
  # focus to the `<body>` of its containing frame, while blurring the top-most
  # frame gives focus to the top-most `<body>`. This allows to blur fancy text
  # editors which use an `<iframe>` as their text area.
  # Note that this trick does not work with Web Components; for them, recursing
  # is necessary.
  if window.document.activeElement?.shadowRoot?
    return getActiveElement(window)?.blur()
  window.document.activeElement?.blur()

# Focus an element and tell Firefox that the focus happened because of a user
# action (not just because some random programmatic focus). `.FLAG_BYKEY` might
# look more appropriate, but it unconditionally selects all text, which
# `.FLAG_BYMOUSE` does not.
focusElement = (element, options = {}) ->
  nsIFocusManager.setFocus(element, options.flag ? 'FLAG_BYMOUSE')
  element.select?() if options.select

# NOTE: In frame scripts, `document.activeElement` may be `null` when the page
# is loading. Therefore always check if anything was returned, such as:
#
#     return unless activeElement = utils.getActiveElement(window)
getActiveElement = (window) ->
  {activeElement} = window.shadowRoot or window.document
  return null unless activeElement
  # If the active element is a frame, recurse into it. The easiest way to detect
  # a frame that works both in browser UI and in web page content is to check
  # for the presence of `.contentWindow`. However, in non-multi-process,
  # `<browser>` (sometimes `<xul:browser>`) elements have a `.contentWindow`
  # pointing to the web page content `window`, which we don’t want to recurse
  # into. The problem is that there are _some_ `<browser>`s which we _want_ to
  # recurse into, such as the sidebar (for instance the history sidebar), and
  # dialogs in `about:preferences`. Checking the `contextmenu` attribute seems
  # to be a reliable test, catching both the main tab `<browser>`s and bookmarks
  # opened in the sidebar.
  # We also want to recurse into the (open) shadow DOM of custom elements.
  if activeElement.shadowRoot?
    return getActiveElement(activeElement)
  else if activeElement.contentWindow and
      not (activeElement.localName == 'browser' and
      activeElement.getAttribute?('contextmenu') == 'contentAreaContextMenu')
    # with Fission enabled, the iframe might be located in a different process
    # (oop). Then, recursing into it isn't possible (throws SecurityError).
    return activeElement unless (try activeElement.contentWindow.document)

    return getActiveElement(activeElement.contentWindow)
  else
    return activeElement

getFocusType = (element) -> switch
  when element.tagName in ['FRAME', 'IFRAME'] and
       not (try element.contentWindow.document)
    # Encountered an out-of-process iframe, which we can't inspect. We fall
    # back to insert mode, so any text inputs it may contain are still usable.
    'editable'
  when isIgnoreModeFocusType(element)
    'ignore'
  when isTypingElement(element)
    if element.closest?('findbar') then 'findbar' else 'editable'
  when isActivatable(element)
    'activatable'
  when isAdjustable(element)
    'adjustable'
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

onRemoved = (element, fn) ->
  window = element.ownerGlobal

  disconnected = false
  disconnect = ->
    return if disconnected
    disconnected = true
    mutationObserver.disconnect() unless Cu.isDeadWrapper(mutationObserver)

  mutationObserver = new window.MutationObserver((changes) ->
    for change in changes then for removedElement in change.removedNodes
      if removedElement.contains?(element)
        disconnect()
        fn()
        return
  )
  mutationObserver.observe(window.document.documentElement, {
    childList: true
    subtree: true
  })
  module.onShutdown(disconnect)

  return disconnect

simulateMouseEvents = (element, sequence, browserOffset) ->
  window = element.ownerGlobal
  rect = element.getBoundingClientRect()
  topOffset = getTopOffset(element)

  eventSequence = switch sequence
    when 'click'
      EVENTS_CLICK
    when 'click-xul'
      EVENTS_CLICK_XUL
    when 'context'
      EVENTS_CONTEXT
    when 'hover-start'
      EVENTS_HOVER_START
    when 'hover-end'
      EVENTS_HOVER_END
    else
      sequence

  for type in eventSequence
    buttonNum = switch
      when type in EVENTS_CONTEXT
        2
      when type in EVENTS_CLICK
        1
      else
        0

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
      clientY: rect.top + rect.height / 2
      screenX: browserOffset.x + topOffset.x
      screenY: browserOffset.y + topOffset.y + rect.height / 2
    })

    if type == 'mousemove'
      # If the below technique is used for this event, the “URL popup” (shown
      # when hovering or focusing links) does not appear.
      element.dispatchEvent(mouseEvent)
    else if isInShadowRoot(element)
      # click events for links and other clickables inside the shadow DOM are
      # caught by the callee (.click_marker_element()).
      element.focus() if type == 'contextmenu' # for <input type=text>
      element.dispatchEvent(mouseEvent)
    else
      try
        (window.windowUtils.dispatchDOMEventViaPresShellForTesting or
         window.windowUtils.dispatchDOMEventViaPresShell # < fx73
        )(element, mouseEvent)
      catch error
        if error.result != Cr.NS_ERROR_UNEXPECTED
          throw error

  return

suppressEvent = (event) ->
  event.preventDefault()
  event.stopPropagation()



# DOM helpers

area = (element) ->
  return element.clientWidth * element.clientHeight

checkElementOrAncestor = (element, fn) ->
  window = element.ownerGlobal
  while element.parentElement
    return true if fn(element)
    element = element.parentElement
  return false

clearSelectionDeep = (window, {blur = true} = {}) ->
  # The selection might be `null` in hidden frames.
  selection = window.getSelection()
  selection?.removeAllRanges()
  # Note: accessing frameElement fails on oop iframes (fission); skip those.
  for frame in window.frames when (try frame.frameElement)
    clearSelectionDeep(frame, {blur})
    # Allow parents to re-gain control of text selection.
    frame.frameElement.blur() if blur
  return

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

# In quirks mode (when the page lacks a doctype), such as on Hackernews,
# `<body>` is considered the root element rather than `<html>`.
getRootElement = (document) ->
  if document.compatMode == 'BackCompat' and document.body?
    return document.body
  else
    return document.documentElement

getText = (element) ->
  text = element.textContent or element.value or element.placeholder or ''
  return text.trim().replace(/\s+/, ' ')

getTopOffset = (element) ->
  window = element.ownerGlobal

  {left: x, top: y} = element.getBoundingClientRect()
  while window.frameElement
    frame = window.frameElement
    frameRect = frame.getBoundingClientRect()
    x += frameRect.left
    y += frameRect.top

    computedStyle = frame.ownerGlobal.getComputedStyle(frame)
    if computedStyle
      x +=
        parseFloat(computedStyle.getPropertyValue('border-left-width')) +
        parseFloat(computedStyle.getPropertyValue('padding-left'))
      y +=
        parseFloat(computedStyle.getPropertyValue('border-top-width')) +
        parseFloat(computedStyle.getPropertyValue('padding-top'))

    window = window.parent
  return {x, y}

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

isDetached = (element) ->
  return not element.ownerDocument?.documentElement?.contains?(element)

isNonEmptyTextNode = (node) ->
  return node.nodeType == 3 and node.data.trim() != ''

querySelectorAllDeep = (window, selector) ->
  elements = Array.from(window.document.querySelectorAll(selector))
  for frame in window.frames
    elements.push(querySelectorAllDeep(frame, selector)...)
  return elements

selectAllSubstringMatches = (element, substring, {caseSensitive = true} = {}) ->
  window = element.ownerGlobal
  selection = window.getSelection()
  {textContent} = element

  format = (string) -> if caseSensitive then string else string.toLowerCase()
  offsets =
    getAllNonOverlappingRangeOffsets(format(textContent), format(substring))
  offsetsLength = offsets.length
  return if offsetsLength == 0

  textIndex = 0
  offsetsIndex = 0
  [currentOffset] = offsets
  searchIndex = currentOffset.start
  start = null

  walkTextNodes(element, (textNode) ->
    {length} = textNode.data
    return false if length == 0

    while textIndex + length > searchIndex
      if start
        range = window.document.createRange()
        range.setStart(start.textNode, start.offset)
        range.setEnd(textNode, currentOffset.end - textIndex)
        selection.addRange(range)

        offsetsIndex += 1
        return true if offsetsIndex >= offsetsLength
        currentOffset = offsets[offsetsIndex]

        start = null
        searchIndex = currentOffset.start

      else
        start = {textNode, offset: currentOffset.start - textIndex}
        searchIndex = currentOffset.end - 1

    textIndex += length
    return false
  )

selectElement = (element) ->
  window = element.ownerGlobal
  selection = window.getSelection()
  range = window.document.createRange()
  range.selectNodeContents(element)
  selection.addRange(range)

setAttributes = (element, attributes) ->
  for attribute, value of attributes
    element.setAttribute(attribute, value)
  return

walkTextNodes = (element, fn) ->
  for node in element.childNodes then switch node.nodeType
    when 3 # TextNode.
      stop = fn(node)
      return true if stop
    when 1 # Element.
      stop = walkTextNodes(node, fn)
      return true if stop
  return false



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

# Returns `[nonMatch, adjacentMatchAfter]`, where `adjacentMatchAfter - nonMatch
# == 1`. `fn(n)` is supposed to return `false` for `n <= nonMatch` and `true`
# for `n >= adjacentMatchAfter`. Both `nonMatch` and `adjacentMatchAfter` may be
# `null` if they cannot be found. Otherwise they’re in the range `min <= n <=
# max`. `[null, null]` is returned in non-sensical cases. This function is
# intended to be used as a faster alternative to something like this:
#
#     adjacentMatchAfter = null
#     for n in [min..max]
#       if fn(n)
#         adjacentMatchAfter = n
#         break
bisect = (min, max, fn) ->
  return [null, null] unless max - min >= 0 and min % 1 == 0 and max % 1 == 0

  while max - min > 1
    mid = min + (max - min) // 2
    match = fn(mid)
    if match
      max = mid
    else
      min = mid

  matchMin = fn(min)
  matchMax = fn(max)

  return switch
    when matchMin and matchMax
      [null, min]
    when not matchMin and not matchMax
      [max, null]
    when not matchMin and matchMax
      [min, max]
    else
      [null, null]

getAllNonOverlappingRangeOffsets = (string, substring) ->
  {length} = substring
  return [] if length == 0

  offsets = []
  lastOffset = {start: -Infinity, end: -Infinity}
  index = -1

  loop
    index = string.indexOf(substring, index + 1)
    break if index == -1
    if index > lastOffset.end
      lastOffset = {start: index, end: index + length}
      offsets.push(lastOffset)
    else
      lastOffset.end = index + length

  return offsets

has = (obj, prop) -> Object::hasOwnProperty.call(obj, prop)

# Check if `search` exists in `string` (case insensitively). Returns `false` if
# `string` doesn’t exist or isn’t a string, such as `<SVG element>.className`.
includes = (string, search) ->
  return false unless typeof string == 'string'
  return string.toLowerCase().includes(search)

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

nextTick = (window, fn) -> window.setTimeout((-> fn()) , 0)

overlaps = (rectA, rectB) ->
  return \
    Math.round(rectA.right) >= Math.round(rectB.left) and
    Math.round(rectA.left) <= Math.round(rectB.right) and
    Math.round(rectA.bottom) >= Math.round(rectB.top) and
    Math.round(rectA.top) <= Math.round(rectB.bottom)

partition = (array, fn) ->
  matching = []
  nonMatching = []
  for item, index in array
    if fn(item, index, array)
      matching.push(item)
    else
      nonMatching.push(item)
  return [matching, nonMatching]

regexEscape = (s) -> s.replace(/[|\\{}()[\]^$+*?.]/g, '\\$&')

removeDuplicateChars = (string) -> removeDuplicates(string.split('')).join('')

removeDuplicates = (array) -> Array.from(new Set(array))

sum = (numbers) -> numbers.reduce(((sum, number) -> sum + number), 0)



# Misc helpers

expandPath = (path) ->
  if path.startsWith('~/') or path.startsWith('~\\')
    return OS.Constants.Path.homeDir + path[1..]
  else
    return path

getCurrentLocation = ->
  return unless window = getCurrentWindow()
  return new window.URL(window.gBrowser.selectedBrowser.currentURI.spec)

# This function might return `null` on startup.
getCurrentWindow = -> nsIWindowMediator.getMostRecentWindow('navigator:browser')

# gBrowser getFindBar() used to return the findBar directly, but in recent
# versions it returns a promise. This function should be removed once these old
# versions are no longer supported.
getFindBar = (gBrowser) ->
  promiseOrFindBar = gBrowser.getFindBar()
  if promiseOrFindBar instanceof Promise
    promiseOrFindBar
  else
    Promise.resolve(promiseOrFindBar)

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

# Try to open a button’s dropdown menu, if any.
openDropdown = (element) ->
  if isXULElement(element) and
     element.getAttribute?('type') == 'menu' and
     element.open == false # Only change `.open` if it is already a boolean.
    element.open = true

openPopup = (popup) ->
  window = popup.ownerGlobal
  # Show the popup so it gets a height and width.
  popup.openPopupAtScreen(0, 0)
  # Center the popup inside the window.
  popup.moveTo(
    window.screenX + window.outerWidth  / 2 - popup.clientWidth  / 2,
    window.screenY + window.outerHeight / 2 - popup.clientHeight / 2
  )

writeToClipboard = (text) -> nsIClipboardHelper.copyString(text)



module.exports = {
  hasMarkableTextNode
  isActivatable
  isAdjustable
  isContentEditable
  isDevtoolsElement
  isDevtoolsWindow
  isDockedDevtoolsElement
  isFocusable
  isIframeEditor
  isIgnoreModeFocusType
  isProperLink
  isTextInputElement
  isTypingElement
  isXULElement
  isInShadowRoot

  blurActiveBrowserElement
  blurActiveElement
  focusElement
  getActiveElement
  getFocusType

  listen
  listenOnce
  onRemoved
  simulateMouseEvents
  suppressEvent

  area
  checkElementOrAncestor
  clearSelectionDeep
  containsDeep
  createBox
  getRootElement
  getText
  getTopOffset
  injectTemporaryPopup
  insertText
  isDetached
  isNonEmptyTextNode
  querySelectorAllDeep
  selectAllSubstringMatches
  selectElement
  setAttributes
  walkTextNodes

  Counter
  EventEmitter
  bisect
  getAllNonOverlappingRangeOffsets
  has
  includes
  interval
  nextTick
  overlaps
  partition
  regexEscape
  removeDuplicateChars
  removeDuplicates
  sum

  expandPath
  getCurrentLocation
  getCurrentWindow
  getFindBar
  hasEventListeners
  loadCss
  observe
  openDropdown
  openPopup
  writeToClipboard
}
