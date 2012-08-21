{ WindowTracker, isBrowserWindow } = require 'window-utils'


class Bucket
  constructor: (@idFunc, @newFunc) ->
    @bucket = {}

  get: (obj) ->
    id = @idFunc obj
    @bucket[id] or @bucket[id] = @newFunc obj

  forget: (obj) ->
    id = @idFunc obj
    delete @bucket[id] if id


class WindowEventTracker
  constructor: (events, eventFilter = null) ->

    handlerFilter = (handler) ->
      return (event) ->
        if !eventFilter or eventFilter event
          handler event

    addEventListeners = (window) ->
      for name, handler of events
        window.addEventListener name, handlerFilter(handler), true

    removeEventListeners = (window) ->
      for name, handler of events
        window.removeEventListener name, handlerFilter(handler), true

    @windowTracker = new WindowTracker
      track: (window) -> 
        if isBrowserWindow window
          addEventListeners window

      untrack: (window) ->
        if isBrowserWindow window
          removeEventListeners window

  start: -> @windowTracker.start()
  stop: -> @windowTracker.stop()

{ interfaces: Ci } = Components

HTMLInputElement    = Ci.nsIDOMHTMLInputElement
HTMLTextAreaElement = Ci.nsIDOMHTMLTextAreaElement
HTMLSelectElement   = Ci.nsIDOMHTMLSelectElement
XULDocument         = Ci.nsIDOMXULDocument
XULElement          = Ci.nsIDOMXULElement
HTMLDocument        = Ci.nsIDOMHTMLDocument
HTMLElement         = Ci.nsIDOMHTMLElement
Window              = Ci.nsIDOMWindow
ChromeWindow        = Ci.nsIDOMChromeWindow

isRootWindow = (window) -> 
  window.location == "chrome://browser/content/browser.xul"

getEventWindow = (event) ->
  if event.originalTarget instanceof Window
    return event.originalTarget
  else 
    doc = event.originalTarget.ownerDocument or event.originalTarget
    if doc instanceof HTMLDocument or doc instanceof XULDocument
      return doc.defaultView 

getEventTabWindow = (event) ->
  if window = getEventWindow event
    if isRootWindow window
      return window.gBrowser.tabs.selectedItem?.contentWindow.wrappedJSObject
    else
      return window

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

exports.WindowEventTracker      = WindowEventTracker
exports.Bucket                  = Bucket
exports.isRootWindow            = isRootWindow
exports.getEventWindow          = getEventWindow
exports.getEventTabWindow       = getEventTabWindow
exports.getEventRootWindow      = getEventRootWindow
exports.getEventTabBrowser      = getEventTabBrowser

exports.getWindowId             = getWindowId
exports.getRootWindow           = getRootWindow
exports.isElementEditable       = isElementEditable
exports.getSessionStore         = getSessionStore
