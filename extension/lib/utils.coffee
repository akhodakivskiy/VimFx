###
# Copyright Anton Khodakivskiy 2012, 2013, 2014.
# Copyright Simon Lydell 2013, 2014.
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

{ classes: Cc, interfaces: Ci, utils: Cu } = Components

Window              = Ci.nsIDOMWindow
ChromeWindow        = Ci.nsIDOMChromeWindow
Element             = Ci.nsIDOMElement
HTMLDocument        = Ci.nsIDOMHTMLDocument
HTMLAnchorElement   = Ci.nsIDOMHTMLAnchorElement
HTMLButtonElement   = Ci.nsIDOMHTMLButtonElement
HTMLInputElement    = Ci.nsIDOMHTMLInputElement
HTMLTextAreaElement = Ci.nsIDOMHTMLTextAreaElement
HTMLSelectElement   = Ci.nsIDOMHTMLSelectElement
XULDocument         = Ci.nsIDOMXULDocument
XULButtonElement    = Ci.nsIDOMXULButtonElement
XULControlElement   = Ci.nsIDOMXULControlElement
XULMenuListElement  = Ci.nsIDOMXULMenuListElement
XULTextBoxElement   = Ci.nsIDOMXULTextBoxElement

class Bucket
  constructor: (@newFunc, @observer = null) ->
    @bucket = new WeakMap()

  get: (obj) ->
    if @bucket.has(obj)
      value = @bucket.get(obj)
    else
      value = @newFunc(obj)
      @bucket.set(obj, value)
    @observer.emit('bucket.get', value) if @observer
    return value

  forget: (obj) ->
    @bucket.delete(obj)

class EventEmitter
  constructor: ->
    @listeners = {}

  on: (event, listener) ->
    (@listeners[event] ?= []).push(listener)

  emit: (event, data) ->
    for listener in @listeners[event] ? []
      listener(data)
    return

getEventWindow = (event) ->
  if event.originalTarget instanceof Window
    return event.originalTarget
  else
    doc = event.originalTarget.ownerDocument or event.originalTarget
    if doc instanceof HTMLDocument or doc instanceof XULDocument
      return doc.defaultView

getEventRootWindow = (event) ->
  return unless window = getEventWindow(event)
  return getRootWindow(window)

getEventCurrentTabWindow = (event) ->
  return unless rootWindow = getEventRootWindow(event)
  return getCurrentTabWindow(rootWindow)

getRootWindow = (window) ->
  return window
    .QueryInterface(Ci.nsIInterfaceRequestor)
    .getInterface(Ci.nsIWebNavigation)
    .QueryInterface(Ci.nsIDocShellTreeItem)
    .rootTreeItem
    .QueryInterface(Ci.nsIInterfaceRequestor)
    .getInterface(Window)

getCurrentTabWindow = (window) ->
  return window.gBrowser.selectedTab.linkedBrowser.contentWindow

blurActiveElement = (window) ->
  # Only blur focusable elements, in order to interfere with the browser as
  # little as possible.
  { activeElement } = window.document
  if activeElement and activeElement.tabIndex > -1
    activeElement.blur()

isProperLink = (element) ->
  # `.getAttribute` is used below instead of `.hasAttribute` to exclude `<a
  # href="">`s used as buttons on some sites.
  return element.getAttribute('href') and
         (element instanceof HTMLAnchorElement or
          element.ownerDocument instanceof XULDocument) and
         not element.href.endsWith('#') and
         not element.href.startsWith('javascript:')

isTextInputElement = (element) ->
  return (element instanceof HTMLInputElement and element.type in [
           'text', 'search', 'tel', 'url', 'email', 'password', 'number'
         ]) or
         element instanceof HTMLTextAreaElement or
         # `<select>` elements can also receive text input: You may type the
         # text of an item to select it.
         element instanceof HTMLSelectElement or
         element instanceof XULMenuListElement or
         element instanceof XULTextBoxElement

isContentEditable = (element) ->
  return element.isContentEditable or
         isGoogleEditable(element)

isGoogleEditable = (element) ->
  # `g_editable` is a non-standard attribute commonly used by Google.
  return element.getAttribute?('g_editable') == 'true' or
         element.ownerDocument.body?.getAttribute('g_editable') == 'true'

isActivatable = (element) ->
  return element instanceof HTMLAnchorElement or
         element instanceof HTMLButtonElement or
         (element instanceof HTMLInputElement and element.type in [
           'button', 'submit', 'reset', 'image'
         ]) or
         element instanceof XULButtonElement

isAdjustable = (element) ->
  return element instanceof HTMLInputElement and element.type in [
           'checkbox', 'radio', 'file', 'color'
           'date', 'time', 'datetime', 'datetime-local', 'month', 'week'
         ] or
         element instanceof XULControlElement or
         # Youtube special case.
         element.classList?.contains('html5-video-player') or
         element.classList?.contains('ytp-button')

area = (element) ->
  return element.clientWidth * element.clientHeight

getSessionStore = ->
  Cc['@mozilla.org/browser/sessionstore;1'].getService(Ci.nsISessionStore)

loadCss = (name) ->
  sss = Cc['@mozilla.org/content/style-sheet-service;1']
    .getService(Ci.nsIStyleSheetService)
  uri = Services.io.newURI("chrome://vimfx/skin/#{ name }.css", null, null)
  method = sss.AUTHOR_SHEET
  unless sss.sheetRegistered(uri, method)
    sss.loadAndRegisterSheet(uri, method)

  module.onShutdown(->
    sss.unregisterSheet(uri, method)
  )

# Store events that we’ve simulated. A `WeakMap` is used in order not to leak
# memory. This approach is better than for example setting `event.simulated =
# true`, since that tells the sites that the click was simulated, and allows
# sites to spoof it.
simulated_events = new WeakMap()

# Simulate mouse click with a full chain of events. ('command' is for XUL
# elements.)
eventSequence = ['mouseover', 'mousedown', 'mouseup', 'click', 'command']
simulateClick = (element) ->
  window = element.ownerDocument.defaultView
  for type in eventSequence
    mouseEvent = new window.MouseEvent(type, {
      # Let the event bubble in order to trigger delegated event listeners.
      bubbles: true
      # Make the event cancelable so that `<a href="#">` can be used as a
      # JavaScript-powered button without scrolling to the top of the page.
      cancelable: true
    })
    element.dispatchEvent(mouseEvent)

isEventSimulated = (event) ->
  return simulated_events.has(event)

# Write a string to the system clipboard.
writeToClipboard = (text) ->
  clipboardHelper = Cc['@mozilla.org/widget/clipboardhelper;1']
    .getService(Ci.nsIClipboardHelper)
  clipboardHelper.copyString(text)

# Executes function `func` and measures how much time it took.
timeIt = (func, name) ->
  console.time(name)
  result = func()
  console.timeEnd(name)
  return result

createBox = (document, className, parent = null, text = null) ->
  box = document.createElement('box')
  box.className = className
  box.textContent = text if text?
  parent.appendChild(box) if parent?
  return box

setAttributes = (element, attributes) ->
  for attribute, value of attributes
    element.setAttribute(attribute, value)
  return

insertText = (input, value) ->
  { selectionStart, selectionEnd } = input
  input.value =
    input.value[0...selectionStart] + value + input.value[selectionEnd..]
  input.selectionStart = input.selectionEnd = selectionStart + value.length

isURL = (str) ->
  try
    url = Cc['@mozilla.org/network/io-service;1']
      .getService(Ci.nsIIOService)
      .newURI(str, null, null)
      .QueryInterface(Ci.nsIURL)
    return true
  catch err
    return false

# Use Firefox services to search for a given string.
browserSearchSubmission = (str) ->
  ss = Cc['@mozilla.org/browser/search-service;1']
    .getService(Ci.nsIBrowserSearchService)

  engine = ss.currentEngine or ss.defaultEngine
  return engine.getSubmission(str, null)

openTab = (rootWindow, url, options) ->
  { gBrowser } = rootWindow
  rootWindow.TreeStyleTabService?.readyToOpenChildTab(gBrowser.selectedTab)
  gBrowser.loadOneTab(url, options)

# Remove duplicate characters from string (case insensitive).
removeDuplicateCharacters = (str) ->
  return removeDuplicates( str.toLowerCase().split('') ).join('')

# Escape a string to render it usable in regular expressions.
regexpEscape = (s) -> s and s.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&')

removeDuplicates = (array) ->
  # coffeelint: disable=no_backticks
  return `[...new Set(array)]`
  # coffeelint: enable=no_backticks

formatError = (error) ->
  stack = String(error.stack?.formattedStack ? error.stack ? '')
    .split('\n')
    .filter((line) -> line.contains('.xpi!'))
    .map((line) -> '  ' + line.replace(/(?:\/<)*@.+\.xpi!/g, '@'))
    .join('\n')
  return "#{ error }\n#{ stack }"

observe = (topic, observer) ->
  observer = {observe: observer} if typeof observer == 'function'
  Services.obs.addObserver(observer, topic, false)
  module.onShutdown(->
    Services.obs.removeObserver(observer, topic, false)
  )

has = Function::call.bind(Object::hasOwnProperty)

class Counter
  constructor: ({start, step}) ->
    @value = start ? 0
    @step  = step  ? 1
  tick: -> @value += @step

module.exports = {
  Bucket
  EventEmitter
  getEventWindow
  getEventRootWindow
  getEventCurrentTabWindow
  getRootWindow
  getCurrentTabWindow

  blurActiveElement
  isProperLink
  isTextInputElement
  isContentEditable
  isActivatable
  isAdjustable
  area
  getSessionStore

  loadCss

  simulateClick
  isEventSimulated
  writeToClipboard
  timeIt

  createBox
  setAttributes
  insertText
  isURL
  browserSearchSubmission
  openTab
  regexpEscape
  removeDuplicates
  removeDuplicateCharacters
  formatError
  observe
  has
  Counter
}
