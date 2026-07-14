//
//  OfferResponse.swift
//  BreadPartnersSDK_Tests
//
//  Created by Joncarlos Tavarez on 7/14/26.
//  Copyright © 2026 CocoaPods. All rights reserved.
//

import Testing
@testable import BreadPartnersSDK

struct OfferResponseTests {

    // MARK: - Raw Value Mapping

    @Test("OfferResponse.yes has raw value 'YES'")
    func testYesRawValue() {
        #expect(OfferResponse.yes.rawValue == "YES")
    }

    @Test("OfferResponse.no has raw value 'NO'")
    func testNoRawValue() {
        #expect(OfferResponse.no.rawValue == "NO")
    }

    @Test("OfferResponse.notMe has raw value 'NOT_ME'")
    func testNotMeRawValue() {
        #expect(OfferResponse.notMe.rawValue == "NOT_ME")
    }

    @Test("OfferResponse.abandoned has raw value 'ABANDONED'")
    func testAbandonedRawValue() {
        #expect(OfferResponse.abandoned.rawValue == "ABANDONED")
    }

    @Test("OfferResponse.prescreenNo has raw value 'PRESCREEN_NO'")
    func testPrescreenNoRawValue() {
        #expect(OfferResponse.prescreenNo.rawValue == "PRESCREEN_NO")
    }

    // MARK: - Initialisation from Raw Value

    @Test("Init from raw value 'YES' returns .yes")
    func testInitFromYes() {
        #expect(OfferResponse(rawValue: "YES") == .yes)
    }

    @Test("Init from raw value 'NO' returns .no")
    func testInitFromNo() {
        #expect(OfferResponse(rawValue: "NO") == .no)
    }

    @Test("Init from raw value 'NOT_ME' returns .notMe")
    func testInitFromNotMe() {
        #expect(OfferResponse(rawValue: "NOT_ME") == .notMe)
    }

    @Test("Init from raw value 'ABANDONED' returns .abandoned")
    func testInitFromAbandoned() {
        #expect(OfferResponse(rawValue: "ABANDONED") == .abandoned)
    }

    @Test("Init from raw value 'PRESCREEN_NO' returns .prescreenNo")
    func testInitFromPrescreenNo() {
        #expect(OfferResponse(rawValue: "PRESCREEN_NO") == .prescreenNo)
    }

    // MARK: - Invalid Raw Values

    @Test("Init from unknown raw value returns nil")
    func testInitFromUnknownRawValue() {
        #expect(OfferResponse(rawValue: "UNKNOWN") == nil)
    }

    @Test("Init from empty string returns nil")
    func testInitFromEmptyString() {
        #expect(OfferResponse(rawValue: "") == nil)
    }

    @Test("Init from lowercase raw value returns nil (case-sensitive)")
    func testInitFromLowercaseRawValue() {
        #expect(OfferResponse(rawValue: "yes") == nil)
        #expect(OfferResponse(rawValue: "no") == nil)
        #expect(OfferResponse(rawValue: "not_me") == nil)
        #expect(OfferResponse(rawValue: "abandoned") == nil)
        #expect(OfferResponse(rawValue: "prescreen_no") == nil)
    }

    // MARK: - Equality

    @Test("Two identical cases are equal")
    func testCaseEquality() {
        #expect(OfferResponse.yes == OfferResponse.yes)
        #expect(OfferResponse.no == OfferResponse.no)
        #expect(OfferResponse.notMe == OfferResponse.notMe)
        #expect(OfferResponse.abandoned == OfferResponse.abandoned)
        #expect(OfferResponse.prescreenNo == OfferResponse.prescreenNo)
    }

    @Test("Different cases are not equal")
    func testCaseInequality() {
        #expect(OfferResponse.yes != OfferResponse.no)
        #expect(OfferResponse.notMe != OfferResponse.abandoned)
        #expect(OfferResponse.prescreenNo != OfferResponse.yes)
    }

    // MARK: - All Cases Coverage

    @Test("All five cases exist and have distinct raw values")
    func testAllCasesDistinct() {
        let allCases: [OfferResponse] = [.yes, .no, .notMe, .abandoned, .prescreenNo]
        let rawValues = allCases.map { $0.rawValue }
        let uniqueRawValues = Set(rawValues)
        #expect(uniqueRawValues.count == allCases.count)
    }
}
