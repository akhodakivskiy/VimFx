var expect    = require("chai").expect
var testError = require("./test-error")

var normalize = require("../").normalize


suite("normalize", function() {

  test("is a function", function() {
    expect(normalize).to.be.a("function")
  })


  test("single characters", function() {
    expect(normalize("a")).to.equal("a")
    expect(normalize("A")).to.equal("A")
    expect(normalize("/")).to.equal("/")
    expect(normalize("1")).to.equal("1")
  })


  test("keys", function() {
    expect(normalize("<a>")).to.equal("a")
    expect(normalize("<A>")).to.equal("A")
    expect(normalize("</>")).to.equal("/")
    expect(normalize("<1>")).to.equal("1")

    expect(normalize("<c-a>")).to.equal("<c-a>")
    expect(normalize("<c-A>")).to.equal("<c-A>")
    expect(normalize("<c-/>")).to.equal("<c-/>")
    expect(normalize("<c-1>")).to.equal("<c-1>")

    expect(normalize("<Escape>")).to.equal("<escape>")
    expect(normalize("<C-ESC>")).to.equal("<c-escape>")
    expect(normalize("<F12>")).to.equal("<f12>")
  })


  test("< and >", function() {
    expect(normalize("<")).to.equal("<lt>")
    expect(normalize(">")).to.equal("<gt>")
  })


  test("the empty string", function() {
    testError(normalize.bind(undefined, ""), {
      id:      "invalid_key",
      subject: ""
    })
  })


  test("errors", function() {
    testError(normalize.bind(undefined, "ab"), {
      id:      "invalid_key",
      subject: "ab"
    })

    testError(normalize.bind(undefined, "<S-gt>"), {
      id:      "disallowed_modifier",
      context: "<S-gt>",
      subject: "S"
    })
  })

})
