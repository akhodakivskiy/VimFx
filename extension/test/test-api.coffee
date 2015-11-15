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

testUtils = require('./utils')
prefs     = require('../lib/prefs')
utils     = require('../lib/utils')

{utils: Cu} = Components

apiPref = 'extensions.VimFx.api_url'
apiUrl  = Services.prefs.getComplexValue(apiPref, Ci.nsISupportsString).data
# Hack: Also import `_callbacks` so callbacks added by tests can be `.pop()`ed.
{getAPI, _callbacks: callbacks} = Cu.import(apiUrl, {})

# In the tests, `vimfx` refers to the API object, while `$vimfx` refers to the
# passed in `VimFx` instance.

exports['test exports'] = (assert, $vimfx, teardown) -> getAPI((vimfx) ->
  teardown(-> callbacks.pop())

  assert.equal(typeof vimfx.get, 'function', 'get')
  assert.equal(typeof vimfx.getDefault, 'function', 'getDefault')
  assert.equal(typeof vimfx.set, 'function', 'set')
  assert.equal(typeof vimfx.addCommand, 'function', 'addCommand')
  assert.equal(typeof vimfx.addOptionOverrides, 'function',
               'addOptionOverrides')
  assert.equal(typeof vimfx.addKeyOverrides, 'function', 'addKeyOverrides')
  assert.equal(typeof vimfx.on, 'function', 'on')
  assert.equal(vimfx.modes, $vimfx.modes, 'modes')
)

exports['test get'] = (assert, $vimfx, teardown) -> getAPI((vimfx) ->
  reset = prefs.tmp('hint_chars', 'abcd')
  teardown(->
    reset?()
    callbacks.pop()
  )

  assert.equal(vimfx.get('hint_chars'), 'abcd')
)

exports['test getDefault'] = (assert, $vimfx, teardown) -> getAPI((vimfx) ->
  default_hint_chars = $vimfx.options.hint_chars
  reset = prefs.tmp('hint_chars', 'abcd')
  teardown(->
    reset?()
    callbacks.pop()
  )

  assert.equal(vimfx.getDefault('hint_chars'), default_hint_chars)
)

exports['test customization'] = (assert, $vimfx, teardown) -> getAPI((vimfx) ->
  originalOptions = Object.assign({}, $vimfx.options)
  originalCategories = Object.assign({}, $vimfx.options.categories)
  $vimfx.options.keyValidator = null
  $vimfx.options.ignore_keyboard_layout = true
  vimfx.set('translations', {KeyQ: ['ö', 'Ö']})
  teardown(->
    $vimfx.options = originalOptions
    $vimfx.options.categories = originalCategories
    delete $vimfx.modes.normal.commands.test_command
    delete $vimfx.modes.ignore.commands.test_command
    callbacks.pop()
  )

  nonce = {}
  event = {code: 'KeyQ'}

  # Add a simple test command.
  vimfx.addCommand({
    name:        'test_command'
    description: 'Test command'
  }, -> nonce)
  vimfx.set('custom.mode.normal.test_command', 'ö')

  # Add a slightly more complex command.
  vimfx.get('categories')['new_category'] = {
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

  $vimfx.createKeyTrees()

  # Test that the new simple command can be run.
  $vimfx.reset('normal')
  match = $vimfx.consumeKeyEvent(event, {mode: 'normal'}, null)
  assert.equal(match.type, 'full')
  assert.equal(match.command.run(), nonce)

  # Test that the new complex command can be run.
  $vimfx.reset('ignore')
  match = $vimfx.consumeKeyEvent(event, {mode: 'ignore'}, null)
  assert.equal(match.type, 'full')
  assert.equal(match.command.run(), nonce)

  modes = $vimfx.getGroupedCommands({enabledOnly: true})

  # Test that the new simple command can show up in the help dialog.
  mode_normal = modes.find((mode) -> mode._name == 'normal')
  category_misc = mode_normal.categories.find(
    (category) -> category._name == 'misc'
  )
  [..., {command: test_command}] = category_misc.commands
  assert.equal(test_command.description(), 'Test command')

  # Test that the new complex command can show up in the help dialog.
  mode_ignore = modes.find((mode) -> mode._name == 'ignore')
  [category_new] = mode_ignore.categories
  assert.equal(category_new.name, 'New category')
  [test_command] = category_new.commands
  assert.equal(test_command.command.description(), 'Test ignore mode command')
  assert.deepEqual(test_command.enabledSequences, ['ö'])

  # Remove the added commands.
  delete vimfx.modes.normal.commands.test_command
  delete vimfx.modes.ignore.commands.test_command
  $vimfx.createKeyTrees()

  # Test that the new simple command cannot be run.
  $vimfx.reset('normal')
  match = $vimfx.consumeKeyEvent(event, {mode: 'normal'}, null)
  if match.type == 'full'
    value = try match.command.run() catch then null
    assert.notEqual(value, nonce)

  # Test that the new complex command cannot be run.
  $vimfx.reset('ignore')
  match = $vimfx.consumeKeyEvent(event, {mode: 'ignore'}, null)
  if match.type == 'full'
    value = try match.command.run() catch then null
    assert.notEqual(value, nonce)

  modes = $vimfx.getGroupedCommands({enabledOnly: true})

  # Test that the new simple command cannot show up in the help dialog.
  mode_normal = modes.find((mode) -> mode._name == 'normal')
  category_misc = mode_normal.categories.find(
    (category) -> category._name == 'misc'
  )
  [..., {command: last_command}] = category_misc.commands
  assert.notEqual(last_command.description(), 'Test command')

  # Test that the new complex command cannot show up in the help dialog.
  mode_ignore = modes.find((mode) -> mode._name == 'ignore')
  [first_category] = mode_ignore.categories
  assert.notEqual(first_category.name, 'New category')
)

exports['test addCommand order'] = \
(assert, $vimfx, teardown) -> getAPI((vimfx) ->
  teardown(->
    delete vimfx.modes.normal.commands.test_command
    callbacks.pop()
  )

  vimfx.addCommand({
    name:        'test_command'
    description: 'Test command'
    order:       0
  }, Function.prototype)
  vimfx.set('custom.mode.normal.test_command', 'ö')

  modes = $vimfx.getGroupedCommands()
  mode_normal = modes.find((mode) -> mode._name == 'normal')
  category_misc = mode_normal.categories.find(
    (category) -> category._name == 'misc'
  )
  [{command: first_command}] = category_misc.commands
  assert.equal(first_command.description(), 'Test command')
)

exports['test addOptionOverrides'] = \
(assert, $vimfx, teardown) -> getAPI((vimfx) ->
  originalOptions = Object.assign({}, $vimfx.options)
  originalOptionOverrides = Object.assign({}, $vimfx.optionOverrides)
  $vimfx.optionOverrides = null
  $vimfx.options.prevent_autofocus = true
  teardown(->
    reset?() # Defined below.
    $vimfx.options = originalOptions
    $vimfx.optionOverrides = originalOptionOverrides
    callbacks.pop()
  )

  vimfx.addOptionOverrides(
    [
      (location) -> location.hostname == 'example.com'
      {prevent_autofocus: false}
    ]
  )

  assert.equal($vimfx.options.prevent_autofocus, true)

  reset = testUtils.stub(utils, 'getCurrentLocation', -> {
    hostname: 'example.com'
  })

  assert.equal($vimfx.options.prevent_autofocus, false)
)

exports['test addKeyOverrides'] = \
(assert, $vimfx, teardown) -> getAPI((vimfx) ->
  originalOptions = Object.assign({}, $vimfx.options)
  originalKeyOverrides = Object.assign({}, $vimfx.keyOverrides)
  $vimfx.options.keyValidator = null
  $vimfx.options.ignore_keyboard_layout = false
  $vimfx.options.translations = {}
  teardown(->
    resetScrollToBottom?() # Defined below.
    resetGetCurrentLocation?() # Defined below.
    $vimfx.options = originalOptions
    $vimfx.keyOverrides = originalKeyOverrides
    callbacks.pop()
  )

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

  resetScrollToBottom = prefs.tmp('mode.normal.scroll_to_bottom', '<foobar>j')
  $vimfx.createKeyTrees()
  $vimfx.reset('normal')

  match = $vimfx.consumeKeyEvent({key: 'j'}, {mode: 'ignore'}, null)
  assert.ok(match)

  resetGetCurrentLocation = testUtils.stub(utils, 'getCurrentLocation', -> {
    hostname: 'example.co'
    href: 'about:blank'
  })

  match = $vimfx.consumeKeyEvent({key: '1'}, {mode: 'normal'}, null)
  assert.equal(match.type, 'count')
  assert.equal(match.count, 1)

  match = $vimfx.consumeKeyEvent({key: 'j'}, {mode: 'normal'}, null)
  assert.ok(not match)

  match = $vimfx.consumeKeyEvent({key: 'foobar', ctrlKey: true},
                                 {mode: 'normal'}, null)
  assert.ok(not match)

  match = $vimfx.consumeKeyEvent({key: 'foobar'}, {mode: 'normal'}, null)
  assert.equal(match.type, 'partial')
  match = $vimfx.consumeKeyEvent({key: 'j'}, {mode: 'normal'}, null)
  assert.equal(match.type, 'full')
  assert.strictEqual(match.count, undefined)

  $vimfx.reset('ignore')

  match = $vimfx.consumeKeyEvent({key: 'j'}, {mode: 'ignore'}, null)
  assert.ok(match)

  match = $vimfx.consumeKeyEvent({key: 'escape'}, {mode: 'ignore'}, null)
  assert.ok(not match)
)

exports['test vimfx.[gs]et(Default)? errors'] = \
(assert, $vimfx, teardown) -> getAPI((vimfx) ->
  teardown(-> callbacks.pop())

  throws(assert, /unknown pref/i, 'undefined', ->
    vimfx.get()
  )

  throws(assert, /unknown pref/i, 'undefined', ->
    vimfx.getDefault()
  )

  throws(assert, /unknown pref/i, 'undefined', ->
    vimfx.set()
  )

  throws(assert, /unknown pref/i, 'unknown_pref', ->
    vimfx.get('unknown_pref')
  )

  throws(assert, /unknown pref/i, 'unknown_pref', ->
    vimfx.getDefault('unknown_pref')
  )

  throws(assert, /no default/i, 'custom.mode.normal.foo', ->
    vimfx.getDefault('custom.mode.normal.foo')
  )

  throws(assert, /no default/i, 'translations', ->
    vimfx.getDefault('translations')
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

exports['test vimfx.addCommand errors'] = \
(assert, $vimfx, teardown) -> getAPI((vimfx) ->
  teardown(-> callbacks.pop())

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
    assert.ok(error.message.endsWith(": #{badValue}"), 'show bad value')
    assert.ok(regex.test(error.message), 'regex match')
