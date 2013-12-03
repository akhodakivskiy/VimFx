{ classes: Cc, interfaces: Ci } = Components

{ unload } = require 'unload'

PREF_BRANCH = 'extensions.VimFx.'

# Default values for the preference
# All used preferences should be mentioned here becuase
# preference type is derived from here
DEFAULT_PREF_VALUES =
  addon_id:           'VimFx@akhodakivskiy.github.com'
  hint_chars:         'fjdkslaghrueiwovncm' # preferably use letters only
  prev_patterns:      'prev,previous,back,<,\xab,<<'
  next_patterns:      'next,more,>,\xbb,>>'
  disabled:           false
  scroll_step_lines:  6
  black_list:         '*mail.google.com*'
  hints_bloom_data:   ''
  hints_bloom_on:     true


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
    value = getBranchPref(branch, key, defaultValue)
    return if value == undefined then getDefaultPref(key) else value

# Unicode String
getComplexPref = do ->
  prefs = Cc['@mozilla.org/preferences-service;1'].getService(Ci.nsIPrefService)
  branch = prefs.getBranch(PREF_BRANCH)

  return (key, defaultValue = undefined) ->
    value = branch.getComplexValue(key, Components.interfaces.nsISupportsString).data
    return if value == undefined then getDefaultPref(key) else value

getDefaultPref = (key) -> return DEFAULT_PREF_VALUES[key]

getFirefoxPref = do ->
  prefs = Cc['@mozilla.org/preferences-service;1'].getService(Ci.nsIPrefService)
  branch = prefs.getBranch('')

  return (key, defaultValue = undefined) ->
    return getBranchPref(branch, key, defaultValue)

# Assign and save Firefox preference value
setPref = do ->
  prefs = Cc['@mozilla.org/preferences-service;1'].getService(Ci.nsIPrefService)
  branch = prefs.getBranch(PREF_BRANCH)

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

initPrefValues = ->
  for key, value of DEFAULT_PREF_VALUES
    if not isPrefSet(key)
      setPref(key, value)

exports.isPrefSet         = isPrefSet
exports.getPref           = getPref
exports.getComplexPref    = getComplexPref
exports.getDefaultPref    = getDefaultPref
exports.getFirefoxPref    = getFirefoxPref
exports.setPref           = setPref
exports.initPrefValues    = initPrefValues
