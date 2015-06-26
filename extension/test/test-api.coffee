###
# Copyright Simon Lydell 2015.
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

prefs = require('../lib/prefs')

{ utils: Cu } = Components

{ getAPI } = Cu.import(
  Services.prefs.getCharPref('extensions.VimFx.api_url'), {}
)

exports['test exports'] = (assert, passed_vimfx) -> getAPI((vimfx) ->
  assert.equal(typeof vimfx.get, 'function', 'get')
  assert.equal(typeof vimfx.set, 'function', 'set')
  assert.equal(typeof vimfx.addCommand, 'function', 'addCommand')
  assert.equal(typeof vimfx.addOptionOverrides, 'function',
               'addOptionOverrides')
  assert.equal(typeof vimfx.addKeyOverrides, 'function', 'addKeyOverrides')
  assert.equal(typeof vimfx.on, 'function', 'on')
  assert.equal(typeof vimfx.refresh, 'function', 'refresh')
  assert.equal(vimfx.modes, passed_vimfx.modes, 'modes')
  assert.equal(vimfx.categories, passed_vimfx.options.categories, 'categories')
)

exports['test get'] = (assert, passed_vimfx) -> getAPI((vimfx) ->
  prefs.tmp('hint_chars', 'abcd', ->
    assert.equal(vimfx.get('hint_chars'), 'abcd')
  )
)

exports['test customization'] = (assert, passed_vimfx) -> getAPI((vimfx) ->
  # Save some values that need to be temporarily changed below.
  originalOptions = Object.assign({}, passed_vimfx.options)
  originalCategories = Object.assign({}, passed_vimfx.options.categories)

  # Setup some settings for testing.
  passed_vimfx.options.keyValidator = null
  passed_vimfx.options.ignore_keyboard_layout = true
  vimfx.set('translations', {KeyQ: ['ö', 'Ö']})

  nonce = {}
  event = {code: 'KeyQ'}

  # Add a simple test command.
  vimfx.addCommand({
    name:        'test_command'
    description: 'Test command'
  }, -> nonce)
  vimfx.set('custom.mode.normal.test_command', 'ö')

  # Add a slightly more complex command.
  vimfx.categories['new_category'] = {
    name:  -> 'New category'
    order: -100
  }
  vimfx.addCommand({
    name:        'test_command'
    description: 'Test ignore mode command'
    mode:        'ignore'
    category:    'new_category'
  }, -> nonce)
  vimfx.set('custom.mode.ignore.test_command', 'ö  <ö>  <c-c-invalid>')

  # Test that the new simple command can be run.
  passed_vimfx.reset('normal')
  match = passed_vimfx.consumeKeyEvent(event, 'normal')
  assert.equal(match.type, 'full')
  assert.equal(match.command.run(), nonce)

  # Test that the new complex command can be run.
  passed_vimfx.reset('ignore')
  match = passed_vimfx.consumeKeyEvent(event, 'ignore')
  assert.equal(match.type, 'full')
  assert.equal(match.command.run(), nonce)

  modes = passed_vimfx.getGroupedCommands({enabledOnly: true})

  # Test that the new simple command can show up in the help dialog.
  mode_normal = modes.find((mode) -> mode._name == 'normal')
  category_misc = mode_normal.categories.find(
    (category) -> category._name == 'misc'
  )
  [ ..., { command: test_command } ] = category_misc.commands
  assert.equal(test_command.description(), 'Test command')

  # Test that the new complex command can show up in the help dialog.
  mode_ignore = modes.find((mode) -> mode._name == 'ignore')
  [ category_new ] = mode_ignore.categories
  assert.equal(category_new.name, 'New category')
  [ test_command ] = category_new.commands
  assert.equal(test_command.command.description(), 'Test ignore mode command')
  assert.deepEqual(test_command.enabledSequences, ['<ö>'])

  # Remove the added commands.
  delete vimfx.modes.normal.commands.test_command
  delete vimfx.modes.ignore.commands.test_command
  vimfx.refresh()

  # Test that the new simple command cannot be run.
  passed_vimfx.reset('normal')
  match = passed_vimfx.consumeKeyEvent(event, 'normal')
  if match.type == 'full'
    value = try match.command.run() catch then null
    assert.notEqual(value, nonce)

  # Test that the new complex command cannot be run.
  passed_vimfx.reset('ignore')
  match = passed_vimfx.consumeKeyEvent(event, 'ignore')
  if match.type == 'full'
    value = try match.command.run() catch then null
    assert.notEqual(value, nonce)

  modes = passed_vimfx.getGroupedCommands({enabledOnly: true})

  # Test that the new simple command cannot show up in the help dialog.
  mode_normal = modes.find((mode) -> mode._name == 'normal')
  category_misc = mode_normal.categories.find(
    (category) -> category._name == 'misc'
  )
  [ ..., { command: last_command } ] = category_misc.commands
  assert.notEqual(last_command.description(), 'Test command')

  # Test that the new complex command cannot show up in the help dialog.
  mode_ignore = modes.find((mode) -> mode._name == 'ignore')
  [ first_category ] = mode_ignore.categories
  assert.notEqual(first_category.name, 'New category')

  # Restore original values.
  passed_vimfx.options = originalOptions
  passed_vimfx.options.categories = originalCategories
)

exports['test addCommand order'] = (assert, passed_vimfx) -> getAPI((vimfx) ->
  vimfx.addCommand({
    name:        'test_command'
    description: 'Test command'
    order:       0
  }, Function.prototype)
  vimfx.set('custom.mode.normal.test_command', 'ö')

  modes = passed_vimfx.getGroupedCommands()
  mode_normal = modes.find((mode) -> mode._name == 'normal')
  category_misc = mode_normal.categories.find(
    (category) -> category._name == 'misc'
  )
  [ { command: first_command } ] = category_misc.commands
  assert.equal(first_command.description(), 'Test command')

  delete vimfx.modes.normal.commands.test_command
)

exports['test addOptionOverrides'] = (assert, passed_vimfx) -> getAPI((vimfx) ->
  originalOptions = Object.assign({}, passed_vimfx.options)
  originalOptionOverrides = Object.assign({}, passed_vimfx.optionOverrides)

  passed_vimfx.optionOverrides = null
  passed_vimfx.options.prevent_autofocus = true

  vimfx.addOptionOverrides(
    [
      (location) -> location.hostname == 'example.com'
      {prevent_autofocus: false}
    ]
  )

  assert.equal(passed_vimfx.options.prevent_autofocus, true)

  passed_vimfx.currentVim =
    window:
      location: {hostname: 'example.com'}

  assert.equal(passed_vimfx.options.prevent_autofocus, false)

  passed_vimfx.options = originalOptions
  passed_vimfx.optionOverrides = originalOptionOverrides
)

exports['test addKeyOverrides'] = (assert, passed_vimfx) -> getAPI((vimfx) ->
  originalOptions = Object.assign({}, passed_vimfx.options)
  originalKeyOverrides = Object.assign({}, passed_vimfx.keyOverrides)

  passed_vimfx.options.keyValidator = null
  passed_vimfx.options.ignore_keyboard_layout = false
  passed_vimfx.options.translations = {}

  vimfx.addKeyOverrides(
    [
      (location, mode) -> mode == 'normal' and location.hostname == 'example.co'
      ['j', '<c-foobar>']
    ],
    [
      (location, mode) -> mode == 'ignore' and location.href == 'about:blank'
      ['<escape>']
    ]
  )

  prefs.tmp('mode.normal.scroll_to_bottom', '<foobar>j', ->
    passed_vimfx.reset('normal')

    match = passed_vimfx.consumeKeyEvent({key: 'j'}, 'ignore')
    assert.ok(match)

    passed_vimfx.currentVim =
      window:
        location: {hostname: 'example.co', href: 'about:blank'}

    match = passed_vimfx.consumeKeyEvent({key: '1'}, 'normal')
    assert.equal(match.type, 'count')
    assert.equal(match.count, 1)

    match = passed_vimfx.consumeKeyEvent({key: 'j'}, 'normal')
    assert.ok(not match)

    match = passed_vimfx.consumeKeyEvent({key: 'foobar', ctrlKey: true},
                                         'normal')
    assert.ok(not match)

    match = passed_vimfx.consumeKeyEvent({key: 'foobar'}, 'normal')
    assert.equal(match.type, 'partial')
    match = passed_vimfx.consumeKeyEvent({key: 'j'}, 'normal')
    assert.equal(match.type, 'full')
    assert.strictEqual(match.count, undefined)

    passed_vimfx.reset('ignore')

    match = passed_vimfx.consumeKeyEvent({key: 'j'}, 'ignore')
    assert.ok(match)

    match = passed_vimfx.consumeKeyEvent({key: 'escape'}, 'ignore')
    assert.ok(not match)
  )

  passed_vimfx.options = originalOptions
  passed_vimfx.keyOverrides = originalKeyOverrides
)

exports['test vimfx.[gs]et errors'] = (assert) -> getAPI((vimfx) ->
  throws(assert, /unknown pref/i, 'undefined', ->
    vimfx.get()
  )

  throws(assert, /unknown pref/i, 'undefined', ->
    vimfx.set()
  )

  throws(assert, /unknown pref/i, 'unknown_pref', ->
    vimfx.get('unknown_pref')
  )

  throws(assert, /unknown pref/i, 'unknown_pref', ->
    vimfx.set('unknown_pref', 'foo')
  )

  throws(assert, /boolean, number, string or null/i, 'undefined', ->
    vimfx.set('hint_chars')
  )

  throws(assert, /boolean, number, string or null/i, 'object', ->
    vimfx.set('hint_chars', ['a', 'b', 'c'])
  )
)

exports['test vimfx.addCommand errors'] = (assert) -> getAPI((vimfx) ->
  throws(assert, /name.+string.+required/i, 'undefined', ->
    vimfx.addCommand()
  )

  throws(assert, /name.+a-z.+underscore/i, 'Command', ->
    vimfx.addCommand({name: 'Command'})
  )

  throws(assert, /name.+a-z.+underscore/i, 'command-name', ->
    vimfx.addCommand({name: 'command-name'})
  )

  throws(assert, /name.+a-z.+underscore/i, 'ö', ->
    vimfx.addCommand({name: 'ö'})
  )

  throws(assert, /non-empty description/i, 'undefined', ->
    vimfx.addCommand({name: 'test'})
  )

  throws(assert, /non-empty description/i, '', ->
    vimfx.addCommand({name: 'test', description: ''})
  )

  throws(assert, /unknown mode.+available.+normal/i, 'toString', ->
    vimfx.addCommand({name: 'test', description: 'Test', mode: 'toString'})
  )

  throws(assert, /unknown category.+available.+location/i, 'toString', ->
    vimfx.addCommand({name: 'test', description: 'Test', category: 'toString'})
  )

  throws(assert, /order.+number/i, 'false', ->
    vimfx.addCommand({name: 'test', description: 'Test', order: false})
  )

  throws(assert, /function/i, 'undefined', ->
    vimfx.addCommand({name: 'test', description: 'Test'})
  )

  throws(assert, /function/i, 'false', ->
    vimfx.addCommand({name: 'test_command', description: 'Test command'}, false)
  )
)

throws = (assert, regex, badValue, fn) ->
  assert.throws(fn)
  try fn() catch error
    assert.ok(error.message.startsWith('VimFx:'), 'start with VimFx')
    assert.ok(error.message.endsWith(": #{ badValue }"), 'show bad value')
    assert.ok(regex.test(error.message), 'regex match')
