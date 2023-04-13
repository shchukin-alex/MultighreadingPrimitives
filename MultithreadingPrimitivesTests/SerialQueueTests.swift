import XCTest
@testable import MultithreadingPrimitives

final class SerialQueueTests: XCTestCase {

    func testFromMainAndBackgroundThreads() {
        let serialQueue = SerialQueue()
        var result: [Int] = []

        let expectation1 = expectation(description: "test1")
        serialQueue.async {
            sleep(1)
            result.append(1)
            expectation1.fulfill()
        }

        let expectation2 = expectation(description: "test2")
        serialQueue.async {
            sleep(1)
            result.append(2)
            expectation2.fulfill()
        }

        let expectation3 = expectation(description: "test3")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) {
            serialQueue.sync {
                sleep(1)
                result.append(3)
                expectation3.fulfill()
            }
        }

        let expectation4 = expectation(description: "test4")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.4) {
            serialQueue.async {
                sleep(1)
                result.append(4)
                expectation4.fulfill()
            }
        }

        let expectation5 = expectation(description: "test5")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            serialQueue.sync {
                sleep(1)
                result.append(5)
                expectation5.fulfill()
            }
        }

        wait(for: [expectation1, expectation2, expectation3, expectation4, expectation5], timeout: 10.0)

        XCTAssertEqual([1, 2, 3, 4, 5], result)
    }

    func testFromBackgroundThreads() {
        let serialQueue = SerialQueue()
        var result: [Int] = []

        let expectation1 = expectation(description: "test1")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
            serialQueue.async {
                sleep(1)
                result.append(1)
                expectation1.fulfill()
            }
        }

        let expectation2 = expectation(description: "test2")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) {
            serialQueue.async {
                sleep(1)
                result.append(2)
                expectation2.fulfill()
            }
        }

        let expectation3 = expectation(description: "test3")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) {
            serialQueue.async {
                sleep(1)
                result.append(3)
                expectation3.fulfill()
            }
        }

        let expectation4 = expectation(description: "test4")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.4) {
            serialQueue.sync {
                sleep(1)
                result.append(4)
                expectation4.fulfill()
            }
            print("sync4")
        }

        let expectation5 = expectation(description: "test5")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            serialQueue.async {
                sleep(1)
                result.append(5)
                expectation5.fulfill()
            }
        }

        wait(for: [expectation1, expectation2, expectation3, expectation4, expectation5], timeout: 10.0)

        XCTAssertEqual([1, 2, 3, 4, 5], result)
    }

    func testFromMainThread() {
        let serialQueue = SerialQueue()

        var result: [Int] = []

        let expectation1 = expectation(description: "test1")
        serialQueue.async {
            sleep(1)
            result.append(1)
            expectation1.fulfill()
        }

        let expectation2 = expectation(description: "test2")
        serialQueue.sync {
            sleep(2)
            result.append(2)
            expectation2.fulfill()
        }

        let expectation3 = expectation(description: "test3")
        serialQueue.async {
            sleep(1)
            result.append(3)
            expectation3.fulfill()
        }

        let expectation4 = expectation(description: "test4")
        serialQueue.sync {
            sleep(1)
            result.append(4)
            expectation4.fulfill()
        }

        let expectation5 = expectation(description: "test5")
        serialQueue.sync {
            result.append(5)
            expectation5.fulfill()
        }

        wait(for: [expectation1, expectation2, expectation3, expectation4, expectation5], timeout: 10.0)
    }

    func testSimultaneousSync() {
        let serialQueue = SerialQueue()

        let expectation1 = expectation(description: "test1")
        DispatchQueue.global().async {
            serialQueue.sync {
                expectation1.fulfill()
            }
        }

        let expectation2 = expectation(description: "test2")
        DispatchQueue.global().async {
            serialQueue.sync {
                expectation2.fulfill()
            }
        }

        let expectation3 = expectation(description: "test3")
        DispatchQueue.global().async {
            serialQueue.sync {
                expectation3.fulfill()
            }
        }

        let expectation4 = expectation(description: "test4")
        DispatchQueue.global().async {
            serialQueue.sync {
                expectation4.fulfill()
            }
        }

        let expectation5 = expectation(description: "test5")
        DispatchQueue.global().async {
            serialQueue.sync {
                expectation5.fulfill()
            }
        }

        wait(for: [expectation1, expectation2, expectation3, expectation4, expectation5], timeout: 10.0)
    }

    func testSimultaneousAsync() {
        let serialQueue = SerialQueue()
//        let serialQueue = DispatchQueue(label: "com.test.test")

        let expectation1 = expectation(description: "test1")
        DispatchQueue.global().async {
            serialQueue.async {
                expectation1.fulfill()
            }
        }

        let expectation2 = expectation(description: "test2")
        DispatchQueue.global().async {
            serialQueue.async {
                expectation2.fulfill()
            }
        }

        let expectation3 = expectation(description: "test3")
        DispatchQueue.global().async {
            serialQueue.async {
                expectation3.fulfill()
            }
        }

        let expectation4 = expectation(description: "test4")
        DispatchQueue.global().async {
            serialQueue.async {
                expectation4.fulfill()
            }
        }

        let expectation5 = expectation(description: "test5")
        DispatchQueue.global().async {
            serialQueue.async {
                expectation5.fulfill()
            }
        }

        wait(for: [expectation1, expectation2, expectation3, expectation4, expectation5], timeout: 10.0)
    }

    func testSimultaneousMixed() {
        let serialQueue = SerialQueue()

        let expectation1 = expectation(description: "test1")
        DispatchQueue.global().async {
            serialQueue.sync {
                expectation1.fulfill()
            }
        }

        let expectation2 = expectation(description: "test2")
        DispatchQueue.global().async {
            serialQueue.async {
                expectation2.fulfill()
            }
        }

        let expectation3 = expectation(description: "test3")
        DispatchQueue.global().async {
            serialQueue.async {
                expectation3.fulfill()
            }
        }

        let expectation4 = expectation(description: "test4")
        DispatchQueue.global().async {
            serialQueue.sync {
                expectation4.fulfill()
            }
        }

        let expectation5 = expectation(description: "test5")
        DispatchQueue.global().async {
            serialQueue.async {
                expectation5.fulfill()
            }
        }

        wait(for: [expectation1, expectation2, expectation3, expectation4, expectation5], timeout: 10.0)
    }

    func testDeinit() {
        var queue: SerialQueue? = SerialQueue()
        weak var weakQueue = queue

        let expectation = expectation(description: "test")
        DispatchQueue.global().async {
            queue = nil
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertNil(weakQueue)
    }
}
