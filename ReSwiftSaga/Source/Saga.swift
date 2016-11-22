//
//  Saga.swift
//  Saga
//
//  Created by Jordane Gagnon Belanger on 11/5/16.
//  Copyright © 2016 benji. All rights reserved.
//

import ReSwift

public enum SagaType {
    case takeFirst
    case takeEvery
    case takeLatest
}

public protocol Saga {
    associatedtype SagaStoreStateType: StateType
    
    static var name: String { get }
    static var type: SagaType { get }
    
    // Notify this Saga's SagaModule that the action has finished all its work by calling this callback
    // in your Saga's action.
    typealias FinishCallback = () -> Void
    
    // Dispatch action to this Saga's SagaModule's store by returning an Action the dispatchCallback
    // passed in parameter to the DispatchFn in your Saga's action.
    typealias DispatchFn = ( (SagaStoreStateType) -> (Action) ) -> Void
    
    typealias ActionCreator = (SagaStoreStateType, FinishCallback, DispatchFn) -> Void
    
    var action: ActionCreator { get }
}
public extension Saga {
    static var name: String {
        return  "\(type(of: self))"
    }
}
