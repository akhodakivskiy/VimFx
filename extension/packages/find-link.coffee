{ interfaces: Ci } = Components

HTMLDocument = Ci.nsIDOMHTMLDocument
XPathResult  = Ci.nsIDOMXPathResult

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

# Find a link with ref equals value
findLinkRef = (document, value) ->
  relTags = ["link", "a", "area"]
  for tag in relTags
    elements = document.getElementsByTagName(tag)
    for element in elements
      if (element.hasAttribute("rel") && element.rel == value)
        return element
  null


# Find a link with match the patterns
findLinkPattern = (document, patterns) ->
  links = getLinkElements(document)
  candidateLinks = []

  # at the end of this loop, candidateLinks will contain all visible links that match our patterns
  # links lower in the page are more likely to be the ones we want, so we loop through the snapshot backwards
  for i in [0...links.snapshotLength] by 1
    link = links.snapshotItem(i)

    if (isVisibleElement(link) &&
        isElementMatchPattern(link, patterns))
      candidateLinks.push(link)

  return if (candidateLinks.length == 0)

  for link in candidateLinks
    link.wordCount = link.textContent.trim().split(/\s+/).length

  # We can use this trick to ensure that Array.sort is stable. We need this property to retain the reverse
  # in-page order of the links.
  candidateLinks.forEach((a,i) -> a.originalIndex = i)

  # favor shorter links, and ignore those that are more than one word longer than the shortest link
  candidateLinks =
    candidateLinks.sort((a, b) ->
      if (a.wordCount == b.wordCount)
        a.originalIndex - b.originalIndex
      else
        a.wordCount - b.wordCount
    ).filter((a) -> a.wordCount <= candidateLinks[0].wordCount + 1)

  for pattern in patterns
    exactWordRegex =
      if /\b/.test(pattern[0]) or /\b/.test(pattern[pattern.length - 1])
        new RegExp "\\b" + pattern + "\\b", "i"
      else
        new RegExp pattern, "i"

    for candidateLink in candidateLinks
      if (exactWordRegex.test(candidateLink.textContent))
        return candidateLink
  null


# Find a followable link match ref or patterns
find = (document, ref, patterns) ->
  findLinkRef(document, ref) || findLinkPattern(document, patterns)


# Returns elements that qualify as links
# Generates and memoizes an XPath query internally
getLinkElements = do ->
  # Some preparations done on startup
  elements = [
    LINK_ELEMENTS...
    "*[#{ LINK_ELEMENT_PROPERTIES.join(' or ') }]"
  ]

  reduce = (m, rule) -> m.concat(["//#{ rule }", "//xhtml:#{ rule }"])
  xpath = elements.reduce(reduce, []).join(' | ')

  namespaceResolver = (namespace) ->
    if namespace == 'xhtml' then 'http://www.w3.org/1999/xhtml' else null

  # The actual function that will return the desired elements
  return (document, resultType = XPathResult.ORDERED_NODE_SNAPSHOT_TYPE) ->
    return document.evaluate(xpath, document.documentElement, namespaceResolver, resultType, null)


# Determine the link is visible
isVisibleElement = (element) ->
  document = element.ownerDocument
  window   = document.defaultView

  # element that isn't visible on the page
  computedStyle = window.getComputedStyle(element, null)
  if (computedStyle.getPropertyValue('visibility') != 'visible' ||
        computedStyle.getPropertyValue('display') == 'none' ||
        computedStyle.getPropertyValue('opacity') == '0')
    return false

  # element that has 0 dimension
  clientRect = element.getBoundingClientRect()
  if (clientRect.width == 0 || clientRect.height == 0)
    return false

  true


# Determine the link has a pattern matched
isElementMatchPattern = (element, patterns) ->
  for pattern in patterns
    if (element.textContent.toLowerCase().indexOf(pattern) != -1)
      return true
  false


exports.find = find
