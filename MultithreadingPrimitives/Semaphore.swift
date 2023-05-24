//
//  Semaphore.swift
//  GCDTest
//
//  Created by Alex Shchukin on 2022-10-07.
//

import Foundation

final class Semaphore {
    
    fileprivate final class Queue {
        private var elements: [Int] = []

        func enqueue(element: Int) {
            elements.append(element)
        }

        func dequeue() -> Int? {
            guard !elements.isEmpty else { return nil }

            return elements.removeFirst()
        }
        
        func peek() -> Int? {
            guard !elements.isEmpty else { return nil }

            return elements.first
        }

        var isEmpty: Bool {
            return elements.isEmpty
        }
    }
    
    private var mutex = pthread_mutex_t()
    private var condition = pthread_cond_t()
    private var counter = 0
    private var maxCount = 0
    private let queue: Queue = Queue()
    
    init(maxCount: Int = 0) {
        pthread_mutex_init(&mutex, nil)
        pthread_cond_init(&condition, nil)
        self.maxCount = maxCount
    }
    
    func signal() {
        pthread_mutex_lock(&mutex)
        counter -= 1
        pthread_mutex_unlock(&mutex)
        
        pthread_cond_broadcast(&condition)
    }
    
    func wait() {
        pthread_mutex_lock(&self.mutex)
        
        counter += 1
        let tmpCounter = counter
        
        while(self.counter > self.maxCount && self.queue.peek() != tmpCounter) {
            queue.enqueue(element: tmpCounter)
            pthread_cond_wait(&self.condition, &self.mutex)
        }
        
        pthread_mutex_unlock(&self.mutex)
    }
}
