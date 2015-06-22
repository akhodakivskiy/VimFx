###
# Copyright Anton Khodakivskiy 2012, 2013.
# Copyright Simon Lydell 2013, 2014.
#
# This file is part of VimFx.
#
# VimFx is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# VimFx is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with VimFx.  If not, see <http://www.gnu.org/licenses/>.
###

utils = require('./utils')

class Vim
  constructor: (@window, @parent) ->
    @rootWindow = utils.getRootWindow(@window) # For convenience.
    @storage = {}
    @resetState(true)

  resetState: (force = false) ->
    @state =
      lastInteraction: null
      lastAutofocusPrevention: null
      scrollableElements: new WeakMap()
      lastFocusedTextInput: null

    if @isBlacklisted()
      @enterMode('insert')
    else
      @enterMode('normal') if force or @mode == 'insert'

    @parent.emit('load', {vim: this, location: @window.location})

  isBlacklisted: ->
    url = @rootWindow.gBrowser.currentURI.spec
    return @parent.options.black_list.some((regex) -> regex.test(url))

  # `args` is an array of arguments to be passed to the mode's `onEnter` method.
  enterMode: (mode, args...) ->
    return if @mode == mode

    unless utils.has(@parent.modes, mode)
      modes = Object.keys(@parent.modes).join(', ')
      throw new Error("VimFx: Unknown mode. Available modes are: #{ modes }.
                       Got: #{ mode }")

    @call('onLeave')
    @mode = mode
    @call('onEnter', {args})
    @parent.emit('modeChange', this)

  onInput: (event) ->
    match = @parent.consumeKeyEvent(event, this)
    return false unless match
    suppress = @call('onInput', {event, count: match.count}, match)
    return suppress

  call: (method, data = {}, extraArgs...) ->
    currentMode = @parent.modes[@mode]
    args = Object.assign({vim: this, storage: @storage[@mode] ?= {}}, data)
    currentMode?[method].call(currentMode, args, extraArgs...)

module.exports = Vim
