import XCTest

@testable import Cache

XCTMain([
    testCase(CacheAsyncTests.allTests),
    testCase(CacheMeasure.allTests),
    testCase(CacheTests.allTests)
])
