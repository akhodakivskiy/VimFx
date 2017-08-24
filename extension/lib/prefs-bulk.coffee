# This files deals with handling all, or many, of VimFx’s prefs in bulk.

defaults = require('./defaults')
prefs = require('./prefs')

resetAll = ->
  prefs.set(pref, null) for pref of defaults.all_prefs
  return

exportAll = ->
  regular = (pref for pref of defaults.all_prefs)
  custom = Services.prefs.getBranch(defaults.BRANCH).getChildList('custom.')
  exported = {}
  for pref in regular.concat(custom) when prefs.has(pref)
    exported[pref] = prefs.get(pref)
  return exported

importExported = (exportedString) ->
  exported = null
  try
    exported = JSON.parse(exportedString)
  catch error
    return {
      numSuccesses: -1
      errors: [error.message]
    }

  unless Object::toString.call(exported) == '[object Object]' and
         Object.keys(exported).length > 0
    return {
      numSuccesses: -1
      errors: ["The input must be a non-empty object. Got: #{exportedString}"]
    }

  numSuccesses = 0
  errors = []

  for pref, value of exported
    unless Object::hasOwnProperty.call(defaults.all_prefs, pref) or
           pref.startsWith('custom.')
      errors.push("#{pref}: Unknown pref.")
      continue

    try
      # `prefs.set` handles validation of `value`.
      prefs.set(pref, value)
    catch error
      errors.push("#{pref}: #{error.message.replace(/^VimFx: /, '')}")
      continue

    numSuccesses += 1

  return {numSuccesses, errors}

createImportErrorReport = ({numSuccesses, errors}) ->
  header =
    if numSuccesses <= 0
      'The stuff you entered is invalid:'
    else
      s1 = if numSuccesses == 1 then '' else 's'
      s2 = if errors.length == 1 then '' else 's'
      """
        #{numSuccesses} option#{s1} imported successfully.

        #{errors.length} error#{s2} also occurred:
      """

  return """
    #{header}

    #{errors.join('\n\n')}
  """

module.exports = {
  resetAll
  exportAll
  importExported
  createImportErrorReport
}
