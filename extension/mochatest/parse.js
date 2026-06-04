var expect    = require("chai").expect
var testError = require("./test-error")

var parse = require("../").parse


suite("parse", function() {

  test("is a function", function() {
    expect(parse).to.be.a("function")
  })


  test("single characters", function() {
    expect(parse("a")).to.eql({key: "a"})
    expect(parse("A")).to.eql({key: "A"})
    expect(parse("/")).to.eql({key: "/"})
    expect(parse("<")).to.eql({key: "<"})
    expect(parse(">")).to.eql({key: ">"})
    expect(parse("1")).to.eql({key: "1"})
  })


  suite("keys", function() {

    test("dash", function () {
      expect(parse("<->")).to.eql({key: "-"})
      expect(parse("<a-->")).to.eql({key: "-", altKey: true})
    })


    test("< and >", function () {
      expect(parse("<gt>")).to.eql({key: ">"})
      expect(parse("<less>")).to.eql({key: "<"})
      expect(parse("<c-lesser>")).to.eql({key: "<", ctrlKey: true})
    })


    test("case preservation", function() {
      expect(parse("<escape>")).to.eql({key: "escape"})
      expect(parse("<Escape>")).to.eql({key: "Escape"})
      expect(parse("<escApe>")).to.eql({key: "escApe"})
      expect(parse("<f1>")).to.eql({key: "f1"})
      expect(parse("<F1>")).to.eql({key: "F1"})
      expect(parse("<A>")).to.eql({key: "A"})
    })


    test("modifiers", function() {
      expect(parse("<c-s-a-m-escape>")).to.eql({
        key:      "escape",
        altKey:   true,
        ctrlKey:  true,
        metaKey:  true,
        shiftKey: true
      })

      expect(parse("<c-1>")).to.eql({
        key:      "1",
        ctrlKey:  true
      })
    })


    test("aliases", function() {
      expect(parse("<left>")).to.eql({key: "ArrowLeft"})
      expect(parse("<c-cr>")).to.eql({key: "Enter", ctrlKey: true})
    })

  })


  test("the empty string", function() {
    testError(parse.bind(undefined, ""), {
      id:      "invalid_key",
      subject: ""
    })
  })


  suite("errors", function() {

    test("single characters", function() {
      testError(parse.bind(undefined, " "), {
        id:      "invalid_key",
        subject: " "
      })

      testError(parse.bind(undefined, "\t"), {
        id:      "invalid_key",
        subject: "\t"
      })

      testError(parse.bind(undefined, "\n"), {
        id:      "invalid_key",
        subject: "\n"
      })
    })


    test("keys", function() {
      testError(parse.bind(undefined, "<>"), {
        id:      "invalid_key",
        subject: "<>"
      })

      testError(parse.bind(undefined, "<ctrl-a>"), {
        id:      "invalid_key",
        subject: "<ctrl-a>"
      })

      testError(parse.bind(undefined, "ab"), {
        id:      "invalid_key",
        subject: "ab"
      })

      testError(parse.bind(undefined, "<a"), {
        id:      "invalid_key",
        subject: "<a"
      })

      testError(parse.bind(undefined, "<a >"), {
        id:      "invalid_key",
        subject: "<a >"
      })

      testError(parse.bind(undefined, "<a- >"), {
        id:      "invalid_key",
        subject: "<a- >"
      })

      testError(parse.bind(undefined, "<a-++>"), {
        id:      "invalid_key",
        subject: "<a-++>"
      })
    })


    test("unknown modifiers", function() {
      testError(parse.bind(undefined, "<x-a>"), {
        id:      "unknown_modifier",
        context: "<x-a>",
        subject: "x"
      })

      testError(parse.bind(undefined, "<X-a>"), {
        id:      "unknown_modifier",
        context: "<X-a>",
        subject: "X"
      })
    })


    test("duplicate modifiers", function() {
      testError(parse.bind(undefined, "<c-c-a>"), {
        id:      "duplicate_modifier",
        context: "<c-c-a>",
        subject: "c"
      })

      testError(parse.bind(undefined, "<c-C-a>"), {
        id:      "duplicate_modifier",
        context: "<c-C-a>",
        subject: "C"
      })

      testError(parse.bind(undefined, "<C-c-a>"), {
        id:      "duplicate_modifier",
        context: "<C-c-a>",
        subject: "c"
      })

      testError(parse.bind(undefined, "<a-s-C-m-s-esc>"), {
        id:      "duplicate_modifier",
        context: "<a-s-C-m-s-esc>",
        subject: "s"
      })

      testError(parse.bind(undefined, "<a-s-C-m-S-esc>"), {
        id:      "duplicate_modifier",
        context: "<a-s-C-m-S-esc>",
        subject: "S"
      })
    })


    test("disallowed modifiers", function() {
      testError(parse.bind(undefined, "<s-a>"), {
        id:      "disallowed_modifier",
        context: "<s-a>",
        subject: "s"
      })

      testError(parse.bind(undefined, "<c-S-/>"), {
        id:      "disallowed_modifier",
        context: "<c-S-/>",
        subject: "S"
      })

      testError(parse.bind(undefined, "<s-lt>"), {
        id:      "disallowed_modifier",
        context: "<s-lt>",
        subject: "s"
      })

      testError(parse.bind(undefined, "<S-greater>"), {
        id:      "disallowed_modifier",
        context: "<S-greater>",
        subject: "S"
      })
    })

  })

})
