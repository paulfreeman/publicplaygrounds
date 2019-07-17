//  Created by Paul Freeman on 15/07/2019.
//  Copyright © 2019 Rocket Garden Labs.
//
//  MIT Licence

import Foundation 

///Create a property wrapper for an array and sync updates to it

//MARK:- Code under test
public class ConcurrentResultData<E> 
{
    private let resultPropertyQueue = dispatch_queue_concurrent_t.init(label: UUID().uuidString)
    private var _resultArray = [E]() // Backing storage
    
    public var resultArray:  [E] {
        get {
            var result = [E]()
            resultPropertyQueue.sync {
                result = self._resultArray
            }
            return result
        }
        set {
            resultPropertyQueue.async(group: nil, qos: .default, flags: .barrier) {
               self._resultArray = newValue
            }
        }
    }
    
    public func append(element : E) 
    {
        resultPropertyQueue.async(group: nil, qos: .default, flags: .barrier) {
            self._resultArray.append(element)
        }
    }
    
    public func appendAll(array : [E])
    {
        resultPropertyQueue.async(group: nil, qos: .default, flags: .barrier) {
            self._resultArray.append(contentsOf: array)
        }
    }
    
} 

//MARK:- helpers
var count:Int = 0
let numberOfOperations = 50

func operationCompleted(d:ConcurrentResultData<Dictionary<AnyHashable, AnyObject>>)
   {
    if count + 1 < numberOfOperations {
        count += 1
    }
    else {
        print("All operations complete \(d.resultArray.count)")
        print(d.resultArray)
    }
}

func runOperationAndAddResult(queue:OperationQueue, result:ConcurrentResultData<Dictionary<AnyHashable, AnyObject>> ) 
{
    queue.addOperation 
    {
        let id = UUID().uuidString
        print("\(id) running")
        let delay:Int = Int(arc4random_uniform(2) + 1)
        for _ in 0..<delay {
            sleep(1)
        }
        let dict:[Dictionary<AnyHashable, AnyObject>] = [[ "uuid" : NSString(string: id), "delay" : NSString(string:"\(delay)") ]]
        result.appendAll(array:dict)
        DispatchQueue.main.async {
            print("\(id) complete")
            operationCompleted(d:result)
        }
    }
} 

//MARK:- call 
let q = OperationQueue()
q.maxConcurrentOperationCount = 10
let d = ConcurrentResultData<Dictionary<AnyHashable, AnyObject>>()
for _ in 0..<numberOfOperations {
    runOperationAndAddResult(queue: q, result: d)
}
