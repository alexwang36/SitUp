// This file should be placed in: YourFlutterApp/ios/Runner/PoseDetectionPlugin.swift

import Flutter
import UIKit
import MediaPipeTasksVision
import AVFoundation
import CoreImage

public class SwiftPoseDetectionPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    private var poseLandmarkerService: PoseLandmarkerService?
    private var cameraFeedService: CameraFeedService?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "pose_detection", binaryMessenger: registrar.messenger())
        let instance = SwiftPoseDetectionPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        
        // Event channel for streaming results
        let eventChannel = FlutterEventChannel(name: "pose_detection_stream", binaryMessenger: registrar.messenger())
        eventChannel.setStreamHandler(instance)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            initializePoseDetector(arguments: call.arguments as? [String: Any], result: result)
        case "detectImage":
            detectImage(arguments: call.arguments as? [String: Any], result: result)
        case "startCameraStream":
            startCameraStream(result: result)
        case "stopCameraStream":
            stopCameraStream(result: result)
        case "dispose":
            dispose(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func initializePoseDetector(arguments: [String: Any]?, result: @escaping FlutterResult) {
        guard let args = arguments else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "Arguments required", details: nil))
            return
        }
        
        let modelPath = args["modelPath"] as? String ?? Bundle.main.path(forResource: "pose_landmarker_lite", ofType: "task") ?? Bundle.main.path(forResource: "pose_landmarker_lite.task", ofType: nil)
        let numPoses = args["numPoses"] as? Int ?? 1
        let minDetectionConfidence = (args["minDetectionConfidence"] as? NSNumber)?.floatValue ?? 0.5
        let minPresenceConfidence = (args["minPresenceConfidence"] as? NSNumber)?.floatValue ?? 0.5
        let minTrackingConfidence = (args["minTrackingConfidence"] as? NSNumber)?.floatValue ?? 0.5
        let useGPU = args["useGPU"] as? Bool ?? false
        
        guard let path = modelPath else {
            result(FlutterError(code: "MODEL_NOT_FOUND", message: "Model file not found. Expected: pose_landmarker_lite.task", details: nil))
            return
        }
        
        print("[PoseDetectionPlugin] Using model path: \(path)")
        print("[PoseDetectionPlugin] File exists: \(FileManager.default.fileExists(atPath: path))")
        
        let delegate: PoseLandmarkerDelegate = useGPU ? .GPU : .CPU
        
        // Use stillImage mode for single image detection
        poseLandmarkerService = PoseLandmarkerService.stillImageLandmarkerService(
            modelPath: path,
            numPoses: numPoses,
            minPoseDetectionConfidence: minDetectionConfidence,
            minPosePresenceConfidence: minPresenceConfidence,
            minTrackingConfidence: minTrackingConfidence,
            delegate: delegate
        )
        
        if poseLandmarkerService != nil {
            result(true)
        } else {
            result(FlutterError(code: "INITIALIZATION_FAILED", message: "Failed to initialize pose detector", details: nil))
        }
    }
    
    private func detectImage(arguments: [String: Any]?, result: @escaping FlutterResult) {
        guard let args = arguments,
              let imagePath = args["imagePath"] as? String else {
            result(FlutterError(code: "INVALID_IMAGE", message: "Missing image path", details: nil))
            return
        }
        
        guard let image = UIImage(contentsOfFile: imagePath) else {
            result(FlutterError(code: "INVALID_IMAGE", message: "Could not load image from path: \(imagePath)", details: nil))
            return
        }
        
        guard let poseService = poseLandmarkerService else {
            result(FlutterError(code: "NOT_INITIALIZED", message: "Pose detector not initialized. Call initialize first.", details: nil))
            return
        }
        
        print("[PoseDetectionPlugin] Starting pose detection for image at: \(imagePath)")
        print("[PoseDetectionPlugin] Image size: \(image.size)")
        
        guard let resultBundle = poseService.detect(image: image) else {
            result(FlutterError(code: "DETECTION_FAILED", message: "Failed to detect pose - check console for detailed error", details: nil))
            return
        }
        
        print("[PoseDetectionPlugin] Detection successful")
        let detectionResult = convertToDictionary(resultBundle)
        result(detectionResult)
    }
    
    private func startCameraStream(result: @escaping FlutterResult) {
        result(FlutterError(code: "NOT_IMPLEMENTED", message: "Camera stream not yet implemented for Flutter plugin", details: "Use detectImage for now"))
    }
    
    private func stopCameraStream(result: @escaping FlutterResult) {
        cameraFeedService?.stopSession()
        cameraFeedService = nil
        result(true)
    }
    
    private func dispose(result: @escaping FlutterResult) {
        poseLandmarkerService = nil
        cameraFeedService = nil
        result(true)
    }
    
    // Convert ResultBundle to dictionary for Flutter
    private func convertToDictionary(_ resultBundle: ResultBundle) -> [String: Any] {
        var dict: [String: Any] = [:]
        dict["inferenceTime"] = resultBundle.inferenceTime
        
        var results: [[String: Any]] = []
        for poseResult in resultBundle.poseLandmarkerResults {
            if let result = poseResult {
                results.append(convertPoseLandmarkerResult(result))
            }
        }
        dict["results"] = results
        dict["size"] = ["width": resultBundle.size.width, "height": resultBundle.size.height]
        
        return dict
    }
    
    private func convertPoseLandmarkerResult(_ result: PoseLandmarkerResult) -> [String: Any] {
        var dict: [String: Any] = [:]
        
        // Convert landmarks
        var landmarks: [[String: Any]] = []
        for landmarkGroup in result.landmarks {
            var groupDict: [String: Any] = [:]
            groupDict["landmarks"] = landmarkGroup.map { landmark in
                [
                    "x": landmark.x,
                    "y": landmark.y,
                    "z": landmark.z,
                    "visibility": landmark.visibility ?? 0,
                    "presence": landmark.presence ?? 0
                ]
            }
            landmarks.append(groupDict)
        }
        dict["landmarks"] = landmarks
        
        return dict
    }
    
    // FlutterStreamHandler implementation
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}

// MARK: - PoseLandmarkerServiceLiveStreamDelegate
extension SwiftPoseDetectionPlugin: PoseLandmarkerServiceLiveStreamDelegate {
    func poseLandmarkerService(_ poseLandmarkerService: PoseLandmarkerService, didFinishDetection result: ResultBundle?, error: Error?) {
        guard let eventSink = self.eventSink else { return }
        
        if let error = error {
            eventSink(FlutterError(code: "DETECTION_ERROR", message: error.localizedDescription, details: nil))
            return
        }
        
        if let result = result {
            let detectionResult = convertToDictionary(result)
            eventSink(detectionResult)
        }
    }
}

