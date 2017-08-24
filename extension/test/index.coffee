# This file implements a simple test runner.

list = do -> # @echo TESTS

module.exports = (topLevelObject) ->
  report = []
  passed = 0
  total = 0

  for name in list when name.endsWith('-frame') == IS_FRAME_SCRIPT
    tests = require("./#{name}")
    report.push(name)
    for key, fn of tests when key.startsWith('test')
      total += 1
      error = null
      teardowns = []
      teardown = (fn) -> teardowns.push(fn)
      try
        fn(topLevelObject, teardown)
        passed += 1
      catch error then null
      finally
        (try fn()) for fn in teardowns
      report.push("  #{if error then '✘' else '✔'} #{key}")
      report.push("#{error}\n#{error.stack}".replace(/^/gm, '    ')) if error

  type = if IS_FRAME_SCRIPT then 'frame' else 'regular'
  report.push("\n#{passed}/#{total} #{type} tests passed.\n")
  console.info("\n#{report.join('\n')}")
