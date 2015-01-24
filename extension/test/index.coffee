###
# Copyright Simon Lydell 2014.
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

list = require('./tests-list')

Components.utils.import('resource://specialpowers/Assert.jsm')
assert = new Assert()

module.exports = ->
  report = []
  passed = 0
  total  = 0

  for name in list
    tests = require("./#{ name }")
    report.push(name)
    for key, fn of tests when key.startsWith('test')
      total++
      try
        fn(assert)
        passed++
      catch error
      report.push("  #{ if error then '\u2718' else '\u2714' } #{ key }")
      report.push(error.toString().replace(/^/gm, '  ')) if error

  report.push("#{ passed }/#{ total } tests passed.")
  console.log("\n#{ report.join('\n') }")
