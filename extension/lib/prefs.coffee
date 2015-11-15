###
# Copyright Anton Khodakivskiy 2012, 2013, 2014.
# Copyright Simon Lydell 2013, 2014, 2015.
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

# This file provides an API a bit more easy to use than the very low-level
# Firefox prefs APIs.

defaults = require('./defaults')

{prefs} = Services

branches =
  addon:
    user:    prefs.getBranch(defaults.BRANCH)
    default: prefs.getDefaultBranch(defaults.BRANCH)
  root:
    user:    prefs
    default: prefs.getDefaultBranch('')

get = (branch, key) ->
  return switch branch.getPrefType(key)
    when branch.PREF_BOOL
      branch.getBoolPref(key)
    when branch.PREF_INT
      branch.getIntPref(key)
    when branch.PREF_STRING
      branch.getComplexValue(key, Ci.nsISupportsString).data

set = (branch, key, value) ->
  switch typeof value
    when 'boolean'
      branch.setBoolPref(key, value)
    when 'number'
      branch.setIntPref(key, value) # `value` will be `Math.floor`ed.
    when 'string'
      str = Cc['@mozilla.org/supports-string;1']
        .createInstance(Ci.nsISupportsString)
      str.data = value
      branch.setComplexValue(key, Ci.nsISupportsString, str)
    else
      if value == null
        branch.clearUserPref(key)
      else
        throw new Error("VimFx: Prefs may only be set to a boolean, number,
                         string or null. Got: #{typeof value}")

has = (branch, key) ->
  branch.prefHasUserValue(key)

tmp = (branch, pref, temporaryValue) ->
  previousValue = if has(branch, pref) then get(branch, pref) else null
  set(branch, pref, temporaryValue)
  return -> set(branch, pref, previousValue)

observe = (branch, domain, callback) ->
  observer = {observe: (branch, topic, changedPref) -> callback(changedPref)}
  branch.addObserver(domain, observer, false)
  module.onShutdown(->
    branch.removeObserver(domain, observer)
  )

module.exports =
  get: get.bind(null, branches.addon.user)
  set: set.bind(null, branches.addon.user)
  has: has.bind(null, branches.addon.user)
  tmp: tmp.bind(null, branches.addon.user)
  observe: observe.bind(null, branches.addon.user)
  default:
    get: get.bind(null, branches.addon.default)
    set: set.bind(null, branches.addon.default)
    init: ->
      for key, value of defaults.all_prefs
        module.exports.default.set(key, value)
      return
  root:
    get: get.bind(null, branches.root.user)
    set: set.bind(null, branches.root.user)
    has: has.bind(null, branches.root.user)
    tmp: tmp.bind(null, branches.root.user)
    default:
      get: get.bind(null, branches.root.default)
      set: set.bind(null, branches.root.default)
  unbound: {get, set, has, tmp, observe}
