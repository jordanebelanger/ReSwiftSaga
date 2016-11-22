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
    
    public func execute<T: Saga where T.SagaStoreStateType == SagaStoreType.State>(saga: T) {
        self.cleanUpSagas(withName: T.name)
        
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
    
    public func cancelAllSagas() {
        for taskGroup in self.tasks.values {
            for task in taskGroup {
                task.finished = true
                task.workItem.cancel()
            }
        }
        
        self.tasks.removeAll()
    }
    
    private func takeFirst<T: Saga where T.SagaStoreStateType == SagaStoreType.State>(saga: T) {
        if let currentTask = self.tasks[T.name]?.first, currentTask.finished == false {
            return // Ignoring the task if there is an ongoing takeFirst task for this Saga
        }
        
        let task = self.task(forSaga: saga)
        
        self.tasks[T.name] = [task]
        task.workItem.perform()
    }
    
    private func takeEvery<T: Saga where T.SagaStoreStateType == SagaStoreType.State>(saga: T) {
        let task = self.task(forSaga: saga)
        if self.tasks[T.name] != nil {
            self.tasks[T.name]!.append(task)
        } else {
            self.tasks[T.name] = [task]
        }
        
        task.workItem.perform()
    }
    
    private func takeLatest<T: Saga where T.SagaStoreStateType == SagaStoreType.State>(saga: T) {
        if let currentTask = self.tasks[T.name]?.first, currentTask.finished == false {
            currentTask.finished = true
            currentTask.workItem.cancel()
        }
        
        let task = self.task(forSaga: saga)
        
        self.tasks[T.name] = [task]
        task.workItem.perform()
    }
    
    private func task<T: Saga where T.SagaStoreStateType == SagaStoreType.State>(forSaga saga: T) -> SagaModuleTask {
        let task = SagaModuleTask()
        
        task.workItem = DispatchWorkItem { [weak self, weak task] in
            guard let strongSagaModule = self, let strongTask = task, strongTask.finished == false else {
                return
            }
            
            let finishCallback: () -> Void = { [weak strongTask] in
                strongTask?.finished = true
            }

            saga.action(strongSagaModule.store.state, finishCallback) { [weak strongSagaModule, weak strongTask] dispatchFn in
                guard let sagaModule = strongSagaModule, let task = strongTask, task.finished == false else {
                    return
                }
                
                let action = dispatchFn(sagaModule.store.state)
                let _ = sagaModule.store.dispatch(action)
            }
        }
        return task
    }
    
    private func cleanUpSagas(withName name: String) {
        guard var tasks = self.tasks[name] else {
            return
        }
        
        tasks = tasks.filter { $0.finished == false }
        self.tasks[name] = tasks
    }
    
}
