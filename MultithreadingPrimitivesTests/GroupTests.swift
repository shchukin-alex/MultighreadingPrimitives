//

import XCTest
@testable import MultithreadingPrimitives

final class GroupTests: XCTestCase {

    func testGroup() {
        let group = Group()
        let concurrentQueue = DispatchQueue(label: "com.test.testGroup", attributes: .concurrent)
        
        let expectation1 = expectation(description: "test1")
        group.enter()
        concurrentQueue.async {
            sleep(1)
            group.leave()
            expectation1.fulfill()
        }
        
        let expectation2 = expectation(description: "test2")
        group.enter()
        concurrentQueue.async {
            group.leave()
            expectation2.fulfill()
        }

        group.wait()
        
        wait(for: [expectation1, expectation2])
    }
}
