//
//  CameraControl.swift
//  camera_api
//
//  Created by MusicMaker on 25/11/2021.
//

import Foundation
import AVFoundation
import SwiftyJSON


private let photo_output = AVCapturePhotoOutput()

class PythonCamaeraControl: NSObject {
    
    private let captureSession = AVCaptureSession()
    private let photoSession = AVCaptureSession()
    
    var py_call: CameraApiCallbacks!
    
    var kivy_texture: PythonObject!
    
    var cameratypes: [AVCaptureDevice.DeviceType] = []
    var available_back_cams: [AVCaptureDevice.DeviceType] = []
    private var videoDevice: AVCaptureDevice!
    private var currentInputDevice: AVCaptureInput!
    private var videoConnection: AVCaptureConnection!
    private var inputCameras_back: [AVCaptureDevice] = []
    //private var audioConnection: AVCaptureConnection!
    
    
    private var available_video_presets: JSON {
        let presets: [AVCaptureSession.Preset] = [.cif352x288, .iFrame960x540, .hd1280x720, .hd1920x1080, .hd4K3840x2160]
        let strings = presets.map {$0.rawValue}
        let myDict = strings.reduce(into: [String: String]()) {
            let key = $1.replacingOccurrences(of: "AVCaptureSessionPreset", with: "").replacingOccurrences(of: "iFrame", with: "")
            $0[ key ] = $1
        }
        return JSON(myDict)
    }
    
    override init() {
        super.init()
        InitCameraApi_Delegate(self)
        add_cemeras()
        
    }
    
    func add_cemeras() {
        
        cameratypes.append(contentsOf: [.builtInDualCamera, .builtInTelephotoCamera, .builtInWideAngleCamera, .builtInMicrophone])
        
        if #available(iOS 13, *) {
            cameratypes.append(contentsOf: [.builtInDualWideCamera, .builtInTripleCamera, .builtInTrueDepthCamera, .builtInUltraWideCamera])
        }
    }
    
    private func startCapture(){
        if captureSession.isRunning {
            print("already running")
            return
        }
        captureSession.startRunning()
    }
    
    private func stopCapture(){
        if !captureSession.isRunning {
            print("already stopped")
            return
        }
        captureSession.stopRunning()
    }
    
    private func setupCaptureSession() {
        //let captureSession = AVCaptureSession()
        let discoveryBack = AVCaptureDevice.DiscoverySession.init(deviceTypes: cameratypes, mediaType: .video, position: .back)
        let discoveryFront = AVCaptureDevice.DiscoverySession.init(deviceTypes: cameratypes, mediaType: .video, position: .front)
        inputCameras_back.append(contentsOf: discoveryBack.devices)
        //print("targets", available_back_cams.map({$0.rawValue}))
        let backs = discoveryBack.devices.map({$0.deviceType.rawValue.replacingOccurrences(of: "AVCaptureDeviceTypeBuiltIn", with: "")}).asJsonBytes()!
        let fronts = discoveryFront.devices.map({$0.deviceType.rawValue.replacingOccurrences(of: "AVCaptureDeviceTypeBuiltIn", with: "")}).asJsonBytes()!
        py_call.get_camera_types(fronts,backs)
        if let captureDevice = AVCaptureDevice.default(for: .video) {
            videoDevice = captureDevice
            do {
                let input = try AVCaptureDeviceInput(device: captureDevice)
                currentInputDevice = input
                print("adding input", input)
                if captureSession.canAddInput(currentInputDevice) {
                    captureSession.addInput(currentInputDevice)
                }
                if photoSession.canAddInput(currentInputDevice) {
                    photoSession.addInput(currentInputDevice)
                }
                
            } catch let error {
                print("Failed to set input device with error: \(error)")
            }
        }
        
        do {
            let videoDataOutput = AVCaptureVideoDataOutput()
            videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable as! String: NSNumber(value: kCVPixelFormatType_32BGRA)]
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            
            
            let queue = DispatchQueue(label: "org.kivy.videosamplequeue")
            videoDataOutput.setSampleBufferDelegate(self, queue: queue)
            
            guard captureSession.canAddOutput(videoDataOutput) else {
                fatalError()
            }
            captureSession.addOutput(videoDataOutput)
            //photoSession.addOutput(photoOutput)
//            guard captureSession.canAddOutput(photoOutput) else {fatalError()}
            
            videoConnection = videoDataOutput.connection(with: .video)
        }
    }
    
    func capturePhoto() {

        let settings = AVCapturePhotoSettings()
        
        let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
        let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
                               kCVPixelBufferWidthKey as String: 160,
                               kCVPixelBufferHeightKey as String: 160]
        settings.previewPhotoFormat = previewFormat
        photo_output.capturePhoto(with: settings, delegate: self)

    }
}

extension PythonCamaeraControl: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        //print("captureOutput",output)
        
        
        if let imageBuffer = sampleBuffer.imageBuffer {
            let (data,data_size,width,height) = imageBuffer.TextureData()
            
            DispatchQueue.main.async {
                self.py_call.returned_pixel_data(
                    PythonData(ptr: data,size: data_size),
                    width,
                    height,
                    width * height * 4,
                    self.kivy_texture
                )
            }
    
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
    }
}


extension PythonCamaeraControl: AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ output: AVCapturePhotoOutput, willBeginCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        print("didFinishProcessingPhoto",photo.pixelBuffer!.TextureData())
        if let previewbuffer = photo.previewPixelBuffer {
            let (buff, size, width, height) = previewbuffer.TextureData()
            //py_call.returned_thumbnail_data(PythonData(ptr: buff, size: size), width, height)
        }
        
        if let pixelbuffer = photo.pixelBuffer {
            let (buff, size, width, height) = pixelbuffer.TextureData()
            print(size,width,height)
            //py_call.returned_image_data(PythonData(ptr: buff, size: size), width, height)
        }
        
    }
    
}

extension PythonCamaeraControl: CameraApi_Delegate {
    
    func auto_exposure(_ state: Bool) {
        try! videoDevice.lockForConfiguration()
        if state {
            videoDevice.exposureMode = .locked
        } else {
            videoDevice.exposureMode = .autoExpose
        }
        
        videoDevice.unlockForConfiguration()
        
        
    }
    
    func set_exposure(_ value: Double) {
        try! videoDevice.lockForConfiguration()
        videoDevice.setExposureTargetBias(Float(value)) { (time) in
            print(time)
        }
        videoDevice.unlockForConfiguration()
    }
    
    func zoom_camera(_ zoom: Double) {
        try! videoDevice.lockForConfiguration()
        videoDevice.videoZoomFactor = CGFloat(zoom)
        videoDevice.unlockForConfiguration()
    }
    
    func set_focus_point(_ x: Double, _ y: Double) {
        let focus_point = CGPoint(x: x, y: 1 - y)
        print(focus_point)
        print(videoDevice.isFocusPointOfInterestSupported)
        try! videoDevice.lockForConfiguration()
        
        videoDevice.focusPointOfInterest = focus_point
        videoDevice.exposurePointOfInterest = focus_point
        videoDevice.focusMode = .autoFocus
        videoDevice.exposureMode = .autoExpose
        videoDevice.unlockForConfiguration()
    }
    
    
    func set_CameraApi_Callback(_ callback: CameraApiCallbacks) {
        py_call = callback
        setupCaptureSession()
        
        
        py_call.set_preview_presets(available_video_presets.rawBytes()!)
    }
    func set_preview_texture(_ tex: PythonObject) {
        kivy_texture = tex
    }

    func select_preview_preset(_ preset: PythonString) {
        if captureSession.isRunning {
            stopCapture()
            let _preset = preset.string
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 , execute: {
                self.captureSession.sessionPreset = .init(rawValue: _preset)
                self.startCapture()
            })
        } else {
            captureSession.sessionPreset = .init(rawValue: preset.string)
            
        }
        
    }
    
    func start_capture(_ mode: PythonString) {
        self.startCapture()
    }
    
    func stop_capture(_ mode: PythonString) {
        self.stopCapture()
    }
    
    func set_camera_mode(_ mode: PythonString) {
        
    }
    
    func select_camera(_ index: Int) {
        captureSession.removeInput(currentInputDevice)
        videoDevice = inputCameras_back[index]
        currentInputDevice = try! AVCaptureDeviceInput(device: videoDevice)
        captureSession.addInput(currentInputDevice)
        //
    }
    
    func take_photo() {
        
    }
    
    func take_multi_photo(_ count: Int) {
        
    }
    
    
}


//
//private func openCamera() {
//        switch AVCaptureDevice.authorizationStatus(for: .video) {
//        case .authorized: // the user has already authorized to access the camera.
//            self.setupCaptureSession()
//
//        case .notDetermined: // the user has not yet asked for camera access.
//            AVCaptureDevice.requestAccess(for: .video) { (granted) in
//                if granted { // if user has granted to access the camera.
//                    print("the user has granted to access the camera")
//                    DispatchQueue.main.async {
//                        self.setupCaptureSession()
//                    }
//                } else {
//                    print("the user has not granted to access the camera")
//                    self.handleDismiss()
//                }
//            }
//
//        case .denied:
//            print("the user has denied previously to access the camera.")
//            self.handleDismiss()
//
//        case .restricted:
//            print("the user can't give camera access due to some restriction.")
//            self.handleDismiss()
//
//        default:
//            print("something has wrong due to we can't access the camera.")
//            self.handleDismiss()
//        }
//    }
