# `originalElements` should be an array of objects. Each object is expected to have a property (see
# the `options` argument) which represents the _weight_ of the object, which is a positive number.
# Each object will be given a _code word_ (see the `options` argument). The larger the weight, the
# shorter the code word. A weight of 0 means that the element should not get a code word at all. The
# code words will use the `options.alphabet` provided. Note that the function modifies the
# `originalElements` array (see the `options` argument) and returns `undefined`.
exports.addHuffmanCodeWordsTo = (originalElements, options = {}) ->
  weightProperty   = options.weightProperty   or 'weight'
  codeWordProperty = options.codeWordProperty or 'codeWord'
  setCodeWord      = options.setCodeWord      or (element, codeWord, index) ->
                                                   element[codeWordProperty] = codeWord
  { alphabet } = options

  if typeof(alphabet) != 'string'
    throw new TypeError('`options.alphabet` must be provided and be a string.')

  nonUnique = /([\s\S])[\s\S]*\1/.exec(alphabet)
  if nonUnique
    throw new Error("`options.alphabet` must consist of unique letters. Found '#{nonUnique[1]}' more than once.")

  if alphabet.length < 2
    throw new Error('`options.alphabet` must consist of at least 2 characters.')


  # The algorithm is so optimized, that it does not produce a code word at all if there is only one
  # element! We still need a code word even if there is only one link, though.
  if originalElements.length == 1
    setCodeWord(originalElements[0], alphabet[0], 0)
    return


  elements = ({weight: obj[weightProperty], index} for obj, index in originalElements)

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
    sum = {weight: 0, children: []}
    for i in [0...numBranches] by 1
      lowestWeight = elements.pop()
      sum.weight += lowestWeight.weight
      sum.children.unshift(lowestWeight)

    # Find the index to insert the sum so that the sorting is maintained. That is faster than
    # sorting the elements in each iteration.
    break for element, index in elements by -1 when sum.weight >= element.weight
    elements.splice(index + 1, 0, sum)

  root = elements[0] # `elements.length == 1` by now.

  # Create the code words by walking the tree. Store them using `setCodeWord`.
  do walk = (node = root, codeWord = '') ->
    if node.children
      for childNode, index in node.children
        walk(childNode, codeWord + alphabet[index])
    else
      setCodeWord(originalElements[node.index], codeWord, node.index)  unless node.weight == 0
    return
