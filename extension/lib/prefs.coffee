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

defaults = require('./defaults')

{ classes: Cc, interfaces: Ci } = Components

prefs = Services.prefs
vimfxBranch = prefs.getBranch(defaults.BRANCH)
vimfxDefaultBranch = prefs.getDefaultBranch(defaults.BRANCH)

isPrefSet = (key) -> vimfxBranch.prefHasUserValue(key)

getBranchPref = (branch, key) ->
  return switch branch.getPrefType(key)
    when branch.PREF_BOOL
      branch.getBoolPref(key)
    when branch.PREF_INT
      branch.getIntPref(key)
    when branch.PREF_STRING
      branch.getComplexValue(key, Ci.nsISupportsString).data

getPref        = getBranchPref.bind(undefined, vimfxBranch)
getFirefoxPref = getBranchPref.bind(undefined, prefs)

setBranchPref = (branch, key, value) ->
  switch typeof value
    when 'boolean'
      branch.setBoolPref(key, value)
    when 'number'
      branch.setIntPref(key, value)
    when 'string'
      str = Cc['@mozilla.org/supports-string;1']
        .createInstance(Ci.nsISupportsString)
      str.data = value
      branch.setComplexValue(key, Ci.nsISupportsString, str)
    else
      branch.clearUserPref(key)

setPref        = setBranchPref.bind(undefined, vimfxBranch)
setDefaultPref = setBranchPref.bind(undefined, vimfxDefaultBranch)
setFirefoxPref = setBranchPref.bind(undefined, prefs)

withFirefoxPrefAs = (pref, temporaryValue, fn) ->
  previousValue = getFirefoxPref(pref)
  setFirefoxPref(pref, temporaryValue)
  fn()
  setFirefoxPref(pref, previousValue)

setDefaultPrefs = ->
  setDefaultPref(key, value) for key, value of defaults.all
  return

exports.isPrefSet         = isPrefSet
exports.getPref           = getPref
exports.getFirefoxPref    = getFirefoxPref
exports.setPref           = setPref
exports.setFirefoxPref    = setFirefoxPref
exports.withFirefoxPrefAs = withFirefoxPrefAs
exports.setDefaultPrefs   = setDefaultPrefs
