{ unload } = require 'unload'
{ getPref
, setPref
} = require 'prefs'

ADDON_ID = 'VimFx@akhodakivskiy.github.com'

{ classes: Cc, interfaces: Ci, utils: Cu } = Components

HTMLInputElement    = Ci.nsIDOMHTMLInputElement
HTMLTextAreaElement = Ci.nsIDOMHTMLTextAreaElement
HTMLSelectElement   = Ci.nsIDOMHTMLSelectElement
XULMenuListElement  = Ci.nsIDOMXULMenuListElement
XULDocument         = Ci.nsIDOMXULDocument
XULElement          = Ci.nsIDOMXULElement
XPathResult         = Ci.nsIDOMXPathResult
HTMLDocument        = Ci.nsIDOMHTMLDocument
HTMLElement         = Ci.nsIDOMHTMLElement
Window              = Ci.nsIDOMWindow
ChromeWindow        = Ci.nsIDOMChromeWindow

_clip = Cc['@mozilla.org/widget/clipboard;1'].getService(Ci.nsIClipboard)

class Bucket
  constructor: (@idFunc, @newFunc) ->
    @bucket = {}

  get: (obj) ->
    id = @idFunc(obj)
    if container = @bucket[id]
      return container
    else
      return @bucket[id] = @newFunc(obj)

  forget: (obj) ->
    delete @bucket[id] if id = @idFunc(obj)

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
  # Only blur editable elements, in order not to interfere with the browser too much. TODO: Is that
  # really needed? What if a website has made more elements focusable -- shouldn't those also be
  # blurred?
  { activeElement } = window.document
  if isElementEditable(activeElement)
    activeElement.blur()

isTextInputElement = (element) ->
  return element instanceof HTMLInputElement or \
         element instanceof HTMLTextAreaElement

isElementEditable = (element) ->
  return element.isContentEditable or \
         element instanceof HTMLInputElement or \
         element instanceof HTMLTextAreaElement or \
         element instanceof HTMLSelectElement or \
         element instanceof XULMenuListElement or \
         element.getAttribute?('g_editable') == 'true' or \
         element.getAttribute?('contenteditable')?.toLowerCase() == 'true' or \
         element.ownerDocument?.designMode?.toLowerCase() == 'on'

isElementBrowserChrome = (element) ->
   element.ownerDocument instanceof XULDocument

getWindowId = (window) ->
  return window
    .QueryInterface(Components.interfaces.nsIInterfaceRequestor)
    .getInterface(Components.interfaces.nsIDOMWindowUtils)
    .outerWindowID

getSessionStore = ->
  Cc['@mozilla.org/browser/sessionstore;1'].getService(Ci.nsISessionStore)

# Function that returns a URI to the css file that's part of the extension
cssUri = do ->
  (name) ->
    baseURI = Services.io.newURI(__SCRIPT_URI_SPEC__, null, null)
    uri = Services.io.newURI("resources/#{ name }.css", null, baseURI)
    return uri

# Loads the css identified by the name in the StyleSheetService as User Stylesheet
# The stylesheet is then appended to every document, but it can be overwritten by
# any user css
loadCss = do ->
  sss = Cc['@mozilla.org/content/style-sheet-service;1'].getService(Ci.nsIStyleSheetService)
  return (name) ->
    uri = cssUri(name)
    # `AGENT_SHEET` is used to override userContent.css and Stylish. Custom website themes installed
    # by users often make the hint markers unreadable, for example. Just using `!important` in the
    # CSS is not enough.
    if !sss.sheetRegistered(uri, sss.AGENT_SHEET)
      sss.loadAndRegisterSheet(uri, sss.AGENT_SHEET)

    unload ->
      sss.unregisterSheet(uri, sss.AGENT_SHEET)

# Simulate mouse click with full chain of event
# Copied from Vimium codebase
simulateClick = (element, modifiers = {}) ->
  document = element.ownerDocument
  window = document.defaultView

  eventSequence = ['mouseover', 'mousedown', 'mouseup', 'click']
  for event in eventSequence
    mouseEvent = document.createEvent('MouseEvents')
    mouseEvent.initMouseEvent(event, true, true, window, 1, 0, 0, 0, 0, modifiers.ctrlKey, false, false,
        modifiers.metaKey, 0, null)
    # Debugging note: Firefox will not execute the element's default action if we dispatch this click event,
    # but Webkit will. Dispatching a click on an input box does not seem to focus it; we do that separately
    element.dispatchEvent(mouseEvent)

WHEEL_MODE_PIXEL = Ci.nsIDOMWheelEvent.DOM_DELTA_PIXEL
WHEEL_MODE_LINE = Ci.nsIDOMWheelEvent.DOM_DELTA_LINE
WHEEL_MODE_PAGE = Ci.nsIDOMWheelEvent.DOM_DELTA_PAGE

# Simulate mouse scroll event by specific offsets given
# that mouse cursor is at specified position
simulateWheel = (window, deltaX, deltaY, mode = WHEEL_MODE_PIXEL) ->
  windowUtils = window
    .QueryInterface(Ci.nsIInterfaceRequestor)
    .getInterface(Ci.nsIDOMWindowUtils)

  [pX, pY] = [window.innerWidth / 2, window.innerHeight / 2]
  windowUtils.sendWheelEvent(
    pX, pY,             # Window offset (x, y) in pixels
    deltaX, deltaY, 0,  # Deltas (x, y, z)
    mode,               # Mode (pixel, line, page)
    0,                  # Key Modifiers
    0, 0,               # Line or Page deltas (x, y)
    0                   # Options
  )

# Write a string into system clipboard
writeToClipboard = (window, text) ->
  str = Cc['@mozilla.org/supports-string;1'].createInstance(Ci.nsISupportsString)
  str.data = text

  trans = Cc['@mozilla.org/widget/transferable;1'].createInstance(Ci.nsITransferable)

  if trans.init
    privacyContext = window
      .QueryInterface(Ci.nsIInterfaceRequestor)
      .getInterface(Ci.nsIWebNavigation)
      .QueryInterface(Ci.nsILoadContext)
    trans.init(privacyContext)

  trans.addDataFlavor('text/unicode')
  trans.setTransferData('text/unicode', str, text.length * 2)

  _clip.setData(trans, null, Ci.nsIClipboard.kGlobalClipboard)

# Write a string into system clipboard
readFromClipboard = (window) ->
  trans = Cc['@mozilla.org/widget/transferable;1'].createInstance(Ci.nsITransferable)

  if trans.init
    privacyContext = window
      .QueryInterface(Ci.nsIInterfaceRequestor)
      .getInterface(Ci.nsIWebNavigation)
      .QueryInterface(Ci.nsILoadContext)
    trans.init(privacyContext)

  trans.addDataFlavor('text/unicode')

  _clip.getData(trans, Ci.nsIClipboard.kGlobalClipboard)

  str = {}
  strLength = {}

  trans.getTransferData('text/unicode', str, strLength)

  if str
    str = str.value.QueryInterface(Ci.nsISupportsString)
    return str.data.substring(0, strLength.value / 2)

  return undefined

# Executes function `func` and mearues how much time it took
timeIt = (func, msg) ->
  start = new Date().getTime()
  result = func()
  end = new Date().getTime()

  console.log(msg, end - start)
  return result

isBlacklisted = (str) ->
  matchingRules = getMatchingBlacklistRules(str)
  return (matchingRules.length != 0)

# Returns all rules in the blacklist that match the provided string
getMatchingBlacklistRules = (str) ->
  matchingRules = []
  for rule in getBlacklist()
    # Wildcards: * and !
    regexifiedRule = regexpEscape(rule).replace(/\\\*/g, '.*').replace(/!/g, '.')
    if str.match(///^#{ regexifiedRule }$///)
      matchingRules.push(rule)

  return matchingRules

getBlacklist = ->
  return splitBlacklistString(getPref('black_list'))

setBlacklist = (blacklist) ->
  setPref('black_list', blacklist.join(', '))

splitBlacklistString = (str) ->
  # Comma/space separated list
  return str.split(/[\s,]+/)

updateBlacklist = ({ add, remove} = {}) ->
  blacklist = getBlacklist()

  if add
    blacklist.push(splitBlacklistString(add)...)

  blacklist = blacklist.filter((rule) -> rule != '')
  blacklist = removeDuplicates(blacklist)

  if remove
    for rule in splitBlacklistString(remove) when rule in blacklist
      blacklist.splice(blacklist.indexOf(rule), 1)

  setBlacklist(blacklist)

# Gets VimFx verions. AddonManager only provides async API to access addon data, so it's a bit tricky...
getVersion = do ->
  version = null

  if version == null
    scope = {}
    Cu.import('resource://gre/modules/AddonManager.jsm', scope)
    scope.AddonManager.getAddonByID(ADDON_ID, (addon) -> version = addon.version)

  return ->
    return version

parseHTML = (document, html) ->
  parser = Cc['@mozilla.org/parserutils;1'].getService(Ci.nsIParserUtils)
  flags = parser.SanitizerAllowStyle
  return parser.parseFragment(html, flags, false, null, document.documentElement)

createElement = (document, type, attributes = {}) ->
  element = document.createElement(type)

  for attribute, value of attributes
    element.setAttribute(attribute, value)

  if document instanceof HTMLDocument
    element.classList.add('VimFxReset')

  return element

# Uses nsIIOService to parse a string as a URL and find out if it is a URL
isURL = (str) ->
  try
    url = Cc['@mozilla.org/network/io-service;1']
      .getService(Ci.nsIIOService)
      .newURI(str, null, null)
      .QueryInterface(Ci.nsIURL)
    return true
  catch err
    return false

# Use Firefox services to search for a given string
browserSearchSubmission = (str) ->
  ss = Cc['@mozilla.org/browser/search-service;1']
    .getService(Ci.nsIBrowserSearchService)

  engine = ss.currentEngine or ss.defaultEngine
  return engine.getSubmission(str, null)

# Get hint characters, convert them to lower case, and filter duplicates
getHintChars = ->
  hintChars = getPref('hint_chars')
  # Make sure that hint chars contain at least two characters
  if hintChars.length < 2
    hintChars = 'fj'

  return removeDuplicateCharacters(hintChars)

# Remove duplicate characters from string (case insensitive)
removeDuplicateCharacters = (str) ->
  return removeDuplicates( str.toLowerCase().split('') ).join('')

# Return URI to some file in the extension packaged as resource
getResourceURI = do ->
  baseURI = Services.io.newURI(__SCRIPT_URI_SPEC__, null, null)
  return (path) -> return Services.io.newURI(path, null, baseURI)

# Escape string to render it usable in regular expressions
regexpEscape = (s) -> s and s.replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&')

removeDuplicates = (array) ->
  seen = {}
  return array.filter((item) -> if seen[item] then false else (seen[item] = true))

# Returns elements that qualify as links
# Generates and memoizes an XPath query internally
getDomElements = (elements) ->
  reduce = (m, rule) -> m.concat(["//#{ rule }", "//xhtml:#{ rule }"])
  xpath = elements.reduce(reduce, []).join(' | ')

  namespaceResolver = (namespace) ->
    if namespace == 'xhtml' then 'http://www.w3.org/1999/xhtml' else null

  # The actual function that will return the desired elements
  return (document, resultType = XPathResult.ORDERED_NODE_SNAPSHOT_TYPE) ->
    return document.evaluate(xpath, document.documentElement, namespaceResolver, resultType, null)

exports.Bucket                    = Bucket
exports.getEventWindow            = getEventWindow
exports.getEventRootWindow        = getEventRootWindow
exports.getEventCurrentTabWindow  = getEventCurrentTabWindow
exports.getRootWindow             = getRootWindow
exports.getCurrentTabWindow       = getCurrentTabWindow

exports.getWindowId               = getWindowId
exports.blurActiveElement         = blurActiveElement
exports.isTextInputElement        = isTextInputElement
exports.isElementEditable         = isElementEditable
exports.isElementBrowserChrome    = isElementBrowserChrome
exports.getSessionStore           = getSessionStore

exports.loadCss                   = loadCss

exports.simulateClick             = simulateClick
exports.simulateWheel             = simulateWheel
exports.WHEEL_MODE_PIXEL          = WHEEL_MODE_PIXEL
exports.WHEEL_MODE_LINE           = WHEEL_MODE_LINE
exports.WHEEL_MODE_PAGE           = WHEEL_MODE_PAGE
exports.readFromClipboard         = readFromClipboard
exports.writeToClipboard          = writeToClipboard
exports.timeIt                    = timeIt

exports.getMatchingBlacklistRules = getMatchingBlacklistRules
exports.isBlacklisted             = isBlacklisted
exports.updateBlacklist           = updateBlacklist

exports.getVersion                = getVersion
exports.parseHTML                 = parseHTML
exports.createElement             = createElement
exports.isURL                     = isURL
exports.browserSearchSubmission   = browserSearchSubmission
exports.getHintChars              = getHintChars
exports.removeDuplicateCharacters = removeDuplicateCharacters
exports.getResourceURI            = getResourceURI
exports.getDomElements            = getDomElements
exports.ADDON_ID                  = ADDON_ID
