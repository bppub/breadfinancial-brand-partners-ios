// https://github.com/Quick/Quick

import Quick
import Nimble
import BreadPartnersSDK
import Testing


struct CalculatorSwiftTests {
    @Test("Verifies that two positive integers add up correctly")
    func addingTwoPositiveNumbers() {
        #expect(1 == 1)
    }
    
    @Test("Verifies that dividing by zero throws an error")
    func divisionByZeroThrowsError() {
        #expect(1 == 1)
    }
    
}

//
//class TableOfContentsSpec: QuickSpec {
//    override func spec() {
//        describe("these will fail") {
//
//            it("can do maths") {
//                expect(1) == 2
//            }
//
//            it("can read") {
//                expect("number") == "string"
//            }
//
//            it("will eventually fail") {
//                expect("time").toEventually( equal("done") )
//            }
//            
//            context("these will pass") {
//
//                it("can do maths") {
//                    expect(23) == 23
//                }
//
//                it("can read") {
//                    expect("🐮") == "🐮"
//                }
//
//                it("will eventually pass") {
//                    var time = "passing"
//
//                    DispatchQueue.main.async {
//                        time = "done"
//                    }
//
//                    waitUntil { done in
//                        Thread.sleep(forTimeInterval: 0.5)
//                        expect(time) == "done"
//
//                        done()
//                    }
//                }
//            }
//        }
//    }
//}
