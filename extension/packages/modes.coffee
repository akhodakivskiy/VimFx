utils                   = require 'utils'
{ mode_hints }          = require 'mode-hints/mode-hints'
{ updateToolbarButton } = require 'button'

modes = {}

modes['hints'] = mode_hints

modes['insert'] =
  onEnter: (vim) ->
    return unless rootWindow = utils.getRootWindow(vim.window)
    updateToolbarButton(rootWindow, {insertMode: true})
  onInput: ->
    return false
  onEnterNormalMode: (vim) ->
    return unless rootWindow = utils.getRootWindow(vim.window)
    updateToolbarButton(rootWindow, {insertMode: false})
    utils.blurActiveElement(vim.window)

exports.modes = modes
