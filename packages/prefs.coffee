{ classes: Cc, interfaces: Ci } = Components

PREF_BRANCH = "extension.VimFx.";

# Default values for the preference
# All used preferences should be mentioned here becuase 
# preference type is derived from here
PREFS = 
  hint_chars: 'asdfgercvhjkl;uinm'
  button_id: 'VimFx-toolbar-button'
  disabled: false

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

# Set firefox preference value
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
    .QueryInterface(Components.interfaces.nsIPrefBranch2)

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

exports.getPref             = getPref
exports.setPref             = setPref
exports.installPrefObserver = installPrefObserver
