//------------------------------------------------------------------------------
//  File:          UnifiedPrequalTest.swift
//  Author(s):     Bread Financial
//  Date:          27 March 2025
//
//  Descriptions:  This file is part of the BreadPartnersSDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------

import Testing
@testable import BreadPartnersSDK

struct UnifiedPrequalPathResultTests {

    // MARK: - Initialisation

    @Test("Stores all properties as provided")
    func testStoresAllProperties() {
        let params: [String: Any?] = ["locationType": "checkout", "count": 3]
        let result = UnifiedPrequalPathResult(
            path: "/prequalify",
            queryString: "locationType=checkout&count=3",
            queryParams: params
        )

        #expect(result.path == "/prequalify")
        #expect(result.queryString == "locationType=checkout&count=3")
        #expect(result.queryParams.count == 2)
        #expect(result.queryParams["locationType"] as? String == "checkout")
        #expect(result.queryParams["count"] as? Int == 3)
    }

    @Test("Supports empty path and query string")
    func testSupportsEmptyValues() {
        let result = UnifiedPrequalPathResult(
            path: "",
            queryString: "",
            queryParams: [:]
        )

        #expect(result.path.isEmpty)
        #expect(result.queryString.isEmpty)
        #expect(result.queryParams.isEmpty)
    }

    @Test("Preserves nil values inside queryParams")
    func testPreservesNilQueryParamValues() {
        let params: [String: Any?] = ["optional": nil, "present": "value"]
        let result = UnifiedPrequalPathResult(
            path: "/path",
            queryString: "present=value",
            queryParams: params
        )

        // Key exists but its value is nil.
        #expect(result.queryParams.keys.contains("optional"))
        #expect(result.queryParams["optional"]! == nil)
        #expect(result.queryParams["present"] as? String == "value")
    }
}

struct UPQAddressRequestTests {

    // MARK: - Initialisation

    @Test("Stores all address fields when fully populated")
    func testStoresAllFields() {
        let address = UPQAddressRequest(
            address1: "123 Main St",
            address2: "Apt 4B",
            city: "Columbus",
            state: "OH",
            zip: "43004"
        )

        #expect(address.address1 == "123 Main St")
        #expect(address.address2 == "Apt 4B")
        #expect(address.city == "Columbus")
        #expect(address.state == "OH")
        #expect(address.zip == "43004")
    }

    @Test("Supports nil for every field")
    func testSupportsAllNilFields() {
        let address = UPQAddressRequest(
            address1: nil,
            address2: nil,
            city: nil,
            state: nil,
            zip: nil
        )

        #expect(address.address1 == nil)
        #expect(address.address2 == nil)
        #expect(address.city == nil)
        #expect(address.state == nil)
        #expect(address.zip == nil)
    }
}
