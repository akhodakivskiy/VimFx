###
# Copyright Anton Khodakivskiy 2012, 2013, 2014.
# Copyright Simon Lydell 2013, 2014.
# Copyright Wang Zhuochun 2013.
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

{ classes: Cc, interfaces: Ci } = Components

PREF_BRANCH = 'extensions.VimFx.'
DEFAULT_PREFS_FILE = 'defaults/preferences/defaults.js'

# Default values for preferences are now specified in
# defaults/preferences/defaults.js.

prefs = Services.prefs
vimfxBranch = prefs.getBranch(PREF_BRANCH)

getBranchPref = (branch, key, defaultValue = undefined) ->
  type = branch.getPrefType(key)
  return switch type
    when branch.PREF_BOOL
      branch.getBoolPref(key)
    when branch.PREF_INT
      branch.getIntPref(key)
    when branch.PREF_STRING
      branch.getComplexValue(key, Ci.nsISupportsString).data
    else
      defaultValue

isPrefSet = (key) ->
  return vimfxBranch.prefHasUserValue(key)

getPref = getBranchPref.bind(undefined, vimfxBranch)

setBranchPref = (branch, key, value) ->
  switch typeof value
    when 'boolean'
      branch.setBoolPref(key, value)
    when 'number'
      branch.setIntPref(key, value)
    when 'string'
      branch.setCharPref(key, value)
    else
      branch.clearUserPref(key)

setPref = setBranchPref.bind(undefined, vimfxBranch)

setDefaultPrefs = ->
  baseUri = Services.io.newURI(__SCRIPT_URI_SPEC__, null, null)
  uri = Services.io.newURI(DEFAULT_PREFS_FILE, null, baseUri)

  branch = prefs.getDefaultBranch('')
  scope = {pref: setBranchPref.bind(undefined, branch)}
  Services.scriptloader.loadSubScript(uri.spec, scope)

exports.isPrefSet         = isPrefSet
exports.getPref           = getPref
exports.setPref           = setPref
exports.setDefaultPrefs   = setDefaultPrefs
