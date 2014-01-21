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

  for link, idx in candidateLinks
    link.firstMatch = -1
    link.wordCount = link.textContent.trim().split(/\s+/).length

  for pattern, idx in patterns
    # if the pattern is a word, wrapped it in word boundaries.
    # thus we won't match words like 'previously' to 'previous'
    exactWordRegex =
      if /^\b|\b$/.test(pattern)
        new RegExp("^#{pattern}\\b|\\b#{pattern}\\b$", 'i')
      else
        new RegExp(pattern, 'i')

    for link in candidateLinks
      if exactWordRegex.test(link.textContent)
        link.firstMatch = idx if link.firstMatch == -1

  # favor shorter links, then the pattern matched in order
  return candidateLinks.filter((a) -> a.firstMatch != -1).sort (a, b) ->
    if a.wordCount != b.wordCount
      a.wordCount - b.wordCount
    else
      a.firstMatch - b.firstMatch


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
