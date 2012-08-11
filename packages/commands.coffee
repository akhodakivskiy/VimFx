SCROLL_AMOUNT = 60

{ classes: Cc, interfaces: Ci, utils: Cu } = Components

utils = require 'utils'

commands = 
  'g,g': (window) ->
    window.scrollTo(0, 0)

  'G': (window) ->
    window.scrollTo(0, window.document.body.scrollHeight)

  'j': (window) -> 
    window.scrollBy(0, SCROLL_AMOUNT)

  'k': (window) -> 
    window.scrollBy(0, -SCROLL_AMOUNT)

  'd': (window) ->
    window.scrollBy(0, window.innerHeight)

  'u': (window) ->
    window.scrollBy(0, -window.innerHeight)

  'J': (window) ->
    if rootWindow = utils.getRootWindow window
      rootWindow.gBrowser.tabContainer.advanceSelectedTab(1, true);

  'K': (window) ->
    if rootWindow = utils.getRootWindow window
      rootWindow.gBrowser.tabContainer.advanceSelectedTab(-1, true);

  'x': (window) ->
    if rootWindow = utils.getRootWindow window
      rootWindow.gBrowser.removeCurrentTab()

  'X': (window) ->
    if rootWindow = utils.getRootWindow window
      ss = utils.getSessionStore()
      if ss and ss.getClosedTabCount(rootWindow) > 0
        ss.undoCloseTab rootWindow, 0

  'Esc': (window) ->
    window.document.activeElement?.blur()


getCommand = (keys) ->
  sequence = [key.toString() for key in keys].join(',')
  if command = commands[sequence]
    return command
  else if keys.length > 0
    return getCommand keys.slice(1)
  else
    undefined

maybeCommand = (keys) ->
  if keys.length == 0
    return false
  else
    sequence = [key.toString() for key in keys].join(',')
    for s in Object.keys(commands)
      if s.search(sequence) == 0
        return true

    return maybeCommand keys.slice(1)

exports.getCommand      = getCommand
exports.maybeCommand    = maybeCommand
