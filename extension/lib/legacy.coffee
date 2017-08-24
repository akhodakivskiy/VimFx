# This file contains functions helping to upgrade to a newer version of VimFx
# without breaking backwards-compatibility. These are used in migrations.coffee.

notation = require('vim-like-key-notation')
prefs = require('./prefs')
utils = require('./utils')

applyMigrations = (migrations) ->
  for migration, index in migrations
    pref = "migration.#{index}.applied"
    # This allows to manually choose migrations to apply. Be careful, though,
    # since some migrations might have to run in order!
    unless prefs.has(pref) and prefs.get(pref)
      migration()
      prefs.set(pref, true)
  return

commaSeparatedList = /.[^,]*,?/g

commaSeparatedListItem = ///^
  (?:
    (?: (Shift) | ([acm])+ )
    -
  )?
  (.+?)
  ,?
$///

convertKey = (keyStr) ->
  return (keyStr.trim().match(commaSeparatedList) ? []).map((part) ->
    [match, shift, modifiers, key] = part.match(commaSeparatedListItem)
    modifiers ?= ''
    return notation.stringify({
      key
      shiftKey: Boolean(shift)
      altKey: 'a' in modifiers
      ctrlKey: 'c' in modifiers
      metaKey: 'm' in modifiers
    })
  )

convertPattern = (pattern) ->
  return utils.regexEscape(pattern)
    .replace(/\\\*/g, '.*')
    .replace(/!/g,    '.')
    .replace(/\s+/g,  '\\s+')

splitListString = (str) ->
  return str.split(/\s*,[\s,]*/)

module.exports = {
  applyMigrations
  convertKey
  convertPattern
  splitListString
}
