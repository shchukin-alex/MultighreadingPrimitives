import Foundation

final class SerialQueue {

    fileprivate final class Task {
        fileprivate enum TaskType: String {
            case sync
            case async
        }

        let type: TaskType
        let execute: (() -> ())
        let threadId: UInt32

        init(type: TaskType, threadId: UInt32, execute: @escaping (() -> ())) {
            self.type = type
            self.execute = execute
            self.threadId = threadId
        }
    }

    fileprivate final class Queue {
        private var elements: [Task] = []
        private var mutex = pthread_mutex_t()

        init() {
            pthread_mutex_init(&mutex, nil)
        }

        func enqueue(element: Task) {
            pthread_mutex_lock(&mutex)
            elements.append(element)
            pthread_mutex_unlock(&mutex)
        }

        func dequeue() -> Task? {
            pthread_mutex_lock(&mutex)
            defer {
                pthread_mutex_unlock(&mutex)
            }
            guard !elements.isEmpty else { return nil }

            return elements.removeFirst()
        }

        var isEmpty: Bool {
            pthread_mutex_lock(&mutex)
            defer {
                pthread_mutex_unlock(&mutex)
            }
            return elements.isEmpty
        }
    }

    fileprivate final class SynchronizedDictionary {
        private var storage: [UInt32: Bool] = [:]
        private var mutex = pthread_mutex_t()

        init() {
            pthread_mutex_init(&mutex, nil)
        }

        func set(value: Bool, key: UInt32) {
            pthread_mutex_lock(&mutex)
            storage[key] = value
            pthread_mutex_unlock(&mutex)
        }

        func value(key: UInt32) -> Bool? {
            pthread_mutex_lock(&mutex)
            defer {
                pthread_mutex_unlock(&mutex)
            }
            return storage[key]
        }
    }

    private var thread: pthread_t?
    private var condition = pthread_cond_t()
    private var mutex = pthread_mutex_t()

    // Used to stop executing background thread
    private var stop = false

    // Used to make an order for sync and async tasks
    private let queue = Queue()

    // Used to store sync execution status per thread
    private var syncExecutionStates = SynchronizedDictionary()

    init() {

        let weakSelfPointer = Unmanaged.passUnretained(self).toOpaque()

        _ = pthread_create(&thread, nil, { (pointer: UnsafeMutableRawPointer) in

            let weakSelf = Unmanaged<SerialQueue>.fromOpaque(pointer).takeRetainedValue()
            weakSelf.runThread()

            pthread_exit(nil)
        }, weakSelfPointer)

        pthread_cond_init(&condition, nil)
        pthread_mutex_init(&mutex, nil)
    }

    func async(task: @escaping () -> ()) {
        let threadId = pthread_mach_thread_np(pthread_self())
        queue.enqueue(element: Task(type: .async, threadId: threadId, execute: task))
        pthread_cond_broadcast(&condition)
    }

    func sync(task: @escaping () -> ()) {
        // Storing sync task with dedicated thread id into thread safe queue for the following execution
        let threadId = pthread_mach_thread_np(pthread_self())
        queue.enqueue(element: Task(type: .sync, threadId: threadId, execute: task))

        // Mark the task is NOT executing yet for the calling thread (threadId)
        syncExecutionStates.set(value: false, key: threadId)

        pthread_mutex_lock(&mutex)

        // Unblock the queue thread if it doesn't execute any task
        pthread_cond_broadcast(&condition)

        // Put on wait current thread if the queue thread is executing the other task
        while(syncExecutionStates.value(key: threadId) == false) {
            pthread_cond_wait(&condition, &mutex)
        }
        // Execute the task on the calling thread
        task()

        // Mark the task is NOT executing for the calling thread (threadId)
        syncExecutionStates.set(value: false, key: threadId)
        pthread_cond_broadcast(&condition)

        pthread_mutex_unlock(&mutex)
    }

    deinit {
        // Set stop flag to finish while loop in the background thread
        stop = true
        // Wake background thread if it was put on wait
        pthread_cond_broadcast(&condition)

        // Wait until background thread finishes its execution
        if let thread = thread {
            pthread_join(thread, nil)
        }

        pthread_cond_destroy(&condition)
        pthread_mutex_destroy(&mutex)
    }

    private func runThread() {
        while(!stop) {
            while let task = queue.dequeue() {
                if task.type == .sync {
                    // Mark the task is executing for the thread id
                    syncExecutionStates.set(value: true, key: task.threadId)
                    pthread_cond_broadcast(&condition)

                    // Lock the queue thread while the sync task is executing on the calling thread
                    while(syncExecutionStates.value(key: task.threadId) == true) {
                        pthread_cond_wait(&condition, &mutex)
                    }
                    continue
                } else {
                    task.execute()
                }
            }

            // Until the task queue is empty put on wait
            while(queue.isEmpty && !stop) {
                pthread_cond_wait(&condition, &mutex)
            }
        }
    }
}
