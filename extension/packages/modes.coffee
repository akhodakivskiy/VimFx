utils                   = require 'utils'
{ mode_hints }          = require 'mode-hints/mode-hints'
{ setWindowInsertMode } = require 'button'

modes = {}

modes['hints'] = mode_hints

modes['insert'] =
  onEnter: (vim) ->
    return unless rootWindow = utils.getRootWindow(vim.window)
    setWindowInsertMode(rootWindow, true)
  onInput: ->
    return false
  onEnterNormalMode: (vim) ->
    return unless rootWindow = utils.getRootWindow(vim.window)
    setWindowInsertMode(rootWindow, false)
    utils.blurActiveElement(vim.window)

exports.modes = modes
