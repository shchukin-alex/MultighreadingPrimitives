//

import XCTest
@testable import MultithreadingPrimitives

final class SemaphoreTests: XCTestCase {
    
    func testSemaphore() {
        let serialQueue = DispatchQueue(label: "com.test.test")
        let semaphore = Semaphore(maxCount: 1)
        var result: [Int] = []

        let expectation1 = expectation(description: "test1")
        serialQueue.async {
            semaphore.wait()
            result.append(1)
            sleep(1)
            semaphore.signal()
            expectation1.fulfill()
        }
        
        let expectation2 = expectation(description: "test2")
        serialQueue.async {
            semaphore.wait()
            result.append(2)
            sleep(1)
            semaphore.signal()
            expectation2.fulfill()
        }
        
        let expectation3 = expectation(description: "test3")
        serialQueue.async {
            semaphore.wait()
            result.append(3)
            sleep(1)
            semaphore.signal()
            expectation3.fulfill()
        }

        wait(for: [expectation1, expectation2, expectation3], timeout: 10)

        XCTAssertEqual([1, 2, 3], result)
    }
}
