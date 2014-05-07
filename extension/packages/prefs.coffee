{ classes: Cc, interfaces: Ci } = Components

{ unload } = require 'unload'

PREF_BRANCH = 'extensions.VimFx.'
DEFAULT_PREFS_FILE = 'defaults/preferences/defaults.js'

# Default values for preferences are now specified in
# defaults/preferences/defaults.js

getBranchPref = (branch, key, defaultValue) ->
  type = branch.getPrefType(key)

  switch type
    when branch.PREF_BOOL
      return branch.getBoolPref(key)
    when branch.PREF_INT
      return branch.getIntPref(key)
    when branch.PREF_STRING
      return branch.getCharPref(key)
    else
      if defaultValue != undefined
        return defaultValue

isPrefSet = do ->
  prefs = Cc['@mozilla.org/preferences-service;1'].getService(Ci.nsIPrefService)
  branch = prefs.getBranch(PREF_BRANCH)

  return (key) ->
    branch.prefHasUserValue(key)

getPref = do ->
  prefs = Cc['@mozilla.org/preferences-service;1'].getService(Ci.nsIPrefService)
  branch = prefs.getBranch(PREF_BRANCH)

  return (key, defaultValue = undefined) ->
    return getBranchPref(branch, key, defaultValue)

# Unicode String
getComplexPref = do ->
  prefs = Cc['@mozilla.org/preferences-service;1'].getService(Ci.nsIPrefService)
  branch = prefs.getBranch(PREF_BRANCH)

  return (key) ->
    return branch.getComplexValue(key, Ci.nsISupportsString).data

getFirefoxPref = do ->
  prefs = Cc['@mozilla.org/preferences-service;1'].getService(Ci.nsIPrefService)
  branch = prefs.getBranch('')

  return (key, defaultValue = undefined) ->
    return getBranchPref(branch, key, defaultValue)

makePrefSetter = (branch) ->
  return (key, value) ->
    switch typeof value
      when 'boolean'
        branch.setBoolPref(key, value)
      when 'number'
        branch.setIntPref(key, value)
      when 'string'
        branch.setCharPref(key, value)
      else
        branch.clearUserPref(key)

# Assign and save Firefox preference value
setPref = do ->
  prefs = Cc['@mozilla.org/preferences-service;1'].getService(Ci.nsIPrefService)
  return makePrefSetter(prefs.getBranch(PREF_BRANCH))

setDefaultPrefs = ->
  scriptLoader = Cc['@mozilla.org/moz/jssubscript-loader;1'].getService(Ci.mozIJSSubScriptLoader)
  ioService = Cc['@mozilla.org/network/io-service;1'].getService(Ci.nsIIOService)
  prefs = Cc["@mozilla.org/preferences-service;1"].getService(Ci.nsIPrefService)

  baseUri = ioService.newURI(__SCRIPT_URI_SPEC__, null, null)
  uri = ioService.newURI(DEFAULT_PREFS_FILE, null, baseUri)

  branch = prefs.getDefaultBranch("")
  scope = { pref: makePrefSetter(branch) }
  scriptLoader.loadSubScript(uri.spec, scope)

exports.isPrefSet         = isPrefSet
exports.getPref           = getPref
exports.getComplexPref    = getComplexPref
exports.getFirefoxPref    = getFirefoxPref
exports.setPref           = setPref
exports.setDefaultPrefs   = setDefaultPrefs
