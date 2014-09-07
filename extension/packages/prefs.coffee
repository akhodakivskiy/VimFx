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
      branch.getCharPref(key)
    else
      defaultValue

isPrefSet = (key) ->
  return vimfxBranch.prefHasUserValue(key)

getPref = getBranchPref.bind(undefined, vimfxBranch)

# Unicode String.
getComplexPref = (key) ->
  return vimfxBranch.getComplexValue(key, Ci.nsISupportsString).data

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
exports.getComplexPref    = getComplexPref
exports.setPref           = setPref
exports.setDefaultPrefs   = setDefaultPrefs
