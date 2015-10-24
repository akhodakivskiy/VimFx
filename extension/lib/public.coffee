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

# This file provides VimFx’s public API (defined in api.coffee) for public
# consumption.

EXPORTED_SYMBOLS = ['getAPI']

# Once VimFx has been installed, this file will be available on the file system,
# and the `api_url` pref will be available in Firefox’s prefs system. That’s all
# that is needed to `Cu.import` this file, regardless of whether VimFx has
# loaded or not. When VimFx _is_ loaded, `api` (which requires access to the
# global `VimFx` instance) is set by main.coffee and passed to all consumers.
api = null

# All requests for the API are stored here.
callbacks = []

# Any time the API is set (when Firefox starts, when VimFx is updated or when
# VimFx is disabled and then enabled), call all callbacks with the new API. This
# takes care of API-consuming add-ons that happen to load before VimFx, as well
# as the case where VimFx is updated in the middle of the session (see below).
setAPI = (passed_api) ->
  api = passed_api
  callback(api) for callback in callbacks
  return

# All callbacks are always stored, in case they need to be re-run in the future.
# If the API is already available, pass it back immediately.
getAPI = (callback) ->
  callbacks.push(callback)
  callback(api) unless api == null

# main.coffee calls this function on shutdown instead of `Cu.unload(apiUrl)`.
# This means that if VimFx is updated (or disabled and then enabled), all
# `getAPI` calls for the old version are re-run with the new version. Otherwise
# you’d have to either restart Firefox, or disable and enable every add-on using
# the API in order for them to take effect.
removeAPI = -> api = null
