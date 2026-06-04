Overview [![Build Status](https://travis-ci.org/lydell/n-ary-huffman.svg?branch=master)](https://travis-ci.org/lydell/n-ary-huffman)
========

```js
var huffman = require("n-ary-huffman")

var names = ["Alfa", "Bravo", "Charlie", "Delta", "Echo", "Foxtrot", "Golf"]
var items = names.map(function(name, index) {
  return {
    name: name,
    weight: index,
    codeWord: null
  }
})

var alphabet = "0123"

var tree = huffman.createTree(items, alphabet.length)
tree.assignCodeWords(alphabet, function(item, codeWord) {
  item.codeWord = codeWord
})

console.log(items)
// [
//   { name: 'Alfa',    weight: 0, codeWord: '13' },
//   { name: 'Bravo',   weight: 1, codeWord: '12' },
//   { name: 'Charlie', weight: 2, codeWord: '11' },
//   { name: 'Delta',   weight: 3, codeWord: '10' },
//   { name: 'Echo',    weight: 4, codeWord: '3'  },
//   { name: 'Foxtrot', weight: 5, codeWord: '2'  },
//   { name: 'Golf',    weight: 6, codeWord: '0'  }
// ]
```

Installation
============

`npm install n-ary-huffman`

```js
var huffman = require('n-ary-huffman')
```


Usage
=====

`createTree(elements, n, [options])`
------------------------------------

`elements` is an array of objects. Each object is expected to have a `weight`
property which represents the _weight_ of the object, which is a number.

Returns a new `BranchPoint`—the root of an `n`-ary huffman tree, consisting of
all the items in `elements` as well as `BranchPoint`s. Each `BranchPoint` has
`n` children (except the deepest one which might have fewer, depending on
`elements.length`).

`options`:

- sorted: `Boolean`. Defaults to `false`. In order to create the tree,
  `elements` needs to be sorted after the weights in descending order. Enable
  this option if `elements` already is sorted this way, to skip sorting again.

- compare: `Function`. Defaults to `function(a, b) { return a.weight - b.weight }`.
  This function takes two tree elements, `a` and `b`, as parameters and returns
  a number, `c`, which tells how the weights of `a` and `b` compare:

  - `c < 0` → `a` is considered smaller than `b`.
  - `c === 0` → `a` is considered equal to `b`.
  - `c > 0` → `a` is considered larger than `b`.

  In other words, this function works just like the callback passed to
  `Array.prototype.sort`.

  This lets you define custom comparisons, for example if you want to consider
  weights that are close to each other to be equal.

`new BranchPoint(children, weight)`
-----------------------------------

Instance properties:

- children: `children`
- weight: `weight`

See `createTree(…)` above for more information.

`BranchPoint.prototype.assignCodeWords(alphabet, callback, prefix="")`
----------------------------------------------------------------------

Assign a _code word_ to each element in the tree. The larger the weight of an
element, the shorter the code word.

`alphabet` is a string or an array of characters to use for the code words. Make
sure that the alphabet is at least as long the arity of the tree. Note: Don’t
repeat characters, or you’ll get invalid code words.

`callback(element, codeWord)` is run for each object in the tree.

`prefix` (optional) will be added at the beginning of each code word.


License
=======

[The X11 “MIT” License](LICENSE).
