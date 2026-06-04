###
# Copyright 2014, 2015, 2016 Simon Lydell
# X11 (“MIT”) Licensed. (See LICENSE.)
###

assert  = require("assert")
huffman = require("../index.coffee")

verifyCode = (item, code)->
  assert code == item.expected,
    """code: "#{code}", item: #{JSON.stringify(item)}"""

testCodes = (alphabet, elements)->
  tree = huffman.createTree(elements, alphabet.length)
  # Make sure that the `children` array always is a copy.
  assert.notEqual tree.children, elements
  tree.assignCodeWords alphabet, verifyCode

suite "codes", ->

  suite "binary", ->

    test "one element", ->
      testCodes "01", [
        {value: "a", weight: 4, expected: "0"}
      ]


    test "two elements", ->
      testCodes "01", [
        {value: "a", weight: 4, expected: "0"}
        {value: "b", weight: 3, expected: "1"}
      ]


    test "three elements", ->
      testCodes "01", [
        {value: "a", weight: 4, expected: "00"}
        {value: "b", weight: 3, expected: "01"}
        {value: "c", weight: 6, expected: "1"}
      ]

    test "four elements", ->
      testCodes "01", [
        {value: "a", weight: 4, expected: "000"}
        {value: "b", weight: 3, expected: "001"}
        {value: "c", weight: 6, expected: "01"}
        {value: "d", weight: 8, expected: "1"}
      ]


  test "ternary", ->
    testCodes "ABC", [
      {value: "a", weight: 4, expected: "BA"}
      {value: "b", weight: 3, expected: "BB"}
      {value: "c", weight: 6, expected: "C"}
      {value: "d", weight: 8, expected: "A"}
    ]


  test "longer alphabet than list", ->
    # Higher weight, earlier letter.
    testCodes "ABCDEF", [
      {value: "a", weight: 4, expected: "C"}
      {value: "b", weight: 3, expected: "D"}
      {value: "c", weight: 6, expected: "B"}
      {value: "d", weight: 8, expected: "A"}
    ]


  test "equal weights", ->
    testCodes "01", [
      {value: "a", weight: 1, expected: "10"}
      {value: "b", weight: 1, expected: "11"}
      {value: "c", weight: 1, expected: "000"}
      {value: "d", weight: 1, expected: "001"}
      {value: "e", weight: 1, expected: "010"}
      {value: "f", weight: 1, expected: "011"}
    ]


  test "preserve “original order”", ->
    testCodes "abcdefgh", [
      {value: "a", weight: 1, expected: "a"}
      {value: "b", weight: 1, expected: "b"}
      {value: "c", weight: 1, expected: "c"}
      {value: "d", weight: 1, expected: "d"}
      {value: "e", weight: 1, expected: "e"}
      {value: "f", weight: 1, expected: "f"}
    ]


  test "“unusual” weights", ->
    testCodes "01", [
      {value: "a", weight:    -4, expected: "111"}
      {value: "b", weight:     0, expected: "110"}
      {value: "c", weight:  18.3, expected: "0"}
      {value: "d", weight:     9, expected: "10"}
    ]


  test "QWERTY home row", ->
    testCodes "fjdksla;", [
      {value: "a", weight: 4,      expected: "kl"}
      {value: "b", weight: 1201,   expected: "f"}
      {value: "c", weight: 254.56, expected: "a"}
      {value: "d", weight: 202,    expected: ";"}
      {value: "e", weight: 578,    expected: "j"}
      {value: "f", weight: 104,    expected: "kj"}
      {value: "g", weight: 48.5,   expected: "kd"}
      {value: "h", weight: 198,    expected: "kf"}
      {value: "i", weight: 18,     expected: "ks"}
      {value: "j", weight: 286,    expected: "s"}
      {value: "k", weight: 463,    expected: "d"}
      {value: "l", weight: 32,     expected: "kk"}
      {value: "m", weight: 271,    expected: "l"}
    ]


  test "alphabet as array", ->
    testCodes ["0", "1"], [
      {value: "a", weight: 4, expected: "000"}
      {value: "b", weight: 3, expected: "001"}
      {value: "c", weight: 6, expected: "01"}
      {value: "d", weight: 8, expected: "1"}
    ]


  test "mixing trees", ->
    subTree = huffman.createTree([
      {value: "sub-a", weight: 4, expected: "ABA"}
      {value: "sub-b", weight: 3, expected: "ABB"}
      {value: "sub-c", weight: 6, expected: "AC"}
      {value: "sub-d", weight: 8, expected: "AA"}
    ], 3)
    tree = huffman.createTree([
      {value: "a", weight: 4, expected: "BB"}
      {value: "b", weight: 3, expected: "BC"}
      {value: "c", weight: 6, expected: "BA"}
      {value: "d", weight: 8, expected: "C"}
      subTree
    ], 3)
    tree.assignCodeWords "ABC", verifyCode


  test "custom prefix", ->
    tree = huffman.createTree([
      {value: "a", weight: 4, expected: "pBA"}
      {value: "b", weight: 3, expected: "pBB"}
      {value: "c", weight: 6, expected: "pC"}
      {value: "d", weight: 8, expected: "pA"}
    ], 3)
    tree.assignCodeWords "ABC", verifyCode, "p"


  test "already sorted", ->
    elements = [
      {value: "d", weight: 8, expected: "1"}
      {value: "c", weight: 6, expected: "01"}
      {value: "a", weight: 4, expected: "000"}
      {value: "b", weight: 3, expected: "001"}
    ]
    elements.slice = -> assert false, "expected the elements not to be copied"
    tree = huffman.createTree(elements, 2, {sorted: yes})
    tree.assignCodeWords "01", verifyCode


  test "custom comparison", ->
    minDiff = 2
    compare = (a, b) ->
      diff = a.weight - b.weight
      if a instanceof huffman.BranchPoint or b instanceof huffman.BranchPoint
        return diff
      else
        return switch
          when diff <= -minDiff
            -1
          when diff >= minDiff
            +1
          else
            0
    tree = huffman.createTree([
      {value: "a", weight: 3, expected: "BA"}
      {value: "b", weight: 4, expected: "BB"}
      {value: "c", weight: 6, expected: "C"}
      {value: "d", weight: 8, expected: "A"}
    ], 3, {compare})
    tree.assignCodeWords "ABC", verifyCode


suite "createTree", ->

  test "empty list", ->
    elements = []
    tree = huffman.createTree(elements, 2)
    assert.equal tree.weight, 0
    assert.equal tree.children.length, 0
    assert.notEqual tree.children, elements
    tree.assignCodeWords "01", ->
      assert false, "Expected callback not to run"


  test "prevent infinite recursion", ->
    assert.throws (-> huffman.createTree([], 0)), RangeError
    assert.throws (-> huffman.createTree([], 1)), RangeError


  test "returns BranchPoint", ->
    assert huffman.createTree([], 2) instanceof huffman.BranchPoint
    assert huffman.createTree([
      {weight: 1}
      {weight: 2}
    ], 2) instanceof huffman.BranchPoint


  test "preserve sort order", ->
    elements = [{weight: 3}, {weight: 1}, {weight: 2}]
    tree = huffman.createTree(elements, 3)
    assert.deepEqual tree.children, [{weight: 1}, {weight: 2}, {weight: 3}]
    assert.deepEqual elements,      [{weight: 3}, {weight: 1}, {weight: 2}]
