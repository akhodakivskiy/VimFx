var expect    = require("chai").expect
var testError = require("./test-error.js")

var stringify = require("../").stringify


suite("stringify", function() {

  test("is a function", function() {
    expect(stringify).to.be.a("function")
  })


  suite("simple", function() {

    test("letter", function() {
      var keyString

      keyString = stringify({
        key: "a"
      })
      expect(keyString).to.equal("a")

      keyString = stringify({
        key: "a",
        shiftKey: true
      })
      expect(keyString).to.equal("a")
    })


    test("capital letter", function() {
      var keyString

      keyString = stringify({
        key: "A"
      })
      expect(keyString).to.equal("A")

      keyString = stringify({
        key: "A",
        shiftKey: true
      })
      expect(keyString).to.equal("A")
    })


    test("symbol", function() {
      var keyString

      keyString = stringify({
        key: "/"
      })
      expect(keyString).to.equal("/")

      keyString = stringify({
        key: "/",
        shiftKey: true
      })
      expect(keyString).to.equal("/")
    })


    test("number", function() {
      var keyString

      keyString = stringify({
        key: "1"
      })
      expect(keyString).to.equal("1")

      keyString = stringify({
        key: "1",
        shiftKey: true
      })
      expect(keyString).to.equal("1")
    })


    test("special key", function() {
      var keyString

      keyString = stringify({
        key: "Enter"
      })
      expect(keyString).to.equal("<enter>")

      keyString = stringify({
        key: "Enter",
        shiftKey: true
      })
      expect(keyString).to.equal("<s-enter>")
    })


    test("aliases", function() {
      var keyString

      keyString = stringify({
        key: "left"
      })
      expect(keyString).to.equal("<arrowleft>")

      keyString = stringify({
        key: "cr",
        shiftKey: true
      })
      expect(keyString).to.equal("<s-enter>")

      keyString = stringify({
        key: "esc"
      })
      expect(keyString).to.equal("<escape>")
    })

  })


  test("fall back to event.code", function() {
    var keyString = stringify({
      key: "Unidentified",
      code: "Tab",
      shiftKey: true
    })
    expect(keyString).to.equal("<s-tab>")
  })


  suite("modifiers", function() {

    test("letter", function() {
      var keyString

      keyString = stringify({
        key: "a",
        ctrlKey: true
      })
      expect(keyString).to.equal("<c-a>")

      keyString = stringify({
        key: "a",
        shiftKey: true,
        ctrlKey: true
      })
      expect(keyString).to.equal("<c-a>")
    })


    test("capital letter", function() {
      var keyString

      keyString = stringify({
        key: "A",
        ctrlKey: true
      })
      expect(keyString).to.equal("<c-A>")

      keyString = stringify({
        key: "A",
        shiftKey: true,
        ctrlKey: true
      })
      expect(keyString).to.equal("<c-A>")
    })


    test("symbol", function() {
      var keyString

      keyString = stringify({
        key: "/",
        ctrlKey: true
      })
      expect(keyString).to.equal("<c-/>")

      keyString = stringify({
        key: "/",
        shiftKey: true,
        ctrlKey: true
      })
      expect(keyString).to.equal("<c-/>")

      keyString = stringify({
        key: "-",
        ctrlKey: true
      })
      expect(keyString).to.equal("<c-->")
    })


    test("number", function() {
      var keyString

      keyString = stringify({
        key: "1",
        ctrlKey: true
      })
      expect(keyString).to.equal("<c-1>")

      keyString = stringify({
        key: "1",
        shiftKey: true,
        ctrlKey: true
      })
      expect(keyString).to.equal("<c-1>")
    })


    test("special key", function() {
      var keyString

      keyString = stringify({
        key: "Enter",
        ctrlKey: true
      })
      expect(keyString).to.equal("<c-enter>")

      keyString = stringify({
        key: "Enter",
        shiftKey: true,
        ctrlKey: true
      })
      expect(keyString).to.equal("<c-s-enter>")
    })


    test("multiple modifiers in alphabetical order", function() {
      var keyString

      keyString = stringify({
        key: "a",
        shiftKey: true,
        ctrlKey: true,
        metaKey: true,
        altKey: true
      })
      expect(keyString).to.equal("<a-c-m-a>")

      keyString = stringify({
        key: "Enter",
        shiftKey: true,
        ctrlKey: true,
        metaKey: true,
        altKey: true
      })
      expect(keyString).to.equal("<a-c-m-s-enter>")
    })

  })


  suite("special cases", function() {

    test("space", function() {
      var keyString

      keyString = stringify({
        key: " "
      })
      expect(keyString).to.equal("<space>")

      keyString = stringify({
        key: " ",
        shiftKey: true
      })
      expect(keyString).to.equal("<s-space>")

      keyString = stringify({
        key: " ",
        shiftKey: true,
        ctrlKey: true
      })
      expect(keyString).to.equal("<c-s-space>")
    })


    test("< and >", function() {
      var keyString

      keyString = stringify({
        key: "<"
      })
      expect(keyString).to.equal("<lt>")
      keyString = stringify({
        key: ">"
      })
      expect(keyString).to.equal("<gt>")

      keyString = stringify({
        key: "<",
        shiftKey: true
      })
      expect(keyString).to.equal("<lt>")
      keyString = stringify({
        key: ">",
        shiftKey: true
      })
      expect(keyString).to.equal("<gt>")

      keyString = stringify({
        key: "<",
        shiftKey: true,
        ctrlKey: true
      })
      expect(keyString).to.equal("<c-lt>")
      keyString = stringify({
        key: ">",
        shiftKey: true,
        ctrlKey: true
      })
      expect(keyString).to.equal("<c-gt>")
    })


    test("Array#join safety", function() {
      var array = []
      array.push(stringify({key: "<"}))
      array.push(stringify({key: "a"}))
      array.push(stringify({key: ">"}))

      var string = array.join("")
      expect(string).not.to.equal("<a>")
      expect(string).to.equal("<lt>a<gt>")
    })

  })


  suite("ignoreCtrlAlt", function() {

    test("simple", function() {
      var keyString

      keyString = stringify({
        key: "$",
        ctrlKey: true,
        altKey: true
      }, {ignoreCtrlAlt: false})
      expect(keyString).to.equal("<a-c-$>")

      keyString = stringify({
        key: "$",
        ctrlKey: true,
        altKey: true
      }, {ignoreCtrlAlt: true})
      expect(keyString).to.equal("$")
    })


    test("shift", function() {
      var keyString

      keyString = stringify({
        key: "$",
        ctrlKey: true,
        altKey: true,
        shiftKey: true
      }, {ignoreCtrlAlt: true})
      expect(keyString).to.equal("$")

      keyString = stringify({
        key: "A",
        ctrlKey: true,
        altKey: true,
        shiftKey: true
      }, {ignoreCtrlAlt: true})
      expect(keyString).to.equal("A")
    })


    test("< and >", function() {
      var keyString

      keyString = stringify({
        key: "<",
        ctrlKey: true,
        altKey: true
      }, {ignoreCtrlAlt: true})
      expect(keyString).to.equal("<lt>")

      keyString = stringify({
        key: ">",
        ctrlKey: true,
        altKey: true
      }, {ignoreCtrlAlt: true})
      expect(keyString).to.equal("<gt>")
    })


    test("special key", function() {
      var keyString

      keyString = stringify({
        key: "Enter",
        ctrlKey: true,
        altKey: true
      }, {ignoreCtrlAlt: true})
      expect(keyString).to.equal("<a-c-enter>")

      keyString = stringify({
        key: "Enter",
        ctrlKey: true,
        altKey: true,
        shiftKey: true
      }, {ignoreCtrlAlt: true})
      expect(keyString).to.equal("<a-c-s-enter>")
    })


    test("missing or extra modifiers", function() {
      var keyString

      keyString = stringify({
        key: "a",
        ctrlKey: true
      }, {ignoreCtrlAlt: true})
      expect(keyString).to.equal("<c-a>")

      keyString = stringify({
        key: "a",
        altKey: true
      }, {ignoreCtrlAlt: true})
      expect(keyString).to.equal("<a-a>")

      keyString = stringify({
        key: "a",
        ctrlKey: true,
        altKey: true,
        metaKey: true
      }, {ignoreCtrlAlt: true})
      expect(keyString).to.equal("<a-c-m-a>")
    })

  })


  suite("ignoreKeyboardLayout", function() {

    test("letter", function() {
      var keyString

      keyString = stringify({
        code: "KeyA"
      }, {ignoreKeyboardLayout: true})
      expect(keyString).to.equal("a")

      keyString = stringify({
        code: "KeyA",
        key: "a"
      }, {ignoreKeyboardLayout: true})
      expect(keyString).to.equal("a")

      keyString = stringify({
        code: "KeyA",
        key: "b"
      }, {ignoreKeyboardLayout: true})
      expect(keyString).to.equal("a")
    })


    test("symbol", function() {
      var keyString

      keyString = stringify({
        code: "Slash"
      }, {ignoreKeyboardLayout: true})
      expect(keyString).to.equal("/")

      keyString = stringify({
        code: "Slash",
        shiftKey: true
      }, {ignoreKeyboardLayout: true})
      expect(keyString).to.equal("?")

      keyString = stringify({
        code: "Digit5"
      }, {ignoreKeyboardLayout: true})
      expect(keyString).to.equal("5")

      keyString = stringify({
        code: "Digit5",
        shiftKey: true
      }, {ignoreKeyboardLayout: true})
      expect(keyString).to.equal("%")
    })


    test("< and >", function() {
      var keyString

      keyString = stringify({
        code: "Comma",
        shiftKey: true
      }, {ignoreKeyboardLayout: true})
      expect(keyString).to.equal("<lt>")

      keyString = stringify({
        code: "Period",
        shiftKey: true
      }, {ignoreKeyboardLayout: true})
      expect(keyString).to.equal("<gt>")
    })


    test("modifiers", function() {
      var keyString

      keyString = stringify({
        code: "KeyA",
        shiftKey: true,
        altKey: true
      }, {ignoreKeyboardLayout: true})
      expect(keyString).to.equal("<a-A>")

      keyString = stringify({
        code: "Space",
        shiftKey: true,
        altKey: true
      }, {ignoreKeyboardLayout: true})
      expect(keyString).to.equal("<a-s-space>")
    })


    suite("numpad exception", function() {

      test("numlock on (numbers)", function() {
        var keyString

        keyString = stringify({
          code: "Numpad1",
          key: "1"
        }, {ignoreKeyboardLayout: true})
        expect(keyString).to.equal("1")

        keyString = stringify({
          code: "Numpad1",
          key: "End"
          // shift+numpadNumber when numlock is on results in the key that would
          // be produced when numlock is off, but without shift itself. So shift
          // is actually pressed, but `.shiftKey` is false.
        }, {ignoreKeyboardLayout: true})
        expect(keyString).to.equal("<end>")

        keyString = stringify({
          code: "Numpad1",
          key: "1",
          ctrlKey: true
        }, {ignoreKeyboardLayout: true})
        expect(keyString).to.equal("<c-1>")

        keyString = stringify({
          code: "Numpad1",
          key: "End",
          ctrlKey: true
        }, {ignoreKeyboardLayout: true})
        expect(keyString).to.equal("<c-end>")

        keyString = stringify({
          code: "NumpadEnter",
          key: "Enter"
        }, {ignoreKeyboardLayout: true})
        expect(keyString).to.equal("<enter>")

        keyString = stringify({
          code: "NumpadEnter",
          key: "Enter",
          shiftKey: true
        }, {ignoreKeyboardLayout: true})
        expect(keyString).to.equal("<s-enter>")
      })


      test("numlock off (arrows, home, end, etc.)", function() {
        var keyString

        keyString = stringify({
          code: "Numpad1",
          key: "End"
        }, {ignoreKeyboardLayout: true})
        expect(keyString).to.equal("<end>")

        keyString = stringify({
          code: "Numpad1",
          key: "End",
          shiftKey: true
        }, {ignoreKeyboardLayout: true})
        expect(keyString).to.equal("<s-end>")

        keyString = stringify({
          code: "Numpad1",
          key: "End",
          ctrlKey: true
        }, {ignoreKeyboardLayout: true})
        expect(keyString).to.equal("<c-end>")

        keyString = stringify({
          code: "Numpad1",
          key: "End",
          shiftKey: true,
          ctrlKey: true
        }, {ignoreKeyboardLayout: true})
        expect(keyString).to.equal("<c-s-end>")

        keyString = stringify({
          code: "NumpadEnter",
          key: "Enter"
        }, {ignoreKeyboardLayout: true})
        expect(keyString).to.equal("<enter>")

        keyString = stringify({
          code: "NumpadEnter",
          key: "Enter",
          shiftKey: true
        }, {ignoreKeyboardLayout: true})
        expect(keyString).to.equal("<s-enter>")
      })

    })

  })


  suite("translations", function() {

    test("azerty", function() {
      var keyString

      keyString = stringify({
        code: "KeyQ"
      }, {ignoreKeyboardLayout: true, translations: {
        "KeyQ": ["a", "A"]
      }})
      expect(keyString).to.equal("a")

      keyString = stringify({
        code: "KeyQ",
        shiftKey: true
      }, {ignoreKeyboardLayout: true, translations: {
        "KeyQ": ["a", "A"]
      }})
      expect(keyString).to.equal("A")

      keyString = stringify({
        code: "KeyQ",
        ctrlKey: true
      }, {ignoreKeyboardLayout: true, translations: {
        "KeyQ": ["a", "A"]
      }})
      expect(keyString).to.equal("<c-a>")

      keyString = stringify({
        code: "KeyQ",
        shiftKey: true,
        ctrlKey: true
      }, {ignoreKeyboardLayout: true, translations: {
        "KeyQ": ["a", "A"]
      }})
      expect(keyString).to.equal("<c-A>")
    })


    test("no shift difference", function() {
      var keyString

      keyString = stringify({
        code: "CapsLock"
      }, {ignoreKeyboardLayout: true, translations: {
        "CapsLock": "Escape"
      }})
      expect(keyString).to.equal("<escape>")

      keyString = stringify({
        code: "CapsLock",
        shiftKey: true
      }, {ignoreKeyboardLayout: true, translations: {
        "CapsLock": "Escape"
      }})
      expect(keyString).to.equal("<s-escape>")

      keyString = stringify({
        code: "KeyQ"
      }, {ignoreKeyboardLayout: true, translations: {
        "KeyQ": "a"
      }})
      expect(keyString).to.equal("a")

      keyString = stringify({
        code: "KeyQ",
        shiftKey: true
      }, {ignoreKeyboardLayout: true, translations: {
        "KeyQ": "a"
      }})
      expect(keyString).to.equal("a")
    })


    test("fall back to normal methods", function() {
      var keyString

      keyString = stringify({
        key: "b",
        code: "KeyB"
      }, {translations: {
        "KeyQ": "a"
      }})
      expect(keyString).to.equal("b")

      keyString = stringify({
        code: "KeyB"
      }, {ignoreKeyboardLayout: true, translations: {
        "KeyQ": "a"
      }})
      expect(keyString).to.equal("b")
    })


    test("numpad", function() {
      var keyString

      keyString = stringify({
        key: "1",
        code: "Numpad1"
      }, {translations: {
        "Numpad1": "K1"
      }})
      expect(keyString).to.equal("<k1>")

      keyString = stringify({
        key: "End",
        code: "Numpad1",
        shiftKey: true
      }, {translations: {
        "Numpad1": "K1"
      }})
      expect(keyString).to.equal("<s-k1>")
    })


    test("aliases", function() {
      var keyString

      keyString = stringify({
        code: "CapsLock"
      }, {translations: {
        "CapsLock": "BS"
      }})
      expect(keyString).to.equal("<backspace>")
    })


    test("modifiers", function() {
      var keyString

      keyString = stringify({
        code: "Digit7"
      }, {translations: {
        "Digit7": "Shift"
      }})
      expect(keyString).to.equal("")

      keyString = stringify({
        code: "ShiftLeft"
      }, {translations: {
        "ShiftLeft": "7"
      }})
      expect(keyString).to.equal("7")
    })


    test("invalid values", function() {

      var test = function(translation, badValue, shiftKey) {
        testError(
          stringify.bind(undefined, {
            code: "KeyA",
            shiftKey: shiftKey
          }, {translations: {
            "KeyA": translation
          }}), {
            id: "bad_translation",
            context: "KeyA",
            subject: badValue
          }
        )
      }

      test(null, null)

      test([false, true], false)
      test([false, true], true, true)

      test(["a"], undefined, true)
    })

  })


  suite("invalid keys", function() {

    test("unrecognized keys", function() {
      var keyString

      keyString = stringify({})
      expect(keyString).to.equal("")

      keyString = stringify({
        key: "Unidentified",
      })
      expect(keyString).to.equal("")

      keyString = stringify({
        key: "Dead",
      })
      expect(keyString).to.equal("")

      keyString = stringify({
        code: ""
      }, {ignoreKeyboardLayout: true})
      expect(keyString).to.equal("")
    })


    test("modifiers", function() {
      var keyString

      keyString = stringify({
        key: "Alt"
      })
      expect(keyString).to.equal("")

      keyString = stringify({
        key: "Control"
      })
      expect(keyString).to.equal("")

      keyString = stringify({
        key: "Hyper"
      })
      expect(keyString).to.equal("")

      keyString = stringify({
        key: "Meta"
      })
      expect(keyString).to.equal("")

      keyString = stringify({
        key: "Shift"
      })
      expect(keyString).to.equal("")

      keyString = stringify({
        key: "Super"
      })
      expect(keyString).to.equal("")

      keyString = stringify({
        key: "OS"
      })
      expect(keyString).to.equal("")

      keyString = stringify({
        code: "ControlRight"
      }, {ignoreKeyboardLayout: true})
      expect(keyString).to.equal("")

      keyString = stringify({
        code: "OSLeft"
      }, {ignoreKeyboardLayout: true})
      expect(keyString).to.equal("")
    })

  })

})
