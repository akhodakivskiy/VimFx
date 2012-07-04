{ WindowTracker, isBrowserWindow, applyToWindows } = require '../packages/window-utils'

setupModule = (module) ->
   module.controller = mozmill.getBrowserController()
   tabBrowser = new TabbedBrowsingAPI.tabBrowser(controller);  
  
testWindowTracker = () ->

  controller.open 'http://www.google.com'
  
  count = 0
  tracker = new WindowTracker
    track: (window) -> count += 1
    untrack: (window) -> count += 1

  tracker.start()
  tracker.stop()

  expect.equal count, 2, 'WindowTracker failed'

