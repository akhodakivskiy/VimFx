###
# Copyright Simon Lydell 2016.
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
    if numSuccesses == -1
      'The stuff you pasted is invalid:'
    else
      s1 = if numSuccesses == 1 then '' else 's'
      s2 = if errors.length == 1 then '' else 's'
      """
        #{numSuccesses} option#{s1} imported successfully.

        #{errors.length} error#{s2} occurred:
      """

  return """
    #{header}

    #{errors.join('\n')}
  """

module.exports = {
  resetAll
  exportAll
  importExported
  createImportErrorReport
}
