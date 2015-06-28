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

# This file contains lots of different helper functions.

HTMLAnchorElement   = Ci.nsIDOMHTMLAnchorElement
HTMLButtonElement   = Ci.nsIDOMHTMLButtonElement
HTMLInputElement    = Ci.nsIDOMHTMLInputElement
HTMLTextAreaElement = Ci.nsIDOMHTMLTextAreaElement
HTMLSelectElement   = Ci.nsIDOMHTMLSelectElement
HTMLFrameElement    = Ci.nsIDOMHTMLFrameElement
HTMLIFrameElement   = Ci.nsIDOMHTMLIFrameElement
XULDocument         = Ci.nsIDOMXULDocument
XULButtonElement    = Ci.nsIDOMXULButtonElement
XULControlElement   = Ci.nsIDOMXULControlElement
XULMenuListElement  = Ci.nsIDOMXULMenuListElement
XULTextBoxElement   = Ci.nsIDOMXULTextBoxElement

USE_CAPTURE = true

class EventEmitter
  constructor: ->
    @listeners = {}

  on: (event, listener) ->
    (@listeners[event] ?= []).push(listener)

  emit: (event, data) ->
    for listener in @listeners[event] ? []
      listener(data)
    return

blurActiveElement = (window, { force = false } = {}) ->
  # Only blur focusable elements, in order to interfere with the browser as
  # little as possible.
  activeElement = getActiveElement(window)
  if activeElement and (activeElement.tabIndex > -1 or force)
    activeElement.blur()

getActiveElement = (window) ->
  { activeElement } = window.document
  if activeElement instanceof HTMLFrameElement or
     activeElement instanceof HTMLIFrameElement
    return getActiveElement(activeElement.contentWindow)
  else
    return activeElement

# Focus an element and tell Firefox that the focus happened because of a user
# keypress (not just because some random programmatic focus).
focusElement = (element, options = {}) ->
  focusManager = Cc['@mozilla.org/focus-manager;1']
    .getService(Ci.nsIFocusManager)
  focusManager.setFocus(element, focusManager.FLAG_BYKEY)
  element.select?() if options.select

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

getFocusType = (event) ->
  target = event.originalTarget
  return switch
    when isTextInputElement(target) or isContentEditable(target)
      'editable'
    when isActivatable(target)
      'activatable'
    when isAdjustable(target)
      'adjustable'
    else
      null

area = (element) ->
  return element.clientWidth * element.clientHeight

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

# Simulate mouse click with a full chain of events. ('command' is for XUL
# elements.)
eventSequence = ['mouseover', 'mousedown', 'mouseup', 'click', 'command']
simulateClick = (element) ->
  window = element.ownerDocument.defaultView
  simulatedEvents = {}
  for type in eventSequence
    mouseEvent = new window.MouseEvent(type, {
      # Let the event bubble in order to trigger delegated event listeners.
      bubbles: true
      # Make the event cancelable so that `<a href="#">` can be used as a
      # JavaScript-powered button without scrolling to the top of the page.
      cancelable: true
    })
    element.dispatchEvent(mouseEvent)
    simulatedEvents[type] = mouseEvent
  return simulatedEvents

listen = (element, eventName, listener) ->
  element.addEventListener(eventName, listener, USE_CAPTURE)
  module.onShutdown(->
    element.removeEventListener(eventName, listener, USE_CAPTURE)
  )

suppressEvent = (event) ->
  event.preventDefault()
  event.stopPropagation()

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

openTab = (window, url, options) ->
  { gBrowser } = window
  window.TreeStyleTabService?.readyToOpenChildTab(gBrowser.selectedTab)
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
    .filter((line) -> line.includes('.xpi!'))
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

getCurrentWindow = ->
  windowMediator = Cc['@mozilla.org/appshell/window-mediator;1']
    .getService(Components.interfaces.nsIWindowMediator)
  return windowMediator.getMostRecentWindow('navigator:browser')

getCurrentLocation = (browser = null) ->
  browser = getCurrentWindow().gBrowser.selectedBrowser unless browser?
  return new browser.ownerGlobal.URL(browser.currentURI.spec)

module.exports = {
  EventEmitter

  blurActiveElement
  getActiveElement
  focusElement
  isProperLink
  isTextInputElement
  isContentEditable
  isActivatable
  isAdjustable
  getFocusType
  area

  loadCss

  simulateClick
  listen
  suppressEvent
  writeToClipboard
  timeIt

  createBox
  setAttributes
  insertText
  openTab
  regexpEscape
  removeDuplicates
  removeDuplicateCharacters
  formatError
  observe
  has
  Counter
  getCurrentWindow
  getCurrentLocation
}
