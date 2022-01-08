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
private let photoPixelFormatType = kCVPixelFormatType_32BGRA
class PythonCameraControl: NSObject {
    
    private let captureSession = AVCaptureSession()
    private let photoSession = AVCaptureSession()
    
    var py_call: CameraApiPyCallback!
    
    var kivy_texture: PythonObject!
    
    var cameratypes: [AVCaptureDevice.DeviceType] = []
    var available_back_cams: [AVCaptureDevice.DeviceType] = []
    private var videoDevice: AVCaptureDevice!
    private var currentInputDevice: AVCaptureInput!
    private var videoConnection: AVCaptureConnection!
    private var inputCameras_back: [AVCaptureDevice] = []
    //private var audioConnection: AVCaptureConnection!
    private var camStreamRunning = false
    
    
    private var available_video_presets: JSON {
        let presets: [AVCaptureSession.Preset] = [.cif352x288, .iFrame960x540, .hd1280x720, .hd1920x1080, .hd4K3840x2160, .photo]
        let strings = presets.map {$0.rawValue}
        let myDict = strings.reduce(into: [String: String]()) {
            let key = $1.replacingOccurrences(of: "AVCaptureSessionPreset", with: "").replacingOccurrences(of: "iFrame", with: "")
            $0[ key ] = $1
        }
        return JSON(myDict)
    }
    
    override init() {
        super.init()
        InitCameraApi_Delegate(delegate: self)
        add_cameras()
        
    }
    
    func add_cameras() {
        
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
        camStreamRunning = true
    }
    
    private func stopCapture(){
        if !captureSession.isRunning {
            print("already stopped")
            return
        }
        camStreamRunning = false
        captureSession.stopRunning()
    }
    
    private func setupCaptureSession() {
        //let captureSession = AVCaptureSession()
        #if !targetEnvironment(simulator)
            let discoveryBack = AVCaptureDevice.DiscoverySession.init(deviceTypes: self.cameratypes, mediaType: .video, position: .back)
            let discoveryFront = AVCaptureDevice.DiscoverySession.init(deviceTypes: self.cameratypes, mediaType: .video, position: .front)
            self.inputCameras_back.append(contentsOf: discoveryBack.devices)
            //print("targets", available_back_cams.map({$0.rawValue}))
            let backs = discoveryBack.devices.map({$0.deviceType.rawValue.replacingOccurrences(of: "AVCaptureDeviceTypeBuiltIn", with: "")})
            let fronts = discoveryFront.devices.map({$0.deviceType.rawValue.replacingOccurrences(of: "AVCaptureDeviceTypeBuiltIn", with: "")})
            self.py_call.get_camera_types(front: fronts.asData(), back: backs.asData())
        
        
        if let captureDevice = AVCaptureDevice.default(for: .video) {
            videoDevice = captureDevice
            do {
                let input = try AVCaptureDeviceInput(device: captureDevice)
                currentInputDevice = input
                print("adding input", input)
                if captureSession.canAddInput(currentInputDevice) {
                    captureSession.addInput(currentInputDevice)
                }
                
            } catch let error {
                print("Failed to set input device with error: \(error)")
            }
        }
        photo_output.isHighResolutionCaptureEnabled = true
        photoSession.sessionPreset = .photo
        captureSession.sessionPreset = .photo
        
//        if photoSession.canAddInput(currentInputDevice) {
//            photoSession.addInput(currentInputDevice)
//        }
        
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
            
            captureSession.addOutput(photo_output)
//            guard captureSession.canAddOutput(photoOutput) else {fatalError()}
            
            videoConnection = videoDataOutput.connection(with: .video)
            //videoConnection.videoOrientation = .landscapeLeft
        }
        #endif
    }
    
    func capturePhoto() {

        let settings = AVCapturePhotoSettings(format: [kCVPixelBufferPixelFormatTypeKey as String : photoPixelFormatType] )
        let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
        let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
                               kCVPixelBufferWidthKey as String: 160,
                               kCVPixelBufferHeightKey as String: 160]
        settings.previewPhotoFormat = previewFormat
        photo_output.capturePhoto(with: settings, delegate: self)

    }
}

extension PythonCameraControl: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        //print("captureOutput",output)
        if camStreamRunning {
            if let imageBuffer = sampleBuffer.imageBuffer {
                let (data,data_size,width,height) = imageBuffer.TextureData()
                let pixel_data = PythonData(ptr: data,size: data_size)
                
                DispatchQueue.main.async { [self] in
                    py_call.returned_pixel_data(
                        pixel_data,
                        width,
                        height,
                        data_size,
                        self.kivy_texture
                    )
                }
            } // if camSreamRunning end
        }
        
    }
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
    }
}


extension PythonCameraControl: AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ output: AVCapturePhotoOutput, willBeginCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let previewbuffer = photo.previewPixelBuffer {
            let (buff, size, width, height) = previewbuffer.TextureData()
            //py_call.returned_thumbnail_data(PythonData(ptr: buff, size: size), width, height)
            py_call.returned_thumbnail_data(PythonData(ptr: buff, size: size), width, height)
        }
        if let pixelbuffer = photo.pixelBuffer {
            
            let (buff, size, width, height) = pixelbuffer.TextureData()
            py_call.returned_image_data(PythonData(ptr: buff, size: size), width, height)
        }
        
    }
    
}


extension PythonCameraControl: CameraApi_Delegate {
    func take_multi_photo_with_preset(presets: [CameraPreset]) {
        
    }
    
    func take_photo_with_preset(preset: CameraPreset) {
        preset.x
    }
    
    func send2_(image: Data) {
        
    }
    
    func set_CameraApi_Callback(callback: CameraApiPyCallback) {
        py_call = callback
        setupCaptureSession()
        //swapRootViewController(pythonmain: PythonMain.shared)

        py_call.set_preview_presets(presets: try! available_video_presets.rawData())
        
        
        swap_sdl_viewcontroller()
    }
    
    func encode_image(image: Data) {
        
    }

    func send_(image: [UInt8]) {

    }



    func auto_exposure(state: Bool) {
        try! videoDevice.lockForConfiguration()
        if state {
            videoDevice.exposureMode = .locked
        } else {
            videoDevice.exposureMode = .autoExpose
        }

        videoDevice.unlockForConfiguration()


    }

    func set_exposure(value: Double) {
        try! videoDevice.lockForConfiguration()
        videoDevice.setExposureTargetBias(Float(value)) { (time) in
            print(time)
        }
        videoDevice.unlockForConfiguration()
    }

    func zoom_camera(zoom: Double) {
        try! videoDevice.lockForConfiguration()
        videoDevice.videoZoomFactor = CGFloat(zoom)
        videoDevice.unlockForConfiguration()
    }

    func set_focus_point(x: Double, y: Double) {
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



    func set_preview_texture(tex: PythonObject) {
        kivy_texture = tex
    }

    func select_preview_preset(preset: String) {

        DispatchQueue.global().async {

            if self.captureSession.isRunning {
                self.stopCapture()

                //DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 , execute: {
                    self.captureSession.sessionPreset = .init(rawValue: preset)
                    self.startCapture()
                //})
            } else {
                self.captureSession.sessionPreset = .init(rawValue: preset)

            }
        }


    }

    func start_capture(mode: String) {
        self.startCapture()
    }

    func stop_capture(mode: String) {
        self.stopCapture()
    }

    func set_camera_mode(mode: String) {

    }

    func select_camera(index: Int) {
        captureSession.removeInput(currentInputDevice)
        //photoSession.removeInput(currentInputDevice)
        videoDevice = inputCameras_back[index]
        currentInputDevice = try! AVCaptureDeviceInput(device: videoDevice)
        captureSession.addInput(currentInputDevice)
        //photoSession.addInput(currentInputDevice)
        //
    }

    func take_photo() {
        capturePhoto()
    }

    func take_multi_photo(count: Int) {

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
