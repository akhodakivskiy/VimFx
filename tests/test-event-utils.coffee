{ WindowEventTracker } = require '../packages/event-utils'

setupModule = (module) ->
   module.controller = mozmill.getBrowserController()

testWindowEventTracker = () ->

  count = 0
  tracker = new WindowEventTracker
    keypress: (event) -> count += 1

  tracker.start()

  controller.rootElement.keypress("k")

  expect.equal count, 1, 'WindowEventTracker keypress failed'


