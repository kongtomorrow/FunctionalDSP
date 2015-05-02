//
//  Utilities.swift
//  FunctionalDSP
//
//  Created by Christopher Liscio on 2015-03-09.
//  Copyright (c) 2015 SuperMegaUltraGroovy, Inc. All rights reserved.
//

import Foundation
import Accelerate

public protocol FloatOrDouble:FloatingPointType, FloatLiteralConvertible, IntegerLiteralConvertible {
    init(_ value: Double)
    init(_ value: Float)
    
    init<P:FloatOrDouble>(_ fp:P)
    
    func +(lhs: Self, rhs: Self) -> Self
    func -(lhs: Self, rhs: Self) -> Self
    func *(lhs: Self, rhs: Self) -> Self
    func /(lhs: Self, rhs: Self) -> Self
    
    func sin() -> Self
    func fabs() -> Self
    var doubleValue: Double { get }
    static func vDSP_vsmul(__vDSP_A: UnsafePointer<Self>, _ __vDSP_IA: vDSP_Stride, _ __vDSP_B: UnsafePointer<Self>, _ __vDSP_C: UnsafeMutablePointer<Self>, _ __vDSP_IC: vDSP_Stride, _ __vDSP_N: vDSP_Length)
    
    static var Epsilon : Self { get }
}

extension Double : FloatOrDouble {
    public func sin() -> Double {
        return Darwin.sin(self)
    }
    
    public func fabs() -> Double {
        return Darwin.fabs(self)
    }
    
    public var doubleValue: Double {
        return self
    }
    
    public static func vDSP_vsmul(__vDSP_A: UnsafePointer<Double>, _ __vDSP_IA: vDSP_Stride, _ __vDSP_B: UnsafePointer<Double>, _ __vDSP_C: UnsafeMutablePointer<Double>, _ __vDSP_IC: vDSP_Stride, _ __vDSP_N: vDSP_Length) {
        vDSP_vsmulD(__vDSP_A, __vDSP_IA, __vDSP_B, __vDSP_C, __vDSP_IC, __vDSP_N)
    }
    
    public static var Epsilon : Double {
        return DBL_EPSILON
    }
    
    public init<P:FloatOrDouble>(_ x:P) {
        self.init(x.doubleValue)
    }
}

extension Float : FloatOrDouble {
    public func sin() -> Float {
        return Darwin.sin(self)
    }
    
    public func fabs() -> Float {
        return Darwin.fabs(self)
    }
    
    public var doubleValue: Double {
        return Double(self)
    }
    
    public static func vDSP_vsmul(__vDSP_A: UnsafePointer<Float>, _ __vDSP_IA: vDSP_Stride, _ __vDSP_B: UnsafePointer<Float>, _ __vDSP_C: UnsafeMutablePointer<Float>, _ __vDSP_IC: vDSP_Stride, _ __vDSP_N: vDSP_Length) {
        vDSP_vsmul(__vDSP_A, __vDSP_IA, __vDSP_B, __vDSP_C, __vDSP_IC, __vDSP_N)
    }
    
    public static var Epsilon : Float {
        return FLT_EPSILON
    }
    
    public init<P:FloatOrDouble>(_ x:P) {
        self.init(x.doubleValue)
    }
}


func scal<P:FloatOrDouble>(inout x : [P], var a : P) {
    P.vDSP_vsmul(x, 1, &a, &x, 1, vDSP_Length(x.count))
}

func zeros<P:FloatOrDouble>(count: Int) -> [P] {
    return [P](count: count, repeatedValue: 0)
}

func sin<P:FloatOrDouble>(x:P)->P {
    return x.sin()
}

func fabs<P:FloatOrDouble>(x:P)->P {
    return x.fabs()
}
