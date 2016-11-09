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
    typealias ActionCreator = ( @escaping ( (StateType) -> (Bool, Action) ) -> Void ) -> Void
    
    static var name: String { get }
    static var type: SagaType { get }
    
    var action: ActionCreator { get }
}
public extension Saga {
    static var name: String {
        return  "\(type(of: self))"
    }
}
