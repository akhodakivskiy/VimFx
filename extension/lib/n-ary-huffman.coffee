###
# Copyright 2014, 2015, 2016 Simon Lydell
# X11 (“MIT”) Licensed. (See LICENSE.)
###

createTree = (elements, numBranches, options = {}) ->
  {sorted = false, compare = (a, b) -> a.weight - b.weight} = options

  unless numBranches >= 2
    throw new RangeError("`n` must be at least 2")

  numElements = elements.length

  # Special cases.
  if numElements == 0
    return new BranchPoint([], 0)
  if numElements == 1
    [element] = elements
    return new BranchPoint([element], element.weight)

  unless sorted
    # Sort the elements after their weights, in descending order, so that the
    # first ones will be the ones with highest weight. This is done on a shallow
    # copy in order not to modify the original array.
    elements = elements[..].sort((a, b) -> compare(b, a))

  # A `numBranches`-ary tree can be formed by `1 + (numBranches - 1) * n`
  # elements: There is the root of the tree (`1`), and each branch point adds
  # `numBranches` elements to the total number or elements, but replaces itself
  # (`numBranches - 1`). `n` is the number of points where the tree branches
  # (therefore, `n` is an integer). In order to create the tree using
  # `numElements` elements, we need to find the smallest `n` such that `1 +
  # (numBranches - 1) * n == numElements + padding`. We need to add `padding`
  # since `n` is an integer and there might not be an integer `n` that makes
  # the left-hand side equal to `numElements`. Solving for `padding` gives
  # `padding = 1 + (numBranches - 1) * n - numElements`. Since `padding >= 0`
  # (we won’t reduce the number of elements, only add extra dummy ones), it
  # follows that `n >= (numElements - 1) / (numBranches - 1)`. The smallest
  # integer `n = numBranchPoints` is then:
  numBranchPoints = Math.ceil((numElements - 1) / (numBranches - 1))
  # The above gives the padding:
  numPadding = 1 + (numBranches - 1) * numBranchPoints - numElements

  # All the `numBranchPoints` branch points will be stored in this array instead
  # of splicing them into the `elements` array. This way we do not need to
  # search for the correct index to maintain the sort order. This array, and all
  # other below, are created with the correct length from the beginning for
  # performance.
  branchPoints = Array(numBranchPoints)

  # These indexes will be used instead of pushing, popping, shifting and
  # unshifting arrays for performance.
  latestBranchPointIndex = 0
  branchPointIndex       = 0
  elementIndex           = numElements - 1

  # The first branch point is the only one that can have fewer than
  # `numBranches` branches. One _could_ add `numPadding` dummy elements, but
  # this algorithm does not. (Why would that be useful?)
  if numPadding > 0
    numChildren = numBranches - numPadding
    weight = 0
    children = Array(numChildren)
    childIndex = 0
    while childIndex < numChildren
      element = elements[elementIndex]
      children[childIndex] = element
      weight += element.weight
      elementIndex--
      childIndex++
    branchPoints[0] = new BranchPoint(children, weight)
    latestBranchPointIndex = 1

  # Create (the rest of) the `numBranchPoints` branch points.
  nextElement = if elementIndex >= 0 then elements[elementIndex] else null
  while latestBranchPointIndex < numBranchPoints
    weight = 0
    children = Array(numBranches)
    childIndex = 0
    nextBranchPoint = branchPoints[branchPointIndex]
    # Put the next `numBranches` smallest weights in the `children` array.
    while childIndex < numBranches
      # The smallest weight is either the next element or the next branch point.
      if not nextElement? or # No elements, only branch points left.
         (nextBranchPoint? and compare(nextBranchPoint, nextElement) <= 0)
        lowestWeight = nextBranchPoint
        branchPointIndex++
        nextBranchPoint = branchPoints[branchPointIndex]
      else
        lowestWeight = nextElement
        elementIndex--
        nextElement = if elementIndex >= 0 then elements[elementIndex] else null
      children[childIndex] = lowestWeight
      weight += lowestWeight.weight
      childIndex++
    branchPoints[latestBranchPointIndex] = new BranchPoint(children, weight)
    latestBranchPointIndex++

  root = branchPoints[numBranchPoints - 1]
  root

class BranchPoint
  constructor: (@children, @weight) ->

  assignCodeWords: (alphabet, callback, prefix = "") ->
    index = 0
    for node in @children by -1
      codeWord = prefix + alphabet[index++]
      if node instanceof BranchPoint
        node.assignCodeWords(alphabet, callback, codeWord)
      else
        callback(node, codeWord)
    return

module.exports = {createTree, BranchPoint}
