{ classes: Cc, interfaces: Ci } = Components

# Generates the underscore function
l10n = do ->
  splitter = /(\w+)-\w+/

  # Current locale
  locale = Cc["@mozilla.org/chrome/chrome-registry;1"]
    .getService(Ci.nsIXULChromeRegistry).getSelectedLocale("global")

  getStr = (aStrBundle, aKey) ->
    try return aStrBundle.GetStringFromName(aKey)

  return (filename, defaultLocale="en-US") ->

    filePath = (locale) ->
      getResourceURI("locale/#{ locale }/#{ filename }").spec

    # Folder in the format `en-US`
    defaultBundle = Services.strings.createBundle(filePath(locale))

    if locale_base = locale.match(splitter)
      # Folder in the basic format: `en`
      defaultBasicBundle = Services.strings.createBundle(filePath(locale_base[1]))

    # Folder named after `defaultLocale`
    addonsDefaultBundle = Services.strings.createBundle(filePath(defaultLocale))

    # The underscore function
    l10n_underscore = (aKey, aLocale) ->
      localeBundle = null
      localeBasicBundle = null

      # Yet another way to specify a folder
      if aLocale
        localeBundle = Services.strings.createBundle(filePath(aLocale))

        if locale_base = aLocale.match(splitter)
          localeBasicBundle = Services.strings.createBundle(filePath(locale_base[1]))

      aVal = getStr(localeBundle, aKey) \
          or getStr(localeBasicBundle, aKey) \
          or (defaultBundle && (getStr(defaultBundle, aKey) or (defaultBundle = null))) \
          or (defaultBasicBundle && (getStr(defaultBasicBundle, aKey) or (defaultBasicBundle = null))) \
          or getStr(addonsDefaultBundle, aKey)

      return aVal

    unload(Services.strings.flushBundles)

    return l10n_underscore

exports.l10n = l10n
