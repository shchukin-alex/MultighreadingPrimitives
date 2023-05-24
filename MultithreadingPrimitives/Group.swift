import Foundation

final class Group {
    
    private var mutex = pthread_mutex_t()
    private var condition = pthread_cond_t()
    private var counter = 0
    
    init() {
        pthread_mutex_init(&mutex, nil)
        pthread_cond_init(&condition, nil)
    }
    
    func enter() {
        pthread_mutex_lock(&mutex)
        counter += 1
        pthread_mutex_unlock(&mutex)
    }
    
    func leave() {
        pthread_mutex_lock(&mutex)
        counter -= 1
        pthread_mutex_unlock(&mutex)
        
        pthread_cond_broadcast(&self.condition)
    }
    
    func wait() {
        pthread_mutex_lock(&self.mutex)
        while(self.counter != 0) {
            pthread_cond_wait(&self.condition, &self.mutex)
        }
        pthread_mutex_unlock(&self.mutex)
    }
}
