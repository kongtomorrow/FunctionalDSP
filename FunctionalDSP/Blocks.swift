//
//  Blocks.swift
//  FunctionalDSP
//
//  Created by Christopher Liscio on 4/14/15.
//  Copyright (c) 2015 SuperMegaUltraGroovy, Inc. All rights reserved.
//

import Foundation

// Inspired by Faust:
// http://faust.grame.fr/index.php/documentation/references/12-documentation/reference/48-faust-syntax-reference-art

/// A block has zero or more inputs, and produces zero or more outputs
//public protocol BlockType {
//    typealias SignalType
//    var inputCount: Int { get }
//    var outputCount: Int { get }
//    var process: [SignalType] -> [SignalType] { get }
//    
//    init(inputCount: Int, outputCount: Int, process: [SignalType] -> [SignalType])
//}

public struct Block<SignalType> {
    public let inputCount: Int
    public let outputCount: Int
    public let process: [SignalType] -> [SignalType]
    
    public init(inputCount: Int, outputCount: Int, process: [SignalType] -> [SignalType]) {
        self.inputCount = inputCount
        self.outputCount = outputCount
        self.process = process
    }
}

public func identity<S>(inputs: Int) -> Block<S> {
    return Block(inputCount: inputs, outputCount: inputs, process: { $0 })
}

//
//   -block-----
//  =|=[A]=[B]=|=
//   -----------
//

/// Runs two blocks serially
public func serial<S>(lhs: Block<S>, rhs: Block<S>) -> Block<S> {
    return Block(inputCount: lhs.inputCount, outputCount: rhs.outputCount, process: { inputs in
        return rhs.process(lhs.process(inputs))
    })
}

//
//   -block---
//  =|==[A]==|=
//  =|==[B]==|=
//   ---------
//

/// Runs two blocks in parallel
public func parallel<S>(lhs: Block<S>, rhs: Block<S>) -> Block<S> {
    let totalInputs = lhs.inputCount + rhs.inputCount
    let totalOutputs = lhs.outputCount + rhs.outputCount
    
    return Block(inputCount: totalInputs, outputCount: totalOutputs, process: { inputs in
        var outputs: [S] = []
        
        outputs += lhs.process(Array<S>(inputs[0..<lhs.inputCount]))
        outputs += rhs.process(Array<S>(inputs[lhs.inputCount..<lhs.inputCount+rhs.inputCount]))
        
        return outputs
    })
}

//
//   -block-------
//  =|=[A]=>-[B]-|-
//   -------------
//

/// Merges the outputs of the block on the left to the inputs of the block on the right
public func merge(lhs: Block<Signal>, rhs: Block<Signal>) -> Block<Signal> {
    return Block(inputCount: lhs.inputCount, outputCount: rhs.outputCount, process: { inputs in
        let leftOutputs = lhs.process(inputs)
        var rightInputs: [Signal] = []

        let k = lhs.outputCount / rhs.inputCount
        for i in 0..<rhs.inputCount  {
            var inputsToSum = Array<Signal>()
            for j in 0..<k {
                inputsToSum.append(leftOutputs[i+(rhs.inputCount*j)])
            }
            let summed = inputsToSum.reduce(NullSignal) { mix($0, $1) }
            rightInputs.append(summed)
        }

        return rhs.process(rightInputs)
    })
}

//
//     -block-------
//    -|-[A]-<=[B]=|=
//     -------------
//
//

/// Split the block on the left, replicating its outputs as necessary to fill the inputs of the block on the right
public func split<S>(lhs: Block<S>, rhs: Block<S>) -> Block<S> {
    return Block(inputCount: lhs.inputCount, outputCount: rhs.outputCount, process: { inputs in
        let leftOutputs = lhs.process(inputs)
        var rightInputs: [S] = []
        
        // Replicate the channels from the lhs to each of the inputs
        let k = lhs.outputCount
        for i in 0..<rhs.inputCount {
            rightInputs.append(leftOutputs[i%k])
        }
        
        return rhs.process(rightInputs)
    })
}

// MARK: Operators

infix operator |- { associativity left }
infix operator -- { associativity left }
infix operator -< { associativity left }
infix operator >- { associativity left }

// Parallel
public func |-<S>(lhs: Block<S>, rhs: Block<S>) -> Block<S> {
    return parallel(lhs, rhs)
}

// Serial
public func --<S>(lhs: Block<S>, rhs: Block<S>) -> Block<S> {
    return serial(lhs, rhs)
}

// Split
public func -<<S>(lhs: Block<S>, rhs: Block<S>) -> Block<S> {
    return split(lhs, rhs)
}

// Merge
public func >-(lhs: Block<Signal>, rhs: Block<Signal>) -> Block<Signal> {
    return merge(lhs, rhs)
}