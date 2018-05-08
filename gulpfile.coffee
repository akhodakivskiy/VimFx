fs = require('fs')
path = require('path')
gulp = require('gulp')
coffee = require('gulp-coffee')
coffeelint = require('gulp-coffeelint')
git = require('gulp-git')
header = require('gulp-header')
mustache = require('gulp-mustache')
preprocess = require('gulp-preprocess')
sloc = require('gulp-sloc')
tap = require('gulp-tap')
zip = require('gulp-zip')
marked = require('marked')
merge = require('merge2')
precompute = require('require-precompute')
request = require('request')
rimraf = require('rimraf')
pkg = require('./package.json')

DEST = 'build'
XPI = 'VimFx.xpi'
LOCALE = 'extension/locale'
TEST = 'extension/test'

BASE_LOCALE = 'en-US'
UPDATE_ALL = /\s*UPDATE_ALL$/

ADDON_PATH = 'chrome://vimfx'
BUILD_TIME = Date.now()

argv = process.argv.slice(2)

{join} = path
read = (filepath) -> fs.readFileSync(filepath).toString()
template = (data) -> mustache(data, {extension: ''})

gulp.task('clean', (callback) ->
  rimraf(DEST, callback)
)

gulp.task('copy', ->
  gulp.src(['extension/**/!(*.coffee|*.tmpl)', 'LICENSE', 'LICENSE-MIT'])
    .pipe(gulp.dest(DEST))
)

gulp.task('node_modules', ->
  dependencies = (name for name of pkg.dependencies)
  # Note: When installing or updating node modules, make sure that the following
  # glob does not include too much or too little!
  gulp.src(
    "node_modules/+(#{dependencies.join('|')})/\
     {LICENSE*,{,**/!(test|examples)/}!(*min|*test*|*bench*).js}"
  )
    .pipe(gulp.dest("#{DEST}/node_modules"))
)

gulp.task('coffee', ->
  test = '--test' in argv or '-t' in argv
  gulp.src(
    [
      'extension/bootstrap.coffee'
      'extension/lib/**/*.coffee'
    ].concat(if test then 'extension/test/**/*.coffee' else []),
    {base: 'extension'}
  )
    .pipe(preprocess({context: {
      BUILD_TIME
      ADDON_PATH: JSON.stringify(ADDON_PATH)
      REQUIRE_DATA: JSON.stringify(precompute('.'), null, 2)
      TESTS:
        if test
          JSON.stringify(fs.readdirSync(TEST)
            .map((name) -> name.match(/^(test-.+)\.coffee$/)?[1])
            .filter(Boolean)
          )
        else
          null
    }}))
    .pipe(coffee({bare: true}))
    .pipe(gulp.dest(DEST))
)

gulp.task('bootstrap-frame.js', ->
  gulp.src('extension/bootstrap-frame.js.tmpl')
    .pipe(mustache({ADDON_PATH}))
    .pipe(tap((file) ->
      file.path = file.path.replace(/\.js\.tmpl$/, "-#{BUILD_TIME}.js")
    ))
    .pipe(gulp.dest(DEST))
)

gulp.task('chrome.manifest', ->
  gulp.src('extension/chrome.manifest.tmpl')
    .pipe(template({locales: fs.readdirSync(LOCALE).map((locale) -> {locale})}))
    .pipe(gulp.dest(DEST))
)

gulp.task('install.rdf', ->
  [[{name: creator}], developers, contributors, translators] =
    read('PEOPLE.md').trim().replace(/^#.+\n|^\s*-\s*/mg, '').split('\n\n')
    .map((block) -> block.split('\n').map((name) -> {name}))

  getDescription = (locale) -> read(join(LOCALE, locale, 'description')).trim()

  descriptions = fs.readdirSync(LOCALE)
    .filter((locale) -> locale != BASE_LOCALE)
    .map((locale) -> {locale, description: getDescription(locale)})

  gulp.src('extension/install.rdf.tmpl')
    .pipe(template({
      idSuffix: if '--unlisted' in argv or '-u' in argv then '-unlisted' else ''
      version: pkg.version
      minVersion: pkg.firefoxVersions.min
      maxVersion: pkg.firefoxVersions.max
      creator, developers, contributors, translators
      defaultDescription: getDescription(BASE_LOCALE)
      descriptions
    }))
    .pipe(gulp.dest(DEST))
)

gulp.task('templates', gulp.parallel(
  'bootstrap-frame.js'
  'chrome.manifest'
  'install.rdf'
))

gulp.task('build', gulp.series(
  'clean',
  gulp.parallel('copy', 'node_modules', 'coffee', 'templates')
))

gulp.task('xpi-only', ->
  gulp.src("#{DEST}/**/*")
    .pipe(zip(XPI, {compress: false}))
    .pipe(gulp.dest(DEST))
)

gulp.task('xpi', gulp.series('build', 'xpi-only'))

gulp.task('push-only', ->
  body = fs.readFileSync(join(DEST, XPI))
  request.post({url: 'http://localhost:8888', body})
)

gulp.task('push', gulp.series('xpi', 'push-only'))

gulp.task('default', gulp.series('push'))

# coffeelint-forbidden-keywords has `require('coffee-script/register');` in its
# index.js :(
gulp.task('lint-workaround', ->
  gulp.src('node_modules/coffeescript/')
    .pipe(gulp.symlink('node_modules/coffee-script'))
)

gulp.task('lint-only', ->
  gulp.src(['extension/**/*.coffee', 'gulpfile.coffee'])
    .pipe(coffeelint())
    .pipe(coffeelint.reporter())
)

gulp.task('lint', gulp.series('lint-workaround', 'lint-only'))

gulp.task('sloc', ->
  gulp.src([
    'extension/bootstrap.coffee'
    'extension/lib/!(migrations|legacy).coffee'
  ])
    .pipe(sloc())
)

gulp.task('release', (callback) ->
  {version} = pkg
  message = "VimFx v#{version}"
  today = new Date().toISOString()[...10]
  merge([
    gulp.src('package.json')
    gulp.src('CHANGELOG.md')
      .pipe(header("### #{version} (#{today})\n\n"))
      .pipe(gulp.dest('.'))
  ])
    .pipe(git.commit(message))
    .on('end', ->
      git.tag("v#{version}", message, callback)
    )
  return
)

gulp.task('changelog', (callback) ->
  num = 1
  for arg in argv when /^-[1-9]$/.test(arg)
    num = Number(arg[1])
  entries = read('CHANGELOG.md').split(/^### .+/m)[1..num].join('')
  process.stdout.write(html(entries))
  callback()
)

gulp.task('readme', (callback) ->
  process.stdout.write(html(read('README.md')))
  callback()
)

# Reduce markdown to the small subset of HTML that AMO allows. Note that AMO
# converts newlines to `<br>`.
html = (string) ->
  return marked(string)
    .replace(/// <h\d [^>]*> ([^<>]+) </h\d> ///g, '\n\n<b>$1</b>')
    .replace(///\s* <p> ((?: [^<] | <(?!/p>) )+) </p>///g, (match, text) ->
      return "\n#{text.replace(/\s*\n\s*/g, ' ')}\n\n"
    )
    .replace(///<li> ((?: [^<] | <(?!/li>) )+) </li>///g, (match, text) ->
      return "<li>#{text.replace(/\s*\n\s*/g, ' ')}</li>"
    )
    .replace(/<br>/g, '\n')
    .replace(///<(/?)kbd>///g, '<$1code>')
    .replace(/<img[^>]*>\s*/g, '')
    .replace(/\n\s*\n/g, '\n\n')
    .trim() + '\n'

gulp.task('faster', ->
  gulp.src('gulpfile.coffee')
    .pipe(coffee({bare: true}))
    .pipe(gulp.dest('.'))
)

gulp.task('sync-locales', (callback) ->
  baseLocale = BASE_LOCALE
  compareLocale = null
  for arg in argv when arg[...2] == '--'
    name = arg[2..]
    if name[-1..] == '?' then compareLocale = name[...-1] else baseLocale = name

  results = fs.readdirSync(join(LOCALE, baseLocale))
    .filter((file) -> path.extname(file) == '.properties')
    .map(syncLocale.bind(null, baseLocale))

  if baseLocale == BASE_LOCALE
    report = []
    for {fileName, untranslated, total} in results
      report.push("#{fileName}:")
      for localeName, strings of untranslated
        paddedName = "#{localeName}:   "[...6]
        percentage = Math.round((1 - strings.length / total) * 100)
        if localeName == compareLocale or compareLocale == null
          report.push("  #{paddedName} #{percentage}%")
        if localeName == compareLocale
          report.push(strings.map((string) -> "    #{string}")...)
    process.stdout.write(report.join('\n') + '\n')

  callback()
)

syncLocale = (baseLocaleName, fileName) ->
  basePath = join(LOCALE, baseLocaleName, fileName)
  base = parseLocaleFile(read(basePath))
  untranslated = {}
  for localeName in fs.readdirSync(LOCALE)
    localePath = join(LOCALE, localeName, fileName)
    locale = parseLocaleFile(read(localePath))
    untranslated[localeName] = []
    newLocale = base.template.map((line, index) ->
      if Array.isArray(line)
        [key] = line
        baseValue = base.keys[key]
        value =
          if UPDATE_ALL.test(baseValue) or key not of locale.keys
            baseValue.replace(UPDATE_ALL, '')
          else
            locale.keys[key]
        result = "#{key}=#{value}"
        if value == base.keys[key] and value != ''
          untranslated[localeName].push("#{index + 1}: #{result}")
        return result
      else
        return line
    )
    fs.writeFileSync(localePath, newLocale.join(base.newline))
  delete untranslated[baseLocaleName]
  return {fileName, untranslated, total: Object.keys(base.keys).length}

parseLocaleFile = (fileContents) ->
  keys = {}
  lines = []
  [newline] = fileContents.match(/\r?\n/)
  for line in fileContents.split(newline)
    line = line.trim()
    [match, key, value] = line.match(///^ ([^=]+) = (.*) $///) ? []
    if match
      keys[key] = value
      lines.push([key])
    else
      lines.push(line)
  return {keys, template: lines, newline}

generateHTMLTask = (filename, message) ->
  gulp.task(filename, (callback) ->
    unless fs.existsSync(filename)
      process.stdout.write(message(filename))
      callback()
      return
    gulp.src(filename)
      .pipe(tap((file) ->
        file.contents = new Buffer(generateTestHTML(file.contents.toString()))
      ))
      .pipe(gulp.dest('.'))
  )

generateHTMLTask('help.html', (filename) -> """
  First enable the “Copy to clipboard” line in help.coffee, show the help
  dialog and finally dump the clipboard into #{filename}.
""")

generateHTMLTask('hints.html', (filename) -> """
  First enable the “Copy to clipboard” line in modes.coffee, show the
  hint markers, activate the “Increase count” command and finally dump the
  clipboard into #{filename}.
""")

testHTMLPrelude = '''
  <!doctype html>
  <meta charset=utf-8>
  <title>VimFx test</title>
  <style>
    * {margin: 0;}
    body > :first-child {min-height: 100vh; width: 100vw;}
  </style>
  <link rel=stylesheet href=extension/skin/style.css>
'''

generateTestHTML = (dumpedHTML) ->
  return testHTMLPrelude + dumpedHTML
    .replace(/^<\w+ xmlns="[^"]+"/, '<div')
    .replace(/\w+>$/, 'div>')
    .replace(/<(\w+)([^>]*)\/>/g, '<$1$2></$1>')
