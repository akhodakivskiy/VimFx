{ WindowTracker, isBrowserWindow, applyToWindows } = require '../packages/window-utils'

setupModule = (module) ->
   module.controller = mozmill.getBrowserController()
  
testWindowTracker = () ->

  controller.open 'http://www.google.com'
  
  countTrack = 0
  countUntrack = 0
  tracker = new WindowTracker
    track: (window) -> countTrack += 1
    untrack: (window) -> countUntrack += 1

  tracker.start()

  mozmill.newBrowserController()

  tracker.stop()

  expect.equal countTrack, 2, 'WindowTracker track failed'
  expect.equal countUntrack, 2, 'WindowTracker untrack failed'


