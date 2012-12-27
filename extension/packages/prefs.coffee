{ classes: Cc, interfaces: Ci } = Components

PREF_BRANCH = "extensions.VimFx.";

# Default values for the preference
# All used preferences should be mentioned here becuase 
# preference type is derived from here
DEFAULT_PREF_VALUES = 
  addon_id:     'VimFx@akhodakivskiy.github.com'
  hint_chars:   'asdfgercvhjkl;uinm'
  disabled:     false
  scroll_step:  60
  scroll_time:  100
  black_list:   '*mail.google.com*'
  blur_on_esc:  true

getPref = do ->
  branch = Services.prefs.getBranch PREF_BRANCH
  
  return (key, defaultValue=undefined) ->
    type = branch.getPrefType(key)

    switch type
      when branch.PREF_BOOL
        return branch.getBoolPref key
      when branch.PREF_INT
        return branch.getIntPref key
      when branch.PREF_STRING
        return branch.getCharPref key
      else
        if defaultValue != undefined
          return defaultValue
        else
          return DEFAULT_PREF_VALUES[key];

# Assign and save Firefox preference value
setPref = do ->
  branch = Services.prefs.getBranch PREF_BRANCH

  return (key, value) ->
    switch typeof value
      when 'boolean'
        branch.setBoolPref(key, value)
      when 'number'
        branch.setIntPref(key, value)
      when 'string'
        branch.setCharPref(key, value);
      else
        branch.clearUserPref(key);


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

# Checks if given command is disabled in the preferences
isCommandDisabled = (key) ->
  return getPref("disabled_commands", "").split("||").indexOf(key) > -1

# Adds command to the disabled list
disableCommand = (key) ->
  dc = getPref("disabled_commands", "").split("||")
  dc.push key
  setPref "disabled_commands", dc.join("||")

# Enables command
enableCommand = (key) ->
  dc = getPref("disabled_commands", "").split("||")
  while (index = dc.indexOf(key)) > -1
    dc.splice(index, 1)
  setPref "disabled_commands", dc.join("||")

exports.getPref             = getPref
exports.setPref             = setPref
exports.transferPrefs       = transferPrefs
exports.isCommandDisabled   = isCommandDisabled
exports.disableCommand      = disableCommand
exports.enableCommand       = enableCommand
