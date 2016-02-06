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

# This file provides VimFx’s config file API (defined in api.coffee). It is kept
# as short as possible on purpose to reduce the need to update it. When VimFx
# updates, consumers of this module do not get updates to this module until the
# next Firefox restart.

EXPORTED_SYMBOLS = ['getAPI']

# Once VimFx has been installed, this file will be available on the file system,
# and the `api_url` pref will be available in Firefox’s prefs system. That’s all
# that is needed to `Cu.import` this file, regardless of whether VimFx has
# loaded or not. When VimFx _is_ loaded, `_invokeCallback` (which requires
# access to the global `VimFx` instance) is set by main.coffee.
_invokeCallback = null

# All requests for the API are stored here.
_callbacks = []

# All callbacks are always stored, in case they need to be re-run in the future.
# If main.coffee already has set `_invokeCallback` then run it. Otherwise let
# main.coffee take care of the queue in `_callbacks` when it loads.
getAPI = (callback) ->
  _callbacks.push(callback)
  _invokeCallback?(callback)
