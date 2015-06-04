###
# Copyright Simon Lydell 2015.
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

EXPORTED_SYMBOLS = ['getAPI']

# Will be set by main.coffee. By passing the API in we make sure that all
# consumers get an up-to-date version. It is also needed to be able to access
# the global `VimFx` instance.
api = null

callbacks = []

setAPI = (passed_api) ->
  api = passed_api
  callback(api) for callback in callbacks
  callbacks.length = 0

getAPI = (callback) ->
  if api == null
    # If this module is imported before main.coffee has set `api`, push the
    # callback to the queue.
    callbacks.push(callback)
  else
    callback(api)
