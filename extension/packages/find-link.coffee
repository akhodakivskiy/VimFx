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

# Find a link that match with the patterns
findLinkMatchPattern = (document, patterns) ->
  links = getLinkElements(document)
  candidateLinks = []

  # filter visible links that contain patterns and put in candidateLinks
  for i in [0...links.snapshotLength] by 1
    link = links.snapshotItem(i)

    if isVisibleElement(link) and isElementMatchPattern(link, patterns)
      candidateLinks.push(link)

  return if candidateLinks.length == 0

  for link in candidateLinks
    link.wordCount = link.textContent.trim().split(/\s+/).length

  # favor shorter links, links near the end of a page
  candidateLinks = candidateLinks.sort (a, b) ->
    if a.wordCount == b.wordCount then 1 else a.wordCount - b.wordCount

  results = []

  # match patterns. Sort them to match shorter patterns first.
  # The latter is to prevent matching first links that contain 
  # longer words like `next`, `more`, etc.
  for pattern in patterns.sort((a, b) -> a.length > b.length)
    console.log(pattern)
    # if the pattern is a word, wrapped it in word boundaries.
    # thus we won't match words like 'previously' to 'previous'
    exactWordRegex =
      if /^\b|\b$/.test(pattern)
        new RegExp('\\b' + pattern + '\\b', 'i')
      else
        new RegExp(pattern, 'i')

    for candidateLink in candidateLinks
      if exactWordRegex.test(candidateLink.textContent)
        results.push(candidateLink)

  return results


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
