//
//  MTLExt.swift
//  MTLCanvas
//
//  Created by Demian Nezhdanov on 19/07/2025.
//

import MetalKit

public func doAfter(_ delay: Double, _ closure: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: closure)
}
public func doMainSync(_ closure: @escaping () -> Void) {
    DispatchQueue.main.sync(execute: closure)
}
public func doMain(_ closure: @escaping () -> Void) {
    DispatchQueue.main.async(execute: closure)
}
public func doGlobal( qos: DispatchQoS.QoSClass,_ closure: @escaping () -> Void) {
    DispatchQueue.global(qos: qos).async(execute: closure)
}
public func doGlobalSync( qos: DispatchQoS.QoSClass,_ closure: @escaping () -> Void) {
    DispatchQueue.global(qos: qos).sync(execute: closure)
}
extension Float {
    func clamp(to range: ClosedRange<Float>) -> Float {
        return min(max(self, range.lowerBound), range.upperBound)
    }
}
extension CGFloat {
    func clamp(to range: ClosedRange<CGFloat>) -> CGFloat {
        return Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
