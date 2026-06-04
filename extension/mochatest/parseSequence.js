var expect = require("chai").expect

var parseSequence = require("../").parseSequence


suite("parseSequence", function() {

  test("is a function", function() {
    expect(parseSequence).to.be.a("function")
  })


  test("single characters", function() {
    expect(parseSequence("a")).to.eql(["a"])
    expect(parseSequence("<")).to.eql(["<"])
    expect(parseSequence(">")).to.eql([">"])
    expect(parseSequence("/")).to.eql(["/"])
    expect(parseSequence("1")).to.eql(["1"])
    expect(parseSequence(" ")).to.eql([" "])
    expect(parseSequence("\t")).to.eql(["\t"])
    expect(parseSequence("\n")).to.eql(["\n"])
  })


  test("sequence of characters", function() {
    expect(parseSequence("a<>/1 \t\n")).to.eql([
      "a", "<", ">", "/", "1", " ", "\t", "\n"
    ])
    expect(parseSequence(">>")).to.eql([">", ">"])
    expect(parseSequence("<2j")).to.eql(["<", "2", "j"])
  })


  test("single keys", function() {
    expect(parseSequence("<a>")).to.eql(["<a>"])
    expect(parseSequence("<A>")).to.eql(["<A>"])
    expect(parseSequence("</>")).to.eql(["</>"])
    expect(parseSequence("<1>")).to.eql(["<1>"])
    expect(parseSequence("<Escape>")).to.eql(["<Escape>"])
    expect(parseSequence("<escApe>")).to.eql(["<escApe>"])

    expect(parseSequence("<c-a>")).to.eql(["<c-a>"])
    expect(parseSequence("<c-A>")).to.eql(["<c-A>"])
    expect(parseSequence("<c-/>")).to.eql(["<c-/>"])
    expect(parseSequence("<c-1>")).to.eql(["<c-1>"])
    expect(parseSequence("<c-Escape>")).to.eql(["<c-Escape>"])
    expect(parseSequence("<c-a-m-Escape>")).to.eql(["<c-a-m-Escape>"])
    expect(parseSequence("<s-K1>")).to.eql(["<s-K1>"])
  })


  test("invalid single keys", function() {
    expect(parseSequence("<-a>")).to.eql(["<-a>"])
    expect(parseSequence("<x-esc>")).to.eql(["<x-esc>"])
    expect(parseSequence("<shift-esc>")).to.eql(["<shift-esc>"])
    expect(parseSequence("<s-++>")).to.eql(["<s-++>"])
  })


  test("mix", function() {
    expect(parseSequence("a<a><c-a><esc><c-esc>b<Del>")).to.eql([
      "a", "<a>", "<c-a>", "<esc>", "<c-esc>", "b", "<Del>"
    ])

    expect(parseSequence("<c-<>")).to.eql(["<", "c", "-", "<", ">"])
    expect(parseSequence("<c->>")).to.eql(["<c->", ">"])
    expect(parseSequence("<c- >")).to.eql(["<", "c", "-", " ", ">"])
  })


  test("empty string", function() {
    expect(parseSequence("")).to.eql([""])
  })

})
