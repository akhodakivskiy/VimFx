{ classes: Cc, interfaces: Ci } = Components

PREF_BRANCH = "extensions.VimFx.";

# Default values for the preference
# All used preferences should be mentioned here becuase 
# preference type is derived from here
PREFS = 
  addon_id:     'VimFx@akhodakivskiy.github.com'
  hint_chars:   'asdfgercvhjkl;uinm'
  disabled:     false
  scroll_step:  60
  scroll_time:  100
  black_list:   '*mail.google.com*'
  blur_on_esc:  true

# Get Firefox preference value of type specified in `PREFS`
getFFPref = do ->
  branch = Services.prefs.getBranch PREF_BRANCH
  
  return (key) ->
    value = PREFS[key]

    # Return default value if the preference value hasn't been set yet
    if branch.getPrefType(key) == branch.PREF_INVALID
      return value;

    switch typeof value 
      when 'boolean'
        return branch.getBoolPref key
      when 'number'
        return branch.getIntPref key
      else
        return branch.getCharPref key

# Assign and save Firefox preference value
setFFPref = do ->
  branch = Services.prefs.getBranch PREF_BRANCH

  return (key, value) ->
    switch typeof value
      when 'boolean'
        branch.setBoolPref(key, value)
      when 'number'
        branch.setIntPref(key, value)
      else
        branch.setCharPref(key, String(value));

# Set default values and update previously stored values for the preferences
do ->
  branch = Services.prefs.getBranch PREF_BRANCH
  for key in Object.keys(PREFS)
    if branch.getPrefType(key) == branch.PREF_INVALID
      setFFPref key, PREFS[key]
    else
      PREFS[key] = getFFPref key

# Monitor preference changes and update values in local cache - PREFS
installPrefObserver = ->
  branch = Services.prefs.getBranch(PREF_BRANCH)

  observer = 
    observe: (subject, topic, data) ->
      if topic == 'nsPref:changed' and data in Object.keys(PREFS)
        PREFS[data] = getFFPref data

  branch.addObserver "", observer, false
  unload -> branch.removeObserver "", observer

# Get preference value from local cache - PREFS
getPref = (key) -> return PREFS[key]

# Set preference value
setPref = (key, value) -> setFFPref key, value

# Transfer all setting values from one branch to another
transferPrefs = (from, to) ->
  fromBranch = Services.prefs.getBranch from
  toBranch = Services.prefs.getBranch to

  count = {}
  vals = fromBranch.getChildList("", count)

  for i in [0...count.value]
    name = vals[i]
    switch fromBranch.getPrefType name
      when fromBranch.PREF_STRING 
        toBranch.setCharPref name, fromBranch.getCharPref name
      when fromBranch.PREF_INT 
        toBranch.setIntPref name, fromBranch.getIntPref name
      when fromBranch.PREF_BOOL 
        toBranch.setBoolPref name, fromBranch.getBoolPref name

  fromBranch.deleteBranch("")


exports.getPref             = getPref
exports.setPref             = setPref
exports.installPrefObserver = installPrefObserver
exports.transferPrefs       = transferPrefs
