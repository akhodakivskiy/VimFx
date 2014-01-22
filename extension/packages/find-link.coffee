utils = require 'utils'

# All the following elements qualify as a link
LINK_ELEMENTS = [
  "a"
  "area[@href]"
  "button"
]

# All elements that have one or more of the following properties
# qualify as a link
LINK_ELEMENT_PROPERTIES = [
  "@onclick"
  "@onmousedown"
  "@onmouseup"
  "@oncommand"
  "@role='link'"
  "@role='button'"
  "contains(@class, 'button')"
]

# Find an array of links that match with patterns
findLinkMatchPattern = (document, patterns) ->
  links = getLinkElements(document)
  candidateLinks = []

  # filter visible links that contain patterns and put in candidateLinks
  for i in [0...links.snapshotLength] by 1
    link = links.snapshotItem(i)

    if isVisibleElement(link) and isElementMatchPattern(link, patterns)
      link.firstMatch = -1
      link.wordCount = link.textContent.trim().split(/\s+/).length

      candidateLinks.push(link)

  return [] if candidateLinks.length == 0

  for pattern, idx in patterns
    # if the pattern is a word, it needs to be the first or last word in string,
    # and wrapped in word boundaries.
    exactWordRegex =
      if /^\b|\b$/.test(pattern)
        /// ^#{ pattern }\b | \b#{ pattern }$ ///i
      else
        /// #{ pattern } ///i

    for link in candidateLinks when exactWordRegex.test(link.textContent)
      link.firstMatch = idx if link.firstMatch == -1

  # favor shorter links, then the pattern matched in order
  return candidateLinks
    .filter((a) -> a.firstMatch != -1)
    .sort((a, b) -> a.wordCount - b.wordCount or a.firstMatch - b.firstMatch)


# Returns elements that qualify as links
getLinkElements = do ->
  elements = [
    LINK_ELEMENTS...
    "*[#{ LINK_ELEMENT_PROPERTIES.join(' or ') }]"
  ]

  return utils.getDomElements(elements)


# Determine if the link is visible
isVisibleElement = (element) ->
  document = element.ownerDocument
  window   = document.defaultView

  # element that isn't visible on the page
  computedStyle = window.getComputedStyle(element, null)
  if computedStyle.getPropertyValue('visibility') != 'visible' or
      computedStyle.getPropertyValue('display') == 'none' or
      computedStyle.getPropertyValue('opacity') == '0'
    return false

  # element that has zero dimension
  clientRect = element.getBoundingClientRect()
  if clientRect.width == 0 or clientRect.height == 0
    return false

  return true


# Determine if the link has a pattern matched
isElementMatchPattern = (element, patterns) ->
  for pattern in patterns
    if element.textContent.toLowerCase().contains(pattern)
      return true

  return false

exports.find = findLinkMatchPattern
