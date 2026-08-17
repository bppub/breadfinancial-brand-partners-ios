# Test Coverage Implementation Plan

## Baseline

Coverage was captured from the `BreadPartnersSDK_UnitTests` scheme on 17 August 2026.

- Tests: 163 passed, 0 failed, 0 skipped
- SDK line coverage: 35.73% (1,961 of 5,489 executable lines)
- Source files at 0% coverage: 11
- Result bundle: `/tmp/BreadPartnersSDK-UnitTests-Coverage.xcresult`

## Prioritization Method

The order below uses the number of distinct production Swift files that reference each file's primary type or methods. Test files, comments, and self-references are excluded. Ties are ordered by executable-line count and the importance of the runtime flow.

## Ranked Zero-Coverage Files

### 1. PopupController.swift

- Coverage: 0% (0/126 executable lines)
- Referenced by: `PopupUIExtension.swift`, `PopupAPIExtension.swift`, `PopupButtonActionExtension.swift`, `HTMLContentRenderer.swift`
- Test focus:
  - Initialisation and stored configuration
  - `viewDidLoad` and `viewDidLayoutSubviews` behavior
  - Embedded versus single-product overlay setup
  - Web view event forwarding and app-restart handling
  - Popup dismissal and action-button behavior
  - Invalid or missing web view placement data

### 2. BreadPartnersSDK.swift

- Coverage: 0% (0/100 executable lines)
- Referenced by: `PlacementApiExtension.swift`, `RTPSApiExtension.swift`
- Test focus:
  - Setup state, environment, integration key, and logging configuration
  - Pre-initialization error callbacks
  - Default popup styling application
  - Placement, silent RTPS, and open-experience entry points
  - Callback behavior for success and failure paths

### 3. ChallengeController.swift

- Coverage: 0% (0/144 executable lines)
- Referenced by: `PlacementApiExtension.swift`, `RTPSApiExtension.swift`
- Test focus:
  - Challenge HTML loading and web view creation
  - Cookie extraction and completion callback
  - Navigation failure and cancellation behavior
  - Retry callback integration from placement and RTPS flows

### 4. RTPSApiExtension.swift

- Coverage: 0% (0/340 executable lines)
- Referenced by: `BreadPartnersSDK.swift`
- Test focus:
  - Batch prescreen flow
  - Prescreen flow with required-field validation
  - Virtual lookup flow with an existing prescreen ID
  - reCAPTCHA success and failure handling
  - Response-code mapping, placement fetching, and error callbacks
  - Incapsula challenge handling

### 5. PlacementApiExtension.swift

- Coverage: 0% (0/185 executable lines)
- Referenced by: `BreadPartnersSDK.swift`
- Test focus:
  - Brand configuration fetch and decode failures
  - Placement request construction and response handling
  - Text-placement versus open-placement behavior
  - Popup parsing failures
  - Incapsula challenge and generic API error callbacks

### 6. PopupUIExtension.swift

- Coverage: 0% (0/635 executable lines)
- Referenced by: `PopupController.swift`
- Test focus:
  - Popup view hierarchy creation
  - Embedded and single-product overlay branches
  - Missing or invalid web view URLs
  - Loader lifecycle
  - Constraint setup and dynamic body sections
  - Header visibility and logo loading behavior

### 7. PopupElements.swift

- Coverage: 0% (0/249 executable lines)
- Referenced by: `PopupUIExtension.swift`
- Test focus:
  - Close buttons, dividers, containers, labels, stack views, and action buttons
  - Attributed font and paragraph-style preservation
  - Superscript styling
  - Disclosure links and SwiftSoup anchor extraction
  - Known and unknown dynamic-body tags

### 8. PopupAPIExtension.swift

- Coverage: 0% (0/74 executable lines)
- Referenced by: `PopupController.swift`
- Test focus:
  - Web view placement request construction
  - Successful response decoding and model assignment
  - Network, decoding, and missing-content errors

### 9. PopupButtonActionExtension.swift

- Coverage: 0% (0/26 executable lines)
- Referenced by: `PopupController.swift` and popup UI selectors
- Test focus:
  - Dismiss callback and dismissal behavior
  - Action-button callback with and without a web view placement
  - Disclosure link handling for anchor and external URLs

### 10. AnalyticsManager.swift

- Coverage: 0% (0/98 executable lines)
- Referenced by: `HTMLContentRenderer.swift`
- Test focus:
  - API key configuration
  - View and click event payload construction
  - Placement metadata and timestamp mapping
  - Analytics request success and failure behavior

### 11. RecaptchaManager.swift

- Coverage: 0% (0/36 executable lines)
- Referenced by: `RTPSApiExtension.swift`
- Test focus:
  - Client creation and caching
  - Token execution and debug logging
  - Recaptcha errors and empty-token fallback behavior

## Suggested Implementation Phases

1. Add focused `PopupController` tests and reusable popup fixtures.
2. Cover `BreadPartnersSDK` entry-point state and callback behavior.
3. Add request-flow tests for `PlacementApiExtension` and `RTPSApiExtension` using mocked API responses.
4. Add popup controller extension tests, starting with action/API behavior before layout-heavy UI branches.
5. Cover `ChallengeController`, `RecaptchaManager`, and `AnalyticsManager` with dependency seams or test doubles where needed.
6. Re-run coverage after each phase and update this file with the new baseline.

## Validation Command

```bash
xcodebuild test \
  -workspace Example/BreadPartnersSDK.xcworkspace \
  -scheme BreadPartnersSDK_UnitTests \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -parallel-testing-enabled NO \
  -enableCodeCoverage YES \
  -resultBundlePath /tmp/BreadPartnersSDK-UnitTests-Coverage.xcresult
```
