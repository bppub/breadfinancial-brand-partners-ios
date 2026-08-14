//------------------------------------------------------------------------------
//  File:          UnifiedPrequal.swift
//  Author(s):     Bread Financial
//  Date:          27 March 2025
//
//  Descriptions:  This file is part of the BreadPartnersSDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2026 Bread Financial
//------------------------------------------------------------------------------


/// Represents the result of unified prequalification path generation
struct UnifiedPrequalPathResult {
    let path: String
    let queryString: String
    let queryParams: [String: Any?]
}


struct UPQAddressRequest {
    let address1: String?
    let address2: String?
    let city: String?
    let state: String?
    let zip: String?
    
    public init(address1: String?,
                address2: String?,
                city: String?,
                state: String?,
                zip: String?) {
        self.address1 = address1
        self.address2 = address2
        self.city = city
        self.state = state
        self.zip = zip
    }
}
