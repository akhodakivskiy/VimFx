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

notation = require('vim-like-key-notation')
{ getPref
, setPref
} = require('./prefs')

ADDON_ID = 'VimFx@akhodakivskiy.github.com'

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
  constructor: (@newFunc) ->
    @bucket = new WeakMap()

  get: (obj) ->
    if @bucket.has(obj)
      return @bucket.get(obj)
    else
      value = @newFunc(obj)
      @bucket.set(obj, value)
      return value

  forget: (obj) ->
    @bucket.delete(obj)

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
  return element.hasAttribute('href') and
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

loadCss = do ->
  sss = Cc['@mozilla.org/content/style-sheet-service;1']
    .getService(Ci.nsIStyleSheetService)
  return (name) ->
    uri = getResourceURI("resources/#{ name }.css")
    # `AGENT_SHEET` is used to override userContent.css and Stylish. Custom
    # website themes installed by users often make the hint markers unreadable,
    # for example. Just using `!important` in the CSS is not enough.
    unless sss.sheetRegistered(uri, sss.AGENT_SHEET)
      sss.loadAndRegisterSheet(uri, sss.AGENT_SHEET)

    module.onShutdown(->
      sss.unregisterSheet(uri, sss.AGENT_SHEET)
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

WHEEL_MODE_PIXEL = Ci.nsIDOMWheelEvent.DOM_DELTA_PIXEL
WHEEL_MODE_LINE  = Ci.nsIDOMWheelEvent.DOM_DELTA_LINE
WHEEL_MODE_PAGE  = Ci.nsIDOMWheelEvent.DOM_DELTA_PAGE

# Simulate mouse scroll event by specific offsets given that mouse cursor is at
# specified position.
simulateWheel = (window, deltaX, deltaY, mode = WHEEL_MODE_PIXEL) ->
  windowUtils = window
    .QueryInterface(Ci.nsIInterfaceRequestor)
    .getInterface(Ci.nsIDOMWindowUtils)

  [pX, pY] = [window.innerWidth / 2, window.innerHeight / 2]
  windowUtils.sendWheelEvent(
    pX, pY,             # Window offset (x, y) in pixels.
    deltaX, deltaY, 0,  # Deltas (x, y, z).
    mode,               # Mode (pixel, line, page).
    0,                  # Key Modifiers.
    0, 0,               # Line or Page deltas (x, y).
    0                   # Options.
  )

# Write a string to the system clipboard.
writeToClipboard = (text) ->
  clipboardHelper = Cc['@mozilla.org/widget/clipboardhelper;1']
    .getService(Ci.nsIClipboardHelper)
  clipboardHelper.copyString(text)

# Executes function `func` and mearues how much time it took.
timeIt = (func, name) ->
  console.time(name)
  result = func()
  console.timeEnd(name)
  return result

isBlacklisted = (str) ->
  matchingRules = getMatchingBlacklistRules(str)
  return (matchingRules.length != 0)

# Returns all blacklisted keys in matching rules.
getBlacklistedKeys = (str) ->
  matchingRules = getMatchingBlacklistRules(str)
  blacklistedKeys = []
  for rule in matchingRules when /##/.test(rule)
    blacklistedKeys.push(x) for x in rule.split('##')[1].split('#')
  return blacklistedKeys

# Returns all rules in the blacklist that match the provided string.
getMatchingBlacklistRules = (str) ->
  return getBlacklist().filter((rule) ->
    /// ^#{ simpleWildcards(rule.split('##')[0]) }$ ///i.test(str)
  )

getBlacklist = ->
  return splitListString(getPref('black_list'))

setBlacklist = (blacklist) ->
  setPref('black_list', blacklist.join(','))

updateBlacklist = ({ add, remove } = {}) ->
  blacklist = getBlacklist()

  if add
    blacklist.push(splitListString(add)...)

  blacklist = blacklist.filter((rule) -> rule != '')
  blacklist = removeDuplicates(blacklist)

  if remove
    for rule in splitListString(remove) when rule in blacklist
      blacklist.splice(blacklist.indexOf(rule), 1)

  setBlacklist(blacklist)

# Splits a comma/space separated list into an array.
splitListString = (str) ->
  return str.split(/\s*,[\s,]*/)

# Prepares a string to be used in a regexp, where "*" matches zero or more
# characters and "!" matches one character.
simpleWildcards = (string) ->
  return regexpEscape(string).replace(/\\\*/g, '.*').replace(/!/g, '.')

# Returns the first element that matches a pattern, favoring earlier patterns.
# The patterns are case insensitive `simpleWildcards`s and must match either in
# the beginning or at the end of a string. Moreover, a pattern does not match
# in the middle of words, so "previous" does not match "previously". If that is
# desired, a pattern such as "previous*" can be used instead. Note: We cannot
# use `\b` word boundaries, because they don’t work well with non-English
# characters. Instead we match a space as word boundary. Therefore we normalize
# the whitespace and add spaces at the edges of the element text.
getBestPatternMatch = (patterns, attrs, elements) ->
  regexps = []
  for pattern in patterns
    wildcarded = simpleWildcards(pattern)
    regexps.push(/// ^\s(?:#{ wildcarded })\s | \s(?:#{ wildcarded })\s$ ///i)

  # Helper function that matches a string against all the patterns.
  matches = (text) ->
    normalizedText = " #{ text } ".replace(/\s+/g, ' ')
    for re in regexps
      if re.test(normalizedText)
        return true
    return false

  # First search in attributes (favoring earlier attributes) as it's likely
  # that they are more specific than text contexts.
  for attr in attrs
    for element in elements
      if matches(element.getAttribute(attr))
        return element

  # Then search in element contents.
  for element in elements
    if matches(element.textContent)
      return element

  return null

# Get VimFx verion. AddonManager only provides async API to access addon data,
# so it's a bit tricky...
getVersion = do ->
  version = null

  scope = {}
  Cu.import('resource://gre/modules/AddonManager.jsm', scope)
  scope.AddonManager.getAddonByID(ADDON_ID, (addon) -> version = addon.version)

  return ->
    return version

parseHTML = (document, html) ->
  parser = Cc['@mozilla.org/parserutils;1'].getService(Ci.nsIParserUtils)
  flags = parser.SanitizerAllowStyle
  return parser.parseFragment(html, flags, false, null,
                              document.documentElement)

escapeHTML = (s) ->
  return s
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&apos;')

createElement = (document, type, attributes = {}) ->
  element = document.createElement(type)

  for attribute, value of attributes
    element.setAttribute(attribute, value)

  if document instanceof HTMLDocument
    element.classList.add('VimFxReset')

  return element

getAllElements = (document) -> switch
  when document instanceof HTMLDocument
    return document.getElementsByTagName('*')
  when document instanceof XULDocument
    elements = []
    getAllRegular = (element) ->
      for child in element.getElementsByTagName('*')
        elements.push(child)
        getAllAnonymous(child)
      return
    getAllAnonymous = (element) ->
      for child in document.getAnonymousNodes(element) or []
        continue unless child instanceof Element
        elements.push(child)
        getAllRegular(child)
      return
    getAllRegular(document.documentElement)
    return elements

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

normalizedKey = (key) -> key.map(notation.normalize).join('')

# Get hint characters, convert them to lower case, and filter duplicates.
getHintChars = ->
  hintChars = getPref('hint_chars')
  # Make sure that hint chars contain at least two characters.
  if not hintChars or hintChars.length < 2
    hintChars = 'fj'

  return removeDuplicateCharacters(hintChars)

# Remove duplicate characters from string (case insensitive).
removeDuplicateCharacters = (str) ->
  return removeDuplicates( str.toLowerCase().split('') ).join('')

# Return URI to some file in the extension packaged as resource.
getResourceURI = do ->
  baseURI = Services.io.newURI(__SCRIPT_URI_SPEC__, null, null)
  return (path) -> return Services.io.newURI(path, null, baseURI)

# Escape a string to render it usable in regular expressions.
regexpEscape = (s) -> s and s.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&')

removeDuplicates = (array) ->
  # coffeelint: disable=no_backticks
  return `[...new Set(array)]`
  # coffeelint: enable=no_backticks

exports.Bucket                    = Bucket
exports.getEventWindow            = getEventWindow
exports.getEventRootWindow        = getEventRootWindow
exports.getEventCurrentTabWindow  = getEventCurrentTabWindow
exports.getRootWindow             = getRootWindow
exports.getCurrentTabWindow       = getCurrentTabWindow

exports.blurActiveElement         = blurActiveElement
exports.isProperLink              = isProperLink
exports.isTextInputElement        = isTextInputElement
exports.isContentEditable         = isContentEditable
exports.isActivatable             = isActivatable
exports.isAdjustable              = isAdjustable
exports.area                      = area
exports.getSessionStore           = getSessionStore

exports.loadCss                   = loadCss

exports.simulateClick             = simulateClick
exports.isEventSimulated          = isEventSimulated
exports.simulateWheel             = simulateWheel
exports.WHEEL_MODE_PIXEL          = WHEEL_MODE_PIXEL
exports.WHEEL_MODE_LINE           = WHEEL_MODE_LINE
exports.WHEEL_MODE_PAGE           = WHEEL_MODE_PAGE
exports.writeToClipboard          = writeToClipboard
exports.timeIt                    = timeIt

exports.getMatchingBlacklistRules = getMatchingBlacklistRules
exports.isBlacklisted             = isBlacklisted
exports.getBlacklistedKeys        = getBlacklistedKeys
exports.updateBlacklist           = updateBlacklist
exports.splitListString           = splitListString
exports.getBestPatternMatch       = getBestPatternMatch

exports.getVersion                = getVersion
exports.parseHTML                 = parseHTML
exports.escapeHTML                = escapeHTML
exports.createElement             = createElement
exports.getAllElements            = getAllElements
exports.isURL                     = isURL
exports.browserSearchSubmission   = browserSearchSubmission
exports.openTab                   = openTab
exports.normalizedKey             = normalizedKey
exports.getHintChars              = getHintChars
exports.removeDuplicates          = removeDuplicates
exports.removeDuplicateCharacters = removeDuplicateCharacters
exports.getResourceURI            = getResourceURI
exports.ADDON_ID                  = ADDON_ID
