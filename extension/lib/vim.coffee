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
modes = require('./modes')

module.exports = class Vim
  constructor: (@window) ->
    @rootWindow = utils.getRootWindow(@window) # For convenience.
    @storage = {}
    @lastInteraction = null
    @enterMode('normal')

  enterMode: (mode, args...) ->
    # `args` is an array of arguments to be passed to the mode's `onEnter`
    # method.

    if mode not of modes
      throw new Error("Not a valid VimFx mode to enter: #{ mode }")

    if @mode != mode
      if @mode of modes
        modes[@mode].onLeave(@, @storage[@mode])

      @mode = mode

      modes[@mode].onEnter(@, @storage[@mode] ?= {}, args...)

  onInput: (keyStr, event) ->
    suppress = modes[@mode]?.onInput(@, @storage[@mode], keyStr, event)
    return suppress
