assert = require('./assert')
legacy = require('../lib/legacy')

exports['test convertKey'] = ->
  assert.arrayEqual(legacy.convertKey('a'), ['a'])
  assert.arrayEqual(legacy.convertKey('Esc'), ['<escape>'])
  assert.arrayEqual(legacy.convertKey('a,Esc'), ['a', '<escape>'])
  assert.arrayEqual(legacy.convertKey(','), [','])
  assert.arrayEqual(legacy.convertKey(',,a'), [',', 'a'])
  assert.arrayEqual(legacy.convertKey('a,,'), ['a', ','])
  assert.arrayEqual(legacy.convertKey('a,,,b'), ['a', ',', 'b'])
  assert.arrayEqual(legacy.convertKey(',,,,a'), [',', ',', 'a'])
  assert.arrayEqual(legacy.convertKey('a,,,,'), ['a', ',', ','])
  assert.arrayEqual(legacy.convertKey(' a '), ['a'])
  assert.arrayEqual(legacy.convertKey(''), [])
  assert.arrayEqual(legacy.convertKey('    '), [])

exports['test convertPattern'] = ->
  assert.equal(legacy.convertPattern('aB.   t*o!	*!'), 'aB\\.\\s+t.*o.\\s+.*.')
