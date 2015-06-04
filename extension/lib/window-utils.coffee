# coffeelint: disable=max_line_length

#
# Waits for a browser window to finish loading before running the callback.
#
# @usage runOnLoad(window, callback): Apply a callback to to run on a window when it loads.
# @param [function] callback: 1-parameter function that gets a browser window.
# @param [function] winType: a parameter that defines what kind of window is "browser window".
#
runOnLoad = (window, callback, winType) ->
  # Listen for one load event before checking the window type.
  cb = ->
    window.removeEventListener('load', arguments.callee, false)

    # Now that the window has loaded, only handle browser windows.
    if window.document.documentElement.getAttribute('windowtype') == winType
      callback(window)

  window.addEventListener('load', cb, false)

#
# Add functionality to existing browser windows.
#
# @usage runOnWindows(callback): Apply a callback to each open browser window.
# @param [function] callback: 1-parameter function that gets a browser window.
# @param [function] winType: a parameter that defines what kind of window is "browser window".
#
runOnWindows = (callback, winType) ->
  # Wrap the callback in a function that ignores failures.
  watcher = (window) -> try callback(window)

  # Add functionality to existing windows
  browserWindows = Services.wm.getEnumerator(winType)
  while browserWindows.hasMoreElements()
    # Only run the watcher immediately if the browser is completely loaded.
    browserWindow = browserWindows.getNext()
    if browserWindow.document.readyState == 'complete'
      watcher(browserWindow)
    # Wait for the window to load before continuing.
    else
      runOnLoad(browserWindow, watcher, winType)

#
# Apply a callback to each open and new browser windows.
#
# @usage watchWindows(callback): Apply a callback to each browser window.
# @param [function] callback: 1-parameter function that gets a browser window.
# @param [function] winType: a parameter that defines what kind of window is "browser window".
#
watchWindows = (callback, winType) ->
  # Wrap the callback in a function that ignores failures.
  watcher = (window) -> try callback(window)

  # Add functionality to existing windows.
  runOnWindows(callback, winType)

  # Watch for new browser windows opening then wait for it to load.
  windowWatcher = (subject, topic) ->
    if topic == 'domwindowopened'
      runOnLoad(subject, watcher, winType)

  Services.ww.registerNotification(windowWatcher)

  # Make sure to stop watching for windows if we're unloading.
  module.onShutdown(-> Services.ww.unregisterNotification(windowWatcher))

module.exports = {
  runOnLoad
  runOnWindows
  watchWindows
}
