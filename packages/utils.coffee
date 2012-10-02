{ interfaces: Ci, classes: Cc } = Components

HTMLInputElement    = Ci.nsIDOMHTMLInputElement
HTMLTextAreaElement = Ci.nsIDOMHTMLTextAreaElement
HTMLSelectElement   = Ci.nsIDOMHTMLSelectElement
XULDocument         = Ci.nsIDOMXULDocument
XULElement          = Ci.nsIDOMXULElement
HTMLDocument        = Ci.nsIDOMHTMLDocument
HTMLElement         = Ci.nsIDOMHTMLElement
Window              = Ci.nsIDOMWindow
ChromeWindow        = Ci.nsIDOMChromeWindow
KeyboardEvent       = Ci.nsIDOMKeyEvent

_sss  = Cc["@mozilla.org/content/style-sheet-service;1"].getService(Ci.nsIStyleSheetService)
_clip = Cc["@mozilla.org/widget/clipboard;1"].getService(Ci.nsIClipboard)

{ getPref } = require 'prefs'

class Bucket
  constructor: (@idFunc, @newFunc) ->
    @bucket = {}

  get: (obj) ->
    id = @idFunc obj
    if container = @bucket[id]
      return container
    else
      return @bucket[id] = @newFunc obj

  forget: (obj) ->
    delete @bucket[id] if id = @idFunc obj

isRootWindow = (window) -> 
  window.location == "chrome://browser/content/browser.xul"

# Returns the `window` from the currently active tab.
getCurrentTabWindow = (event) ->
  if window = getEventWindow event
    if rootWindow = getRootWindow window
      return rootWindow.gBrowser.selectedTab.linkedBrowser.contentWindow

# Returns the window associated with the event
getEventWindow = (event) ->
  if event.originalTarget instanceof Window
    return event.originalTarget
  else 
    doc = event.originalTarget.ownerDocument or event.originalTarget
    if doc instanceof HTMLDocument or doc instanceof XULDocument
      return doc.defaultView 

getEventRootWindow = (event) ->
  if window = getEventWindow event
    return getRootWindow window

getEventTabBrowser = (event) -> 
  cw.gBrowser if cw = getEventRootWindow event

getRootWindow = (window) ->
  return window.QueryInterface(Ci.nsIInterfaceRequestor)
               .getInterface(Ci.nsIWebNavigation)
               .QueryInterface(Ci.nsIDocShellTreeItem)
               .rootTreeItem
               .QueryInterface(Ci.nsIInterfaceRequestor)
               .getInterface(Window); 

isElementEditable = (element) ->
  return element.isContentEditable or \
         element instanceof HTMLInputElement or \
         element instanceof HTMLTextAreaElement or \
         element instanceof HTMLSelectElement

getWindowId = (window) ->
  return window.QueryInterface(Components.interfaces.nsIInterfaceRequestor)
               .getInterface(Components.interfaces.nsIDOMWindowUtils)
               .outerWindowID

getSessionStore = ->
  Cc["@mozilla.org/browser/sessionstore;1"].getService(Ci.nsISessionStore);

# Function that returns a URI to the css file that's part of the extension
cssUri = do () ->
  (name) ->
    baseURI = Services.io.newURI __SCRIPT_URI_SPEC__, null, null
    uri = Services.io.newURI "resources/#{ name }.css", null, baseURI
    return uri

# Loads the css identified by the name in the StyleSheetService as User Stylesheet
# The stylesheet is then appended to every document, but it can be overwritten by
# any user css
loadCss = (name) ->
  uri = cssUri(name)
  _sss.loadAndRegisterSheet(uri, _sss.AGENT_SHEET)

  unload -> 
    _sss.unregisterSheet(uri, _sss.AGENT_SHEET)

# Processes the keyboard event and extracts string representation
# of the key *without modifiers*. 
# Only processes that can be handled by the extension
#
# Currently we handle letters, Escape and Tab keys
keyboardEventChar = (keyboardEvent) ->

  # Ignore the key if Meta of Alt are pressed
  if keyboardEvent.metaKey or keyboardEvent.altKey
    return

  key = keyboardEvent.keyCode
  char = String.fromCharCode(key)
  HINTCHARS = getPref 'hint_chars'

  if key >= KeyboardEvent.DOM_VK_A and key <= KeyboardEvent.DOM_VK_Z
    if keyboardEvent.shiftKey
      return char.toUpperCase()
    else
      return char.toLowerCase()
  # Allow additional chars from the hint chars list
  else if HINTCHARS.search(char) > -1
    return char
  else
    switch keyboardEvent.keyCode
      when KeyboardEvent.DOM_VK_ESCAPE
        return 'Esc'
      when KeyboardEvent.DOM_VK_BACK_SPACE
        return 'Backspace'

# Extracts string representation of the KeyboardEvent and adds 
# relevant modifiers (_ctrl_, _alt_, _meta_) in case they were pressed
keyboardEventKeyString = (keyboardEvent) ->
  char = keyboardEventChar keyboardEvent

  if char and keyboardEvent.ctrlKey
    char = "c-#{ char }"

  return char

# Simulate mouse click with full chain of event
# Copied from Vimium codebase
simulateClick = (element, modifiers) ->
  document = element.ownerDocument
  window = document.defaultView
  modifiers ||= {}

  eventSequence = ["mouseover", "mousedown", "mouseup", "click"]
  for event in eventSequence
    mouseEvent = document.createEvent("MouseEvents")
    mouseEvent.initMouseEvent(event, true, true, window, 1, 0, 0, 0, 0, modifiers.ctrlKey, false, false,
        modifiers.metaKey, 0, null)
    # Debugging note: Firefox will not execute the element's default action if we dispatch this click event,
    # but Webkit will. Dispatching a click on an input box does not seem to focus it; we do that separately
    element.dispatchEvent(mouseEvent)

# Write a string into system clipboard
writeToClipboard = (text) ->
  str = Cc["@mozilla.org/supports-string;1"].createInstance(Ci.nsISupportsString);
  str.data = text

  trans = Cc["@mozilla.org/widget/transferable;1"].createInstance(Ci.nsITransferable);
  trans.addDataFlavor("text/unicode");
  trans.setTransferData("text/unicode", str, text.length * 2);

  _clip.setData trans, null, Ci.nsIClipboard.kGlobalClipboard
  #
# Write a string into system clipboard
readFromClipboard = () ->
  trans = Cc["@mozilla.org/widget/transferable;1"].createInstance(Ci.nsITransferable);
  trans.addDataFlavor("text/unicode");

  _clip.getData trans, Ci.nsIClipboard.kGlobalClipboard

  str = {}
  strLength = {}

  trans.getTransferData("text/unicode", str, strLength)

  if str
    str = str.value.QueryInterface(Ci.nsISupportsString);
    return str.data.substring 0, strLength.value / 2

  return undefined

# Executes function `func` and mearues how much time it took
timeIt = (func, msg) ->
  start = new Date().getTime()
  result = func()
  end = new Date().getTime()

  console.log msg, end - start
  return result

exports.Bucket                  = Bucket
exports.isRootWindow            = isRootWindow
exports.getCurrentTabWindow     = getCurrentTabWindow
exports.getEventWindow          = getEventWindow
exports.getEventRootWindow      = getEventRootWindow
exports.getEventTabBrowser      = getEventTabBrowser

exports.getWindowId             = getWindowId
exports.getRootWindow           = getRootWindow
exports.isElementEditable       = isElementEditable
exports.getSessionStore         = getSessionStore

exports.loadCss                 = loadCss

exports.keyboardEventKeyString  = keyboardEventKeyString
exports.simulateClick           = simulateClick
exports.readFromClipboard       = readFromClipboard
exports.writeToClipboard        = writeToClipboard
exports.timeIt                  = timeIt
