//------------------------------------------------------------------------------
//  File:          TestData.swift
//  Author(s):     Bread Financial
//  Date:          27 March 2025
//
//  Descriptions:  This file is part of the BreadPartnersSDK for iOS,
//  providing UI components and functionalities to integrate Bread Financial
//  services into partner applications.
//
//  © 2025 Bread Financial
//------------------------------------------------------------------------------

import UIKit
import BreadPartnersSDK

/// `TestData` class provides default configurations/styles/properties used across the BreadPartner SDK.
public class TestData: NSObject {

    public static let shared = TestData()

    private override init() {}

    public let placementConfigurations: [String: [String: Any]] = [:]
    
    public let styleStruct: [String: [String: Any]] = [
        "red": [
            "primaryColor": "#d50132",
            "lightColor": "#b8bdc0",
            "darkColor": "#000000",
            "boxColor": "#ececec",
            "fontFamily": "ArialMT",
            "smallTextSize": 12,
            "mediumTextSize": 15,
            "largeTextSize": 18,
            "xlargeTextSize": 20
        ],
        "green": [
            "primaryColor": "#28A745",
            "lightColor": "#68ba7b",
            "darkColor": "#19692C",
            "boxColor": "#E6F9EF",
            "fontFamily": "ArialMT",
            "smallTextSize": 14,
            "mediumTextSize": 16,
            "largeTextSize": 20,
            "xlargeTextSize": 22
        ],
        "blue": [
            "primaryColor": "#007BFF",
            "lightColor": "#6da3de",
            "darkColor": "#003F7F",
            "boxColor": "#EAF4FF",
            "fontFamily": "ArialMT",
            "smallTextSize": 16,
            "mediumTextSize": 18,
            "largeTextSize": 22,
            "xlargeTextSize": 24
        ]
    ]
}
