# `originalElements` should be an array of objects. Each object is expected to have a `weight`
# property which represents the _weight_ of the object, which is a positive number. Each object will
# be given a _code word_. The larger the weight, the shorter the code word. A weight of 0 means that
# the element should not get a code word at all. The code words will use the `alphabet` provided.
# The functions runs `callback(element, codeWord)` for each object in `originalElements` and returns
# `undefined`.
exports.addHuffmanCodeWordsTo = (originalElements, {alphabet}, callback) ->
  unless typeof(alphabet) == 'string'
    throw new TypeError('`alphabet` must be provided and be a string.')

  nonUnique = /([\s\S])[\s\S]*\1/.exec(alphabet)
  if nonUnique
    throw new Error("`alphabet` must consist of unique letters. Found '#{nonUnique[1]}' more than once.")

  if alphabet.length < 2
    throw new Error('`alphabet` must consist of at least 2 characters.')

  unless typeof(callback) == "function"
    throw new TypeError "`callback` must be provided and be a function."


  # Shallow working copy.
  elements = originalElements[..]


  # The algorithm is so optimized, that it does not produce a code word at all if there is only one
  # element! We still need a code word even if there is only one link, though.
  if elements.length == 1
    callback(elements[0], alphabet[0])
    return


  numBranches = alphabet.length
  numElements = elements.length

  # The Huffman algorithm needs to create a `numBranches`-ary tree (one branch for each character in
  # the `alphabet`). Such a tree can be formed by `1 + (numBranches - 1) * n` elements: There is the
  # root of the tree (`1`), and each branching adds `numBranches` elements to the total number or
  # elements, but replaces itself (`numBranches - 1`). `n` is the number of points where the tree
  # branches. In order to create the tree using `numElements` elements, we need to find an `n` such
  # that `1 + (numBranches - 1) * n >= numElements` (1), and then pad `numElements`, such that `1 +
  # (numBranches - 1) * n == numElements + padding` (2).
  #
  # Solving for `n = numBranchPoints` in (1) gives:
  numBranchPoints = Math.ceil((numElements - 1) / (numBranches - 1))
  # Solving for `padding` in (2) gives:
  padding = 1 + (numBranches - 1) * numBranchPoints - numElements

  # Sort the elements after their weights, in descending order, so that the last ones will be the
  # ones with lowest weight.
  elements.sort((a, b) -> b.weight - a.weight)

  # Pad with zero-weights to be able to form a `numBranches`-ary tree.
  for i in [0...padding] by 1
    elements.push({weight: 0})

  # Construct the Huffman tree.
  for i in [0...numBranchPoints] by 1
    # Replace `numBranches` of the lightest weights with their sum.
    sum = new BranchingPoint
    for i in [0...numBranches] by 1
      lowestWeight = elements.pop()
      sum.weight += lowestWeight.weight
      sum.children.unshift(lowestWeight)

    # Find the index to insert the sum so that the sorting is maintained. That is faster than
    # sorting the elements in each iteration.
    break for element, index in elements by -1 when sum.weight <= element.weight
    elements.splice(index + 1, 0, sum)

  root = elements[0] # `elements.length == 1` by now.

  # Create the code words by walking the tree. Store them using `callback`.
  do walk = (node = root, codeWord = '') ->
    if node instanceof BranchingPoint
      for childNode, index in node.children
        walk(childNode, codeWord + alphabet[index])
    else
      callback(node, codeWord)  unless node.weight == 0
    return


class BranchingPoint
  constructor: ->
    @weight = 0
    @children = []
