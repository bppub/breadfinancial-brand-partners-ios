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

    public let placementConfigurations: [String: [String: Any]] = []
}
