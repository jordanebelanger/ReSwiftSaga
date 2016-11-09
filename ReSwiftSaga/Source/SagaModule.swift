//
//  SagaModule.swift
//  ReSwiftSaga
//
//  Created by Jordane Gagnon Belanger on 11/8/16.
//  Copyright © 2016 tehjord. All rights reserved.
//

import ReSwift

fileprivate class SagaModuleTask {
    var workItem: DispatchWorkItem!
    var finished: Bool = false
}

open class SagaModule<SagaStoreType: StoreType> {
    let store: SagaStoreType
    
    private var tasks: [String: [SagaModuleTask]] = [:]
    
    init(withStore store: SagaStoreType) {
        self.store = store
    }
    
    public func execute<T: Saga>(saga: T) {
        self.cleanUp(saga: saga)
        
        switch T.type {
        case .takeFirst:
            takeFirst(saga: saga)
        case .takeEvery:
            takeEvery(saga: saga)
        case .takeLatest:
            takeLatest(saga: saga)
        }
    }
    
    public func cancelSagas(withName name: String) {
        guard let tasks = self.tasks[name] else {
            return
        }
        
        for task in tasks {
            task.finished = true
            task.workItem.cancel()
        }
        
        self.tasks[name] = nil
    }
    
    private func takeFirst<T: Saga>(saga: T) {
        if let currentTask = self.tasks[T.name]?.first, currentTask.finished == false {
            return // Ignoring the task if there is an ongoing takeFirst task for this Saga
        }
        
        let task = self.task(forSaga: saga)
        
        self.tasks[T.name] = [task]
        task.workItem.perform()
    }
    
    private func takeEvery<T: Saga>(saga: T) {
        let task = self.task(forSaga: saga)
        if self.tasks[T.name] != nil {
            self.tasks[T.name]!.append(task)
        } else {
            self.tasks[T.name] = [task]
        }
        
        task.workItem.perform()
    }
    
    private func takeLatest<T: Saga>(saga: T) {
        if let currentTask = self.tasks[T.name]?.first, currentTask.finished == false {
            currentTask.finished = true
            currentTask.workItem.cancel()
        }
        
        let task = self.task(forSaga: saga)
        
        self.tasks[T.name] = [task]
        task.workItem.perform()
    }
    
    private func task<T: Saga>(forSaga saga: T) -> SagaModuleTask {
        let task = SagaModuleTask()
        task.workItem = DispatchWorkItem { [weak self, weak task] in
            saga.action { [weak self, weak task] dispatchFn in
                guard let weakSagaModule = self, let weakTask = task, weakTask.finished == false else {
                    return
                }
                
                let result = dispatchFn(weakSagaModule.store.state)
                if result.0 {
                    weakTask.finished = true
                }
                
                let _ = weakSagaModule.store.dispatch(result.1)
            }
        }
        return task
    }
    
    private func cleanUp<T: Saga>(saga: T) {
        guard var tasks = self.tasks[T.name] else {
            return
        }
        
        tasks = tasks.filter { $0.finished == false }
        self.tasks[T.name] = tasks
    }
    
}
