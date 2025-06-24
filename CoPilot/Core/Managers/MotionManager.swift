//
//  MotionManager.swift
//  CoPilot
//
//  Created by Zachary Farmer on 6/23/25.
//


import Foundation
import CoreMotion
import Combine

final class MotionManager: NSObject, ObservableObject {
    static let shared = MotionManager()
    
    private let motionManager = CMMotionManager()
    private let queue = OperationQueue()
    
    @Published var isVehicleMotionDetected: Bool = false
    @Published var currentActivity: CMMotionActivity?
    @Published var accelerometerData: CMAccelerometerData?
    
    private var motionHistory: [CMAccelerometerData] = []
    private let motionThreshold = 0.3 // Adjust based on testing
    private let historySize = 50
    
    override init() {
        super.init()
        configureMotionManager()
    }
    
    private func configureMotionManager() {
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInteractive
    }
    
    func startMotionUpdates() {
        guard motionManager.isAccelerometerAvailable else { return }
        
        motionManager.accelerometerUpdateInterval = 0.1
        motionManager.startAccelerometerUpdates(to: queue) { [weak self] data, error in
            guard let data = data, error == nil else { return }
            
            DispatchQueue.main.async {
                self?.processAccelerometerData(data)
            }
        }
        
        // Start activity updates if available
        if CMMotionActivityManager.isActivityAvailable() {
            let activityManager = CMMotionActivityManager()
            activityManager.startActivityUpdates(to: queue) { [weak self] activity in
                DispatchQueue.main.async {
                    self?.currentActivity = activity
                }
            }
        }
    }
    
    private func processAccelerometerData(_ data: CMAccelerometerData) {
        accelerometerData = data
        motionHistory.append(data)
        
        if motionHistory.count > historySize {
            motionHistory.removeFirst()
        }
        
        // Detect vehicle-like motion patterns
        isVehicleMotionDetected = detectVehicleMotion()
    }
    
    private func detectVehicleMotion() -> Bool {
        guard motionHistory.count >= 10 else { return false }
        
        // Calculate motion variance (vehicle motion is more consistent than walking)
        let recentData = Array(motionHistory.suffix(10))
        let xValues = recentData.map { $0.acceleration.x }
        let yValues = recentData.map { $0.acceleration.y }
        let zValues = recentData.map { $0.acceleration.z }
        
        let xVariance = calculateVariance(xValues)
        let yVariance = calculateVariance(yValues)
        let zVariance = calculateVariance(zValues)
        
        // Vehicle motion typically has lower variance than walking
        let totalVariance = xVariance + yVariance + zVariance
        return totalVariance < motionThreshold
    }
    
    private func calculateVariance(_ values: [Double]) -> Double {
        let mean = values.reduce(0, +) / Double(values.count)
        let squaredDifferences = values.map { pow($0 - mean, 2) }
        return squaredDifferences.reduce(0, +) / Double(values.count)
    }
    
    func stopMotionUpdates() {
        motionManager.stopAccelerometerUpdates()
    }
}