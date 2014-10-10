###
# Copyright Anton Khodakivskiy 2012.
# Copyright Simon Lydell 2014.
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

class Unloader
  constructor: ->
    @unloaders = []

  unload: ->
    unloader() for unloader in @unloaders
    @unloaders.length = 0

  add: (callback) ->
    # Wrap the callback in a function that ignores failures.
    unloader = -> try callback()
    @unloaders.push(unloader)

exports.unloader = new Unloader
