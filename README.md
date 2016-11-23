Here's how it works:

``` 
// Create a store as per usual
let store = Store(reducer: Reducer(), state: AppState())

// Create your SagaModule passing in your store
let sagaModule = SagaModule(withStore: store)

// Define a Saga
struct UserRefreshSaga: Saga {

	static var type: SagaType {
		// With .takeLatest someone attempting run a UserRefreshSaga while there is an ongoing one
		// would immediately stop the initial Saga and start a new one.
        return .takeLatest
    }

    var action: (
        AppState, // Current state of the store
        @escaping () -> Void, // The Saga ending function, tells the saga module this saga is over
        @escaping ((AppState) -> (Action)) -> Void // The action dispatching function
    ) -> Void {
        return { state, finishCallback, dispatchFn in

        	// Dispatching a StartedRefreshingUserAction to your SagaModule's Store
            dispatchFn { _ in return StartedRefreshingUserAction() }
            
            getUserProfile { result in
                switch result {
                case .success(let value):
                    dispatchFn { _ in return RefreshedUserAction(user: value) }
                    
                    // Tells the SagaModule this Saga has finished its work. Any further
                    // accidental dispatch from this closure will now be ignored by the SagaModule.
                    finishCallback()

                case .failure(let error):
                    dispatchFn { _ in return FailedToRefreshUserAction(error: error) }
                    finishCallback()
                }
            }
        }
    }

}

// Dispatch 1 Saga 
sagaModule.dispatch(UserRefreshSaga())

// Dispatch multiple .takeLatest Saga
sagaModule.dispatch(UserRefreshSaga())
sagaModule.dispatch(UserRefreshSaga())
sagaModule.dispatch(UserRefreshSaga()) // Only this one will fully execute after the async network request

```
