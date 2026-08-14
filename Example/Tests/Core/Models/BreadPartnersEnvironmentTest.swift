//------------------------------------------------------------------------------
//  File:          BreadPartnersEnvironment.swift
//  Author(s):     Bread Financial
//  Date:          14 July 2026
//
//  Descriptions:  This file is part of the BreadPartnersSDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import Testing
@testable import BreadPartnersSDK

struct BreadPartnersEnvironmentTests {

    // MARK: - Raw Value Mapping

    @Test("BreadPartnersEnvironment.stage has raw value 'STAGE'")
    func testStageRawValue() {
        #expect(BreadPartnersEnvironment.stage.rawValue == "STAGE")
    }

    @Test("BreadPartnersEnvironment.prod has raw value 'PROD'")
    func testProdRawValue() {
        #expect(BreadPartnersEnvironment.prod.rawValue == "PROD")
    }

    @Test("BreadPartnersEnvironment.uat has raw value 'UAT'")
    func testUatRawValue() {
        #expect(BreadPartnersEnvironment.uat.rawValue == "UAT")
    }

    // MARK: - Initialisation from Raw Value

    @Test("Init from raw value 'STAGE' returns .stage")
    func testInitFromStage() {
        #expect(BreadPartnersEnvironment(rawValue: "STAGE") == .stage)
    }

    @Test("Init from raw value 'PROD' returns .prod")
    func testInitFromProd() {
        #expect(BreadPartnersEnvironment(rawValue: "PROD") == .prod)
    }

    @Test("Init from raw value 'UAT' returns .uat")
    func testInitFromUat() {
        #expect(BreadPartnersEnvironment(rawValue: "UAT") == .uat)
    }

    // MARK: - Invalid Raw Values

    @Test("Init from unknown raw value returns nil")
    func testInitFromUnknownRawValue() {
        #expect(BreadPartnersEnvironment(rawValue: "UNKNOWN") == nil)
    }

    @Test("Init from empty string returns nil")
    func testInitFromEmptyString() {
        #expect(BreadPartnersEnvironment(rawValue: "") == nil)
    }

    @Test("Init from lowercase raw value returns nil (case-sensitive)")
    func testInitFromLowercaseRawValue() {
        #expect(BreadPartnersEnvironment(rawValue: "stage") == nil)
        #expect(BreadPartnersEnvironment(rawValue: "prod") == nil)
        #expect(BreadPartnersEnvironment(rawValue: "uat") == nil)
    }

    // MARK: - Equality

    @Test("Two identical cases are equal")
    func testCaseEquality() {
        #expect(BreadPartnersEnvironment.stage == BreadPartnersEnvironment.stage)
        #expect(BreadPartnersEnvironment.prod == BreadPartnersEnvironment.prod)
        #expect(BreadPartnersEnvironment.uat == BreadPartnersEnvironment.uat)
    }

    @Test("Different cases are not equal")
    func testCaseInequality() {
        #expect(BreadPartnersEnvironment.stage != BreadPartnersEnvironment.prod)
        #expect(BreadPartnersEnvironment.prod != BreadPartnersEnvironment.uat)
        #expect(BreadPartnersEnvironment.stage != BreadPartnersEnvironment.uat)
    }

    // MARK: - CaseIterable

    @Test("allCases contains exactly three environments")
    func testAllCasesCount() {
        #expect(BreadPartnersEnvironment.allCases.count == 3)
    }

    @Test("allCases contains stage, prod, and uat")
    func testAllCasesContents() {
        #expect(BreadPartnersEnvironment.allCases.contains(.stage))
        #expect(BreadPartnersEnvironment.allCases.contains(.prod))
        #expect(BreadPartnersEnvironment.allCases.contains(.uat))
    }

    @Test("All cases have distinct raw values")
    func testAllCasesDistinctRawValues() {
        let rawValues = BreadPartnersEnvironment.allCases.map { $0.rawValue }
        let uniqueRawValues = Set(rawValues)
        #expect(uniqueRawValues.count == BreadPartnersEnvironment.allCases.count)
    }
}
