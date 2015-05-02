//
//  FunctionalDSP.swift
//  FunctionalDSP
//
//  Created by Christopher Liscio on 3/8/15.
//  Copyright (c) 2015 SuperMegaUltraGroovy, Inc. All rights reserved.
//

import Foundation
import Accelerate



// Just to demonstrate, mixing doubles and floats for parameter and sample types, respectively
public struct Signal<S:FloatOrDouble> {
    let compute : Int -> S
    public init(_ compute : Int -> S) {
        self.compute = compute
    }
    
    subscript (i: Int) -> S {
        return compute(i)
    }
    
    public static func null() -> Signal {
        return Signal { i in
            return 0
        }
    }
    
    public func scale<P:FloatOrDouble>(amplitude : P) -> Signal {
        return Signal { i in
            return S(self[i] * S(amplitude))
        }
    }
    
    public func mix(other: Signal) -> Signal {
        return Signal { i in
            return self[i] + other[i]
        }
    }
    /// Mix an arbitrary number of signals together
    static public func mix(signals: [Signal]) -> Signal {
        return Signal { i in
            return signals.reduce(S(0)) { $0 + $1[i] }
        }
    }
    
    // MARK: Generators
    
    /// Generate a sine wave
    static public func sineWave<P:FloatOrDouble>(sampleRate: Int, _ frequency: P) -> Signal {
        let phi = frequency / P(sampleRate)
        return Signal { i in
            return S(sin(2.0 * P(0) * phi * P(M_PI)))
        }
    }
    
    /// Simple white noise generator
    static public func whiteNoise() -> Signal {
        return Signal { i in
            return S(-1.0 + 2.0 * (S(arc4random_uniform(UInt32(Int16.max))) / S(Int16.max)))
        }
    }
    
    // MARK: Output
    
    /// Read count samples from the signal starting at the specified index
    public func getOutput(index: Int, _ count: Int) -> [S] {
        return [Int](index..<count).map { self[$0] }
    }
    
    // MARK: Filtering
    public func pinkFilter() -> Signal {
        return filt(gFilt.b, gFilt.a, &gFilt.w)
    }

    public func filt<FilterType:FloatOrDouble>(var b: [FilterType], var _ a: [FilterType], inout _ w: [FilterType]!) -> Signal {
        let N = a.count
        let M = b.count
        let MN = max(N, M)
        let lw = MN - 1
        
        if w == nil {
            w = [FilterType](count: lw, repeatedValue: 0)
        }
        assert(w.count == lw)
        
        if b.count < MN {
            b = b + zeros(MN-b.count)
        }
        if a.count < MN {
            a = a + zeros(MN-a.count)
        }
        
        let norm = a[0]
        assert(norm > 0, "First element in A must be nonzero")
        if fabs(norm - 1.0) > FilterType.Epsilon {
            scal(&b, 1.0 / norm)
        }
        
        if N > 1 {
            // IIR Filter Case
            if fabs(norm - 1.0) > FilterType.Epsilon {
                scal(&a, 1.0 / norm)
            }
            
            return Signal { i in
                let xi = FilterType(self[i])
                let y = w[0] + (b[0] * xi)
                if ( lw > 1 ) {
                    for j in 0..<(lw - 1) {
                        w[j] = w[j+1] + (b[j+1] * xi) - (a[j+1] * y)
                    }
                    w[lw-1] = (b[MN-1] * xi) - (a[MN-1] * y)
                } else {
                    w[0] = (b[MN-1] * xi) - (a[MN-1] * y)
                }
                return S(y)
            }
        } else {
            // FIR Filter Case
            if lw > 0 {
                return Signal { i in
                    let xi = FilterType(self[i])
                    let y = w[0] + b[0] * xi
                    if ( lw > 1 ) {
                        for j in 0..<(lw - 1) {
                            w[j] = w[j+1] + (b[j+1] * xi)
                        }
                        w[lw-1] = b[MN-1] * xi;
                    }
                    else {
                        w[0] = b[1] * xi
                    }
                    return S(y)
                }
            } else {
                // No delay
                return Signal { i in S(Double(self[i]) * Double(b[0])) }
            }
        }
    }
}

struct PinkFilter {
    // Filter coefficients from jos: https://ccrma.stanford.edu/~jos/sasp/Example_Synthesis_1_F_Noise.html
    var b: [Double] = [0.049922035, -0.095993537, 0.050612699, -0.004408786];
    var a: [Double] = [1.000000000, -2.494956002, 2.017265875, -0.522189400];
    
    // The filter's "memory"
    var w: [Double]! = nil
    init() {}
}

var gFilt = PinkFilter()

//public func NullSignal(_: Int) -> SampleType {
//    return 0
//}
//
//// MARK: Basic Operations
//
///// Scale a signal by a given amplitude
//public func scale(s: Signal, amplitude: ParameterType) -> Signal {
//    return { i in
//        return SampleType(s(i) * SampleType(amplitude))
//    }
//}
//
//// MARK: Mixing
//
///// Mix two signals together
//public func mix(s1: Signal, s2: Signal) -> Signal {
//    return { i in
//        return s1(i) + s2(i)
//    }
//}
//
///// Mix an arbitrary number of signals together
//public func mix(signals: [Signal]) -> Signal {
//    return { i in
//        return signals.reduce(SampleType(0)) { $0 + $1(i) }
//    }
//}
//
//// MARK: Generators
//
///// Generate a sine wave
//public func sineWave(sampleRate: Int, frequency: ParameterType) -> Signal {
//    let phi = frequency / ParameterType(sampleRate)
//    return { i in
//        return SampleType(sin(2.0 * ParameterType(i) * phi * ParameterType(M_PI)))
//    }
//}
//
///// Simple white noise generator
//public func whiteNoise() -> Signal {
//    return { _ in
//        return SampleType(-1.0 + 2.0 * (SampleType(arc4random_uniform(UInt32(Int16.max))) / SampleType(Int16.max)))
//    }
//}
//
//// MARK: Output
//
///// Read count samples from the signal starting at the specified index
//public func getOutput(signal: Signal, index: Int, count: Int) -> [SampleType] {
//    return [Int](index..<count).map { signal($0) }
//}
//
//// MARK: Filtering
//
//public typealias FilterType = Double
//public extension FilterType {
//    static let Epsilon = DBL_EPSILON
//}
//
//public struct PinkFilter {
//    // Filter coefficients from jos: https://ccrma.stanford.edu/~jos/sasp/Example_Synthesis_1_F_Noise.html
//    var b: [FilterType] = [0.049922035, -0.095993537, 0.050612699, -0.004408786];
//    var a: [FilterType] = [1.000000000, -2.494956002, 2.017265875, -0.522189400];
//    
//    // The filter's "memory"
//    public var w: [FilterType]! = nil
//    
//    public init() {}
//}
//
//var gFilt = PinkFilter()
//public func pinkFilter(x: Signal) -> Signal {
//    return filt(x, gFilt.b, gFilt.a, &gFilt.w)
//}
//
//public func filt(x: Signal, var b: [FilterType], var a: [FilterType], inout w: [FilterType]!) -> Signal {
//    let N = a.count
//    let M = b.count
//    let MN = max(N, M)
//    let lw = MN - 1
//    
//    if w == nil {
//        w = [FilterType](count: lw, repeatedValue: 0)
//    }
//    assert(w.count == lw)
//
//    if b.count < MN {
//        b = b + zeros(MN-b.count)
//    }
//    if a.count < MN {
//        a = a + zeros(MN-a.count)
//    }
//    
//    let norm = a[0]
//    assert(norm > 0, "First element in A must be nonzero")
//    if fabs(norm - 1.0) > FilterType.Epsilon {
//        scale(&b, 1.0 / norm)
//    }
//    
//    if N > 1 {
//        // IIR Filter Case
//        if fabs(norm - 1.0) > FilterType.Epsilon {
//            scale(&a, 1.0 / norm)
//        }
//
//        return { i in
//            let xi = FilterType(x(i))
//            let y = w[0] + (b[0] * xi)
//            if ( lw > 1 ) {
//                for j in 0..<(lw - 1) {
//                    w[j] = w[j+1] + (b[j+1] * xi) - (a[j+1] * y)
//                }
//                w[lw-1] = (b[MN-1] * xi) - (a[MN-1] * y)
//            } else {
//                w[0] = (b[MN-1] * xi) - (a[MN-1] * y)
//            }
//            return SampleType(y)
//        }
//    } else {
//        // FIR Filter Case
//        if lw > 0 {
//            return { i in
//                let xi = FilterType(x(i))
//                let y = w[0] + b[0] * xi
//                if ( lw > 1 ) {
//                    for j in 0..<(lw - 1) {
//                        w[j] = w[j+1] + (b[j+1] * xi)
//                    }
//                    w[lw-1] = b[MN-1] * xi;
//                }
//                else {
//                    w[0] = b[1] * xi
//                }
//                return Float(y)
//            }
//        } else {
//            // No delay
//            return { i in Float(Double(x(i)) * b[0]) }
//        }
//    }
//}


