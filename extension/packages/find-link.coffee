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

  # filter visible links that match patterns and put in candidateLinks
  for i in [0...links.snapshotLength] by 1
    link = links.snapshotItem(i)

    if isVisibleElement(link) and isElementMatchPattern(link, patterns)
      candidateLinks.push(link)

  return if candidateLinks.length == 0

  for link in candidateLinks
    link.wordCount = link.textContent.trim().split(/\s+/).length

  # favor shorter links, links near the end of a page
  # and ignore those that are more than one word longer than the shortest link
  candidateLinks =
    candidateLinks.sort((a, b) ->
      if a.wordCount == b.wordCount then 1 else a.wordCount - b.wordCount
    ).filter((a) -> a.wordCount <= candidateLinks[0].wordCount + 1)

  # match patterns
  for pattern in patterns
    exactWordRegex =
      if /\b/.test(pattern[0]) or /\b/.test(pattern[pattern.length - 1])
        new RegExp '\\b' + pattern + '\\b', 'i'
      else
        new RegExp pattern, 'i'

    for candidateLink in candidateLinks
      if exactWordRegex.test(candidateLink.textContent)
        return candidateLink

  return null

# Returns elements that qualify as links
getLinkElements = do ->
  elements = [
    LINK_ELEMENTS...
    "*[#{ LINK_ELEMENT_PROPERTIES.join(' or ') }]"
  ]

  utils.getDomElements(elements)


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
    if element.textContent.toLowerCase().indexOf(pattern) != -1
      return true

  return false

exports.find = findLinkMatchPattern
