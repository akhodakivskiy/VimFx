{ classes: Cc, interfaces: Ci, utils: Cu } = Components

tools = {}
Cu.import "resource://gre/modules/Services.jsm", tools

ww = tools.Services.ww

runOnWindowLoad = (callback, window) ->
  if window.document.readyState == 'complete'
    callback window
  else
    onLoad = ->
      window.removeEventListener 'load', arguments.callee, false
      callback(window)

    window.addEventListener 'load', onLoad, false

applyToWindows = (callback) ->
  winEnum = ww.getWindowEnumerator()
  while winEnum.hasMoreElements()
    window = winEnum.getNext().QueryInterface(Ci.nsIDOMWindow)
    runOnWindowLoad callback, window

isBrowserWindow = (window) ->
  return window.document.documentElement.getAttribute("windowtype") == "navigator:browser"

class WindowObserver
  constructor: (@delegate) ->

  observe: (subject, topic, data) ->
    window = subject.QueryInterface(Ci.nsIDOMWindow)
    switch topic
      when 'domwindowopened'
        runOnWindowLoad @delegate.track, window
      when 'domwindowclosed'
        runOnWindowLoad @delegate.untrack, window

class WindowTracker

  constructor: (@delegate) ->
    @observer = new WindowObserver @delegate

  start: ->
    applyToWindows @delegate.track
    ww.registerNotification @observer

  stop: ->
    ww.unregisterNotification @observer
    applyToWindows @delegate.untrack


exports.runOnWindowLoad = runOnWindowLoad
exports.applyToWindows = applyToWindows
exports.WindowTracker = WindowTracker
exports.isBrowserWindow = isBrowserWindow
