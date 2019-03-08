import UIKit

// First things first: Result type is a Generic Type

// but..., what's a Generic Type? (* Ref)

// Def. (Generic Code): Generic code (Generic Type) allows you to write flexible, reusable code that can accept any type

// Take the example:

func swapTwoInts(_ a: inout Int, _ b: inout Int) {
    let temporaryA = a
    a = b
    b = temporaryA
}

// This function takes in two inout parameters and swaps them
// Remark: inout parameters are parameters that are passed by value and will modify variables that are out of scope
// Note that when variables are passed, ampersand is needed

var someInt = 3
var anotherInt = 107
swapTwoInts(&someInt, &anotherInt)
print("someInt is now \(someInt), and anotherInt is \(anotherInt)")
// prints out someInt is now 107, and anotherInt is 3

// Take another example:
func swapTwoStrings(_ a: inout String, _ b: inout String) {
    let temporaryA = a
    a = b
    b = temporaryA
}

// swapTwoStrings implementation is identical to swapTwoInts, is it possible that we introduce a logic abstraction of the two functions?

// Generic Example
func swapTwoValues<Type>(_ a: inout Type, _ b: inout Type) {
    let temporaryA = a
    a = b
    b = temporaryA
}

// Remarks:
// 1. "Type" is placeholder type name, not an actual type. Swift will NOT search for such type
// 2. a and b have to be of the same generic type: "Type"
// 3. "Type" is merely a placeholder
// 4. Generic function can be passed two values of **any** type. The Type to use for "Type" is inferred from the types of values passed

// Now:

someInt = 50
anotherInt = 100
swapTwoValues(&someInt, &anotherInt)
print("someInt is now \(someInt), and anotherInt is \(anotherInt)")
// someInt is now 100, and anotherInt is 50

var someString = "hello"
var anotherString = "world"
swapTwoValues(&someString, &anotherString)
print("someString is now: \(someString), and anotherString is now: \(anotherString)")
// someString is now: world, and anotherString is now: hello


// Error handling basics in Swift -- The Swift Dev (* Ref)


// 1. Use Optionals

let zeroValue = Int("0") // Int
let nilValue = Int("not a number") // Int? and is nil, but no errors will be shown as it is optional

guard let number = Int("6") else {
    fatalError("Ooops... this should always work, so we crash.")
}
print(number)

// 2. Throw errors using the Error protocol

// Use an enum to define different error reasons
enum DivisionError: Error {
    case zeroDivisor
}

extension DivisionError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .zeroDivisor:
            return "Division by zero is quite problematic. " +
            "(https://en.wikipedia.org/wiki/Division_by_zero)"
        }
    }
}

func divideByErrorProtocol(_ x: Int, by y: Int) throws -> Int {
    guard y != 0 else {
        throw DivisionError.zeroDivisor
    }
    return x / y
}

// We can catch specific error types by casting them using the let error as MyType syntax

do {
    try divideByErrorProtocol(100, by: 0)
    try divideByErrorProtocol(25, by: 4)
} catch let error as DivisionError {
    print("Division error handler block")
    print(error.localizedDescription)
} catch {
    print("Generic error handler block")
    print(error.localizedDescription)
}

// Differences between try, try? and try!
// try forces us to use do, try, catch syntax to handle our errors, if we cared about what the errors meant
// Sometimes when we don't care about the exact error, we can simply use ```try?```

guard let anotherNumber = try? divideByErrorProtocol(10, by: 2) else {
    fatalError("This should work")
}
print(anotherNumber) // 5

// Not recommended: Simply let the app crash and not spit out the error
let someNumber = try! divideByErrorProtocol(10, by: 2) // this will work for sure
print(someNumber)

// Note that Swift errors are not exceptions, since they are handled intentionally
// When an error is raised, execution exits current scope
// Exceptions unwind the stack, which may lead to memory leaks

// Introducing the Result Type

func divideByResultType(_ x: Int, by y: Int) -> Result<Int, DivisionError> {
    guard y != 0 else {
        return .failure(.zeroDivisor)
    }
    return .success(x / y)
}

let result = divideByResultType(10, by: 5)
let zeroDivisorResult = divideByResultType(10, by: 5)
switch result {
case .success(let number):
    print(number)
case .failure(let error):
    print(error.localizedDescription)
}



// Advantages
// 1. Type Safe: Throwing functions can throw any kind of errors
// Throwing functions can throw any type of errors but we forcing the
// the error type to be ```DivisionError``` here

// 2. Can switch the result w/o providing a default case

// How is this better than throwing functions?
// Note that ```throw``` is a function keyword, meaning
// that we need to create a function to facilitate the throw

// Consider the asynchronous process where completion closure
// callback

// Throwing functions can be difficult to follow as
// we are passing the throwing function as an inner
// closure for the completion block ```(() throws -> Int) - > Void```

func divideWithThrowing(_ x: Int, by y: Int, completion: ((() throws -> Int) -> Void)) {
    guard y != 0 else {
        completion { throw DivisionError.zeroDivisor }
        return
    }
    completion { return x / y }
}

divideWithThrowing(10, by: 0) { calculate in
    do {
        // calculate() is the inner closure
        let number = try calculate()
        print(number)
    }
    catch {
        print(error.localizedDescription)
    }
}

// A nicer way to do callbacks is to use optionals

func divideWithOptionals(_ x: Int, _ y: Int, completion: (Int?) -> Void) {
    guard y != 0 else {
        return completion(nil)
    }
    completion(x / y) // Int?
}

divideWithOptionals(10, 0) { (result) in
    guard let result = result else {
        debugPrint("result is nil!")
        return
    }
    print(result)
}

// Additionally, we may add in our ```Error``` parameter in the closure
// to catch the error. Note that the error also has to be option

func divideWithErrorOptionals(_ x: Int, _ y: Int, completion: (Int?, Error?) -> Void) {
    guard y != 0 else {
        return completion(nil, DivisionError.zeroDivisor)
    }
    completion(x / y, nil)
}

divideWithErrorOptionals(10, 0) { (result, err) in
    guard err == nil else {
        debugPrint("Result returned an error: \(err!.localizedDescription)")
        return
    }
    print("result: \(result)")
}

// WITH RESULT TYPE!!!! SUPER CLEAN!!
func divideWithAsyncResultType(_ x: Int, _ y: Int, completion: (Result<Int, DivisionError>) -> Void) {
    
    guard y != 0 else {
        return completion(.failure(.zeroDivisor))
    }
    return completion(.success(x / y))
}

divideWithAsyncResultType(10, 0) { (result) in
    switch result {
    case .success(let number):
        print(number)
    case .failure(let error):
        debugPrint("Result returned an error: \(error)")
    }
}

// References
// https://docs.swift.org/swift-book/LanguageGuide/Generics.html
// https://docs.swift.org/swift-book/LanguageGuide/Functions.html#ID173
// https://theswiftdev.com/2019/01/28/how-to-use-the-result-type-to-handle-errors-in-swift/
// https://www.hackingwithswift.com/articles/161/how-to-use-result-in-swift
// 
