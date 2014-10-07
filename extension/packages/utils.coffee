{ unloader } = require 'unloader'
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

class Bucket
  constructor: (@newFunc) ->
    @bucket = new WeakMap()

  get: (obj) ->
    if @bucket.has(obj)
      return @bucket.get(obj)
    else
      return @bucket.set(obj, @newFunc(obj))

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
  # Only blur editable elements, in order to interfere with the browser as
  # little as possible.
  { activeElement } = window.document
  if activeElement and isElementEditable(activeElement)
    activeElement.blur()

isTextInputElement = (element) ->
  return element instanceof HTMLInputElement or
         element instanceof HTMLTextAreaElement

isElementEditable = (element) ->
  return element.isContentEditable or
         element instanceof HTMLInputElement or
         element instanceof HTMLTextAreaElement or
         element instanceof HTMLSelectElement or
         element instanceof XULMenuListElement or
         element.isContentEditable or
         isElementGoogleEditable(element)

isElementGoogleEditable = (element) ->
  # `g_editable` is a non-standard attribute commonly used by Google.
  return element.getAttribute?('g_editable') == 'true' or
         (element instanceof HTMLElement and
          element.ownerDocument.body?.getAttribute('g_editable') == 'true')

isElementVisible = (element) ->
  document = element.ownerDocument
  window   = document.defaultView
  computedStyle = window.getComputedStyle(element, null)
  return computedStyle.getPropertyValue('visibility') == 'visible' and
         computedStyle.getPropertyValue('display') != 'none' and
         computedStyle.getPropertyValue('opacity') != '0'

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
    if !sss.sheetRegistered(uri, sss.AGENT_SHEET)
      sss.loadAndRegisterSheet(uri, sss.AGENT_SHEET)

    unloader.add(->
      sss.unregisterSheet(uri, sss.AGENT_SHEET)
    )

# Store events that we’ve simulated. A `WeakMap` is used in order not to leak
# memory. This approach is better than for example setting `event.simulated =
# true`, since that tells the sites that the click was simulated, and allows
# sites to spoof it.
simulated_events = new WeakMap()

# Simulate mouse click with a full chain of events.  Copied from Vimium
# codebase.
simulateClick = (element, modifiers = {}) ->
  document = element.ownerDocument
  window = document.defaultView

  eventSequence = ['mouseover', 'mousedown', 'mouseup', 'click']
  for event in eventSequence
    mouseEvent = document.createEvent('MouseEvents')
    mouseEvent.initMouseEvent(
      event, true, true, window, 1, 0, 0, 0, 0,
      modifiers.ctrlKey, false, false, modifiers.metaKey,
      0, null
    )
    simulated_events.set(mouseEvent, true)
    # Debugging note: Firefox will not execute the element's default action if
    # we dispatch this click event, but Webkit will. Dispatching a click on an
    # input box does not seem to focus it; we do that separately.
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

# Read the system clipboard.
readFromClipboard = (window) ->
  trans = Cc['@mozilla.org/widget/transferable;1']
    .createInstance(Ci.nsITransferable)

  if trans.init
    privacyContext = window
      .QueryInterface(Ci.nsIInterfaceRequestor)
      .getInterface(Ci.nsIWebNavigation)
      .QueryInterface(Ci.nsILoadContext)
    trans.init(privacyContext)

  trans.addDataFlavor('text/unicode')

  clip = Cc['@mozilla.org/widget/clipboard;1'].getService(Ci.nsIClipboard)
  clip.getData(trans, Ci.nsIClipboard.kGlobalClipboard)

  str = {}
  strLength = {}

  trans.getTransferData('text/unicode', str, strLength)

  if str
    str = str.value.QueryInterface(Ci.nsISupportsString)
    return str.data.substring(0, strLength.value / 2)

  return undefined

# Executes function `func` and mearues how much time it took.
timeIt = (func, name) ->
  console.time(name)
  result = func()
  console.timeEnd(name)
  return result

isBlacklisted = (str) ->
  matchingRules = getMatchingBlacklistRules(str)
  return (matchingRules.length != 0)

# Returns all rules in the blacklist that match the provided string.
getMatchingBlacklistRules = (str) ->
  return getBlacklist().filter((rule) ->
    /// ^#{ simpleWildcards(rule) }$ ///i.test(str)
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

createElement = (document, type, attributes = {}) ->
  element = document.createElement(type)

  for attribute, value of attributes
    element.setAttribute(attribute, value)

  if document instanceof HTMLDocument
    element.classList.add('VimFxReset')

  return element

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
  return `[...new Set(array)]`

# Why isn’t `a[@href]` used, when `area[@href]` is? Some sites (such as
# StackExchange sites) leave out the `href` property and use the anchor as a
# JavaScript-powered button (instead of just using the `button` element).
ACTION_ELEMENT_TAGS = [
  "a"
  "area[@href]"
  "button"
  # When viewing an image directly, and it is larger than the viewport,
  # clicking it toggles zoom.
  "img[contains(@class, 'decoded') and
     (contains(@class, 'overflowing') or
     contains(@class, 'shrinkToFit'))]"
]

ACTION_ELEMENT_PROPERTIES = [
  "@onclick"
  "@onmousedown"
  "@onmouseup"
  "@oncommand"
  "@role='link'"
  "@role='button'"
  "contains(@class, 'button')"
  "contains(@class, 'js-new-tweets-bar')"
]

EDITABLE_ELEMENT_TAGS = [
  "textarea"
  "select"
  "input[not(@type='hidden' or @disabled)]"
]

EDITABLE_ELEMENT_PROPERTIES = [
  "@contenteditable=''"
  "translate(@contenteditable, 'TRUE', 'true')='true'"
]

FOCUSABLE_ELEMENT_TAGS = [
  "frame"
  "iframe"
  "embed"
  "object"
]

FOCUSABLE_ELEMENT_PROPERTIES = [
  "@tabindex!=-1"
]

getMarkableElements = do ->
  xpathify = (tags, properties)->
    return tags
      .concat("*[#{ properties.join(' or ') }]")
      .map((rule) -> "//#{ rule } | //xhtml:#{ rule }")
      .join(" | ")

  xpaths =
    action:    xpathify(ACTION_ELEMENT_TAGS,    ACTION_ELEMENT_PROPERTIES   )
    editable:  xpathify(EDITABLE_ELEMENT_TAGS,  EDITABLE_ELEMENT_PROPERTIES )
    focusable: xpathify(FOCUSABLE_ELEMENT_TAGS, FOCUSABLE_ELEMENT_PROPERTIES)
    all: xpathify(
      [ACTION_ELEMENT_TAGS...,       EDITABLE_ELEMENT_TAGS...,       FOCUSABLE_ELEMENT_TAGS...      ],
      [ACTION_ELEMENT_PROPERTIES..., EDITABLE_ELEMENT_PROPERTIES..., FOCUSABLE_ELEMENT_PROPERTIES...]
    )

  # The actual function that will return the desired elements.
  return (document, { type }) ->
    return xpathQueryAll(document, xpaths[type])

xpathHelper = (node, query, resultType) ->
  document = node.ownerDocument ? node
  namespaceResolver = (namespace) ->
    if namespace == 'xhtml' then 'http://www.w3.org/1999/xhtml' else null
  return document.evaluate(query, node, namespaceResolver, resultType, null)

xpathQuery = (node, query) ->
  result = xpathHelper(node, query, XPathResult.FIRST_ORDERED_NODE_TYPE)
  return result.singleNodeValue

xpathQueryAll = (node, query) ->
  result = xpathHelper(node, query, XPathResult.ORDERED_NODE_SNAPSHOT_TYPE)
  return (result.snapshotItem(i) for i in [0...result.snapshotLength] by 1)


exports.Bucket                    = Bucket
exports.getEventWindow            = getEventWindow
exports.getEventRootWindow        = getEventRootWindow
exports.getEventCurrentTabWindow  = getEventCurrentTabWindow
exports.getRootWindow             = getRootWindow
exports.getCurrentTabWindow       = getCurrentTabWindow

exports.blurActiveElement         = blurActiveElement
exports.isTextInputElement        = isTextInputElement
exports.isElementEditable         = isElementEditable
exports.isElementVisible          = isElementVisible
exports.getSessionStore           = getSessionStore

exports.loadCss                   = loadCss

exports.simulateClick             = simulateClick
exports.isEventSimulated          = isEventSimulated
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
exports.splitListString           = splitListString
exports.getBestPatternMatch       = getBestPatternMatch

exports.getVersion                = getVersion
exports.parseHTML                 = parseHTML
exports.createElement             = createElement
exports.isURL                     = isURL
exports.browserSearchSubmission   = browserSearchSubmission
exports.getHintChars              = getHintChars
exports.removeDuplicates          = removeDuplicates
exports.removeDuplicateCharacters = removeDuplicateCharacters
exports.getResourceURI            = getResourceURI
exports.getMarkableElements       = getMarkableElements
exports.xpathQuery                = xpathQuery
exports.xpathQueryAll             = xpathQueryAll
exports.ADDON_ID                  = ADDON_ID
