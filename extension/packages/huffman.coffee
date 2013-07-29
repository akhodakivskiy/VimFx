# `originalElements` should be an array of arrays. The first item of each sub-array should be a
# _weight_, which is a positive number. The sub-arrays may then contain whatever data that should be
# associated with the weight and the _code word_ which will be appended to each sub-array. The
# larger the weight, the shorter the code word. The code words will use the `{alphabet}` provided.
# Note that the function modifies the `originalElements` array and returns `null`.
exports.addHuffmanCodeWordsTo = (originalElements, {alphabet}) ->
  if typeof(alphabet) != 'string'
    throw new TypeError('`alphabet` must be a string.')

  nonUnique = /([\s\S])[\s\S]*\1/.exec(alphabet)
  if nonUnique
    throw new Error("`alphabet` must consist of unique letters. Found '#{nonUnique[1]}' more than once.")

  if alphabet.length < 2
    throw new Error('`alphabet` must consist of at least 2 characters.')

  # The algorithm is so optimized, that it does not even produce a code word at all if there is only
  # one element! We still need a code word even if there is only one link, though.
  if originalElements.length == 1
    originalElements[0].push(alphabet[0])
    return null

  elements = ({ index, weight } for [weight], index in originalElements)

  numBranches = alphabet.length
  numElements = elements.length
  # A `numBranches`-ary tree can be formed by `1 + (numBranches - 1) * n` elements (there needs to
  # be 1 element left, and each parent node replaces `numBranches` other nodes). `n` is the number
  # of points where the tree branches. If numElements does not exist in mentioned set, we have to
  # pad it to the nearest larger such number. Thus, we need to find an `n` such that `1 +
  # (numBranches - 1) * n >= numElements`. Solving for `n = numBranchPoints` gives:
  numBranchPoints = Math.ceil((numElements - 1) / (numBranches - 1))
  # It is required that `(numElements + padding) - (numBranches - 1) * numBranchPoints == 1` (see
  # above). Otherwise we cannot form a `numBranches`-ary tree. Solving for `padding` gives:
  padding = 1 + (numBranches - 1) * numBranchPoints - numElements

  # Pad with zero-weights to be able to form a `numBranches` tree.
  for i in [0...padding] by 1
    elements.push({weight: 0})

  # Construct the Huffman tree.
  for i in [0...numBranchPoints] by 1
    # Sort the weights in descending order, so that the last ones will be the ones with lowest
    # weight.
    elements.sort((a, b) -> b.weight - a.weight)

    # Replace `numBranches` weights with their sum.
    sum = {weight: 0, children: []}
    for i in [0...numBranches] by 1
      lowestWeight = elements.pop()
      sum.weight += lowestWeight.weight
      sum.children.unshift(lowestWeight)
    elements.push(sum)

  root = elements[0] # `elements.length == 1` by now.

  # Create the code words by walking the tree. Store them on `originalElements`.
  do walk = (node = root, codeWord = '') ->
    if node.children
      for childNode, index in node.children
        walk(childNode, codeWord + alphabet[index])
    else
      originalElements[node.index].push(codeWord)  unless node.weight == 0
    return null
