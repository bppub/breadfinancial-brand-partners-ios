// UtilitiesSpec.swift
// Tests for fromMoneyToDollars, stringifyJSON, unwrapForJSON,
// Dictionary.toQueryString, Dictionary.assignDefined,
// Optional<String>.takeIfNotEmpty, UIColor(hex:)

import Quick
import Nimble
import UIKit
@testable import BreadPartnersSDK

class UtilitiesSpec: QuickSpec {
    override func spec() {

        // MARK: - fromMoneyToDollars

        describe("fromMoneyToDollars") {
            it("converts zero cents to 0.0 dollars") {
                expect(fromMoneyToDollars(0)) == 0.0
            }

            it("converts 100 cents to 1.0 dollar") {
                expect(fromMoneyToDollars(100)) == 1.0
            }

            it("converts 999 cents to 9.99 dollars") {
                expect(fromMoneyToDollars(999)) == 9.99
            }

            it("converts 10000 cents to 100.0 dollars") {
                expect(fromMoneyToDollars(10000)) == 100.0
            }

            it("handles negative values") {
                expect(fromMoneyToDollars(-50)) == -0.5
            }

            it("returns nil for nil input") {
                expect(fromMoneyToDollars(nil)).to(beNil())
            }
        }

        // MARK: - unwrapForJSON

        describe("unwrapForJSON") {
            it("passes through a plain string unchanged") {
                let result = unwrapForJSON("hello") as? String
                expect(result) == "hello"
            }

            it("unwraps a flat dictionary with optional values") {
                let input: [String: Any?] = ["key": "value", "missing": nil]
                let result = unwrapForJSON(input) as? [String: Any]
                expect(result?["key"] as? String) == "value"
                expect(result?["missing"]).to(beNil())
            }

            it("formats Double values to 2 decimal places") {
                let input: [String: Any?] = ["price": 9.9]
                let result = unwrapForJSON(input) as? [String: Any]
                expect(result?["price"] as? Double) == 9.9
            }

            it("recursively unwraps nested arrays") {
                let input: [Any] = ["a", "b"]
                let result = unwrapForJSON(input) as? [Any]
                expect(result?.count) == 2
            }
        }

        // MARK: - stringifyJSON

        describe("stringifyJSON") {
            it("returns a valid JSON string for a simple dictionary") {
                let input: [String: Any] = ["name": "bread", "value": 42]
                let json = stringifyJSON(input)
                expect(json).toNot(beEmpty())
                expect(json).to(contain("bread"))
                expect(json).to(contain("42"))
            }

            it("returns a non-empty string for an array") {
                let input: [Any] = [1, 2, 3]
                let json = stringifyJSON(input)
                expect(json).toNot(beEmpty())
            }
        }

        // MARK: - Optional<String>.takeIfNotEmpty

        describe("Optional<String>.takeIfNotEmpty") {
            it("returns nil for nil optional") {
                let value: String? = nil
                expect(value.takeIfNotEmpty()).to(beNil())
            }

            it("returns nil for empty string") {
                let value: String? = ""
                expect(value.takeIfNotEmpty()).to(beNil())
            }

            it("returns nil for whitespace-only string") {
                let value: String? = "   "
                expect(value.takeIfNotEmpty()).to(beNil())
            }

            it("returns the string when non-empty") {
                let value: String? = "hello"
                expect(value.takeIfNotEmpty()) == "hello"
            }

            it("returns trimmed non-empty string") {
                let value: String? = "  world  "
                expect(value.takeIfNotEmpty()) == "  world  "
            }
        }

        // MARK: - Dictionary.assignDefined

        describe("Dictionary.assignDefined") {
            it("adds non-nil, non-empty values") {
                var dict: [String: Any?] = [:]
                dict.assignDefined(["a": "hello", "b": "world"])
                expect(dict["a"] as? String) == "hello"
                expect(dict["b"] as? String) == "world"
            }

            it("skips nil values") {
                var dict: [String: Any?] = [:]
                dict.assignDefined(["a": nil as String?])
                expect(dict["a"]).to(beNil())
            }

            it("skips empty string values") {
                var dict: [String: Any?] = [:]
                dict.assignDefined(["key": ""])
                expect(dict["key"]).to(beNil())
            }

            it("keeps non-string non-nil values (e.g., Bool)") {
                var dict: [String: Any?] = [:]
                dict.assignDefined(["flag": true])
                expect(dict["flag"] as? Bool) == true
            }

            it("merges multiple source dictionaries") {
                var dict: [String: Any?] = [:]
                dict.assignDefined(["a": "1"], ["b": "2"])
                expect(dict["a"] as? String) == "1"
                expect(dict["b"] as? String) == "2"
            }
        }

        // MARK: - Dictionary.toQueryString

        describe("Dictionary.toQueryString") {
            it("produces key=value pairs joined by &") {
                var dict: [String: Any?] = ["key": "value"]
                let qs = dict.toQueryString()
                expect(qs).to(contain("key=value"))
            }

            it("omits nil values") {
                var dict: [String: Any?] = ["a": "1", "b": nil]
                let qs = dict.toQueryString()
                expect(qs).to(contain("a=1"))
                expect(qs).toNot(contain("b="))
            }

            it("serialises Bool true as 'true'") {
                var dict: [String: Any?] = ["flag": true]
                let qs = dict.toQueryString()
                expect(qs).to(contain("flag=true"))
            }

            it("serialises Bool false as 'false'") {
                var dict: [String: Any?] = ["flag": false]
                let qs = dict.toQueryString()
                expect(qs).to(contain("flag=false"))
            }

            it("serialises Double with 2 decimal places") {
                var dict: [String: Any?] = ["price": 9.9 as Double]
                let qs = dict.toQueryString()
                expect(qs).to(contain("price=9.90"))
            }
        }

        // MARK: - UIColor(hex:)

        describe("UIColor(hex:)") {
            it("parses a standard 6-character hex (no #)") {
                let color = UIColor(hex: "FF0000") // pure red
                var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                color.getRed(&r, green: &g, blue: &b, alpha: &a)
                expect(r).to(beCloseTo(1.0, within: 0.01))
                expect(g).to(beCloseTo(0.0, within: 0.01))
                expect(b).to(beCloseTo(0.0, within: 0.01))
                expect(a).to(beCloseTo(1.0, within: 0.01))
            }

            it("parses a hex string prefixed with #") {
                let color = UIColor(hex: "#0000FF") // pure blue
                var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                color.getRed(&r, green: &g, blue: &b, alpha: &a)
                expect(r).to(beCloseTo(0.0, within: 0.01))
                expect(g).to(beCloseTo(0.0, within: 0.01))
                expect(b).to(beCloseTo(1.0, within: 0.01))
            }

            it("respects the alpha parameter") {
                let color = UIColor(hex: "FFFFFF", alpha: 0.5)
                var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                color.getRed(&r, green: &g, blue: &b, alpha: &a)
                expect(a).to(beCloseTo(0.5, within: 0.01))
            }

            it("parses white as (1,1,1)") {
                let color = UIColor(hex: "FFFFFF")
                var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                color.getRed(&r, green: &g, blue: &b, alpha: &a)
                expect(r).to(beCloseTo(1.0, within: 0.01))
                expect(g).to(beCloseTo(1.0, within: 0.01))
                expect(b).to(beCloseTo(1.0, within: 0.01))
            }
        }
    }
}
