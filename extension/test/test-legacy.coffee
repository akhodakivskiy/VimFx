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

legacy = require('../lib/legacy')

exports['test convertKey'] = (assert) ->
  assert.deepEqual(legacy.convertKey('a'), ['a'])
  assert.deepEqual(legacy.convertKey('Esc'), ['<escape>'])
  assert.deepEqual(legacy.convertKey('a,Esc'), ['a', '<escape>'])
  assert.deepEqual(legacy.convertKey(','), [','])
  assert.deepEqual(legacy.convertKey(',,a'), [',', 'a'])
  assert.deepEqual(legacy.convertKey('a,,'), ['a', ','])
  assert.deepEqual(legacy.convertKey('a,,,b'), ['a', ',', 'b'])
  assert.deepEqual(legacy.convertKey(',,,,a'), [',', ',', 'a'])
  assert.deepEqual(legacy.convertKey('a,,,,'), ['a', ',', ','])
