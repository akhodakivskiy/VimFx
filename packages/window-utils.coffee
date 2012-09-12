{ classes: Cc, interfaces: Ci, utils: Cu } = Components

{ getWindowId } = require 'utils'

tools = {}
Cu.import "resource://gre/modules/Services.jsm", tools

ww = tools.Services.ww

# Will run `callback` funcion with `window` passed as argument
# when the window finishes loading. The function is run 
# synchronously if the window has finished loading.
runOnWindowLoad = (callback, window) ->
  if window.document.readyState == 'complete'
    callback window
  else
    onLoad = ->
      window.removeEventListener 'load', arguments.callee, true
      callback(window)

    window.addEventListener 'load', onLoad, true

# Applies `runOnWindowLoad` to all windows currently opened
# passing it the `callback` argument
applyToWindows = (callback) ->
  winEnum = ww.getWindowEnumerator()
  while winEnum.hasMoreElements()
    window = winEnum.getNext().QueryInterface(Ci.nsIDOMWindow)
    runOnWindowLoad callback, window

# Checks if the window is a top level window, typically 
# an instance of ChromeWindow. I'm kind of confused with the
# terms
isBrowserWindow = (window) ->
  return window.document.documentElement.getAttribute("windowtype") == "navigator:browser"

# Class whose instanced passed to WindowWatcher service
# will receive notifications when new top level windows 
# are opened/closed. It won't be notified about windows
# that were open when observer has been registered.
class WindowObserver
  constructor: (@delegate) ->

  observe: (subject, topic, data) ->
    window = subject.QueryInterface(Ci.nsIDOMWindow)
    switch topic
      when 'domwindowopened'
        runOnWindowLoad @delegate.track, window
      when 'domwindowclosed'
        runOnWindowLoad @delegate.untrack, window

# Class that will track all top level windows
# Each time a window is opened/closed the `track` and `untrack`
# methods will be called on the window
class WindowTracker

  constructor: (@delegate) ->
    @observer = new WindowObserver @delegate

  start: ->
    # We have to run the track on all windows that have already
    # been opened
    applyToWindows @delegate.track
    ww.registerNotification @observer

  stop: ->
    # And run untack as well
    ww.unregisterNotification @observer
    applyToWindows @delegate.untrack

exports.runOnWindowLoad           = runOnWindowLoad
exports.applyToWindows            = applyToWindows
exports.WindowTracker             = WindowTracker
exports.isBrowserWindow           = isBrowserWindow
