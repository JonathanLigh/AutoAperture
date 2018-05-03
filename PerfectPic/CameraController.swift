//
//  CameraController.swift
//  PerfectPic
//
//  Created by Jonathan Ligh on 4/9/18.
//  Copyright © 2018 JonathanLigh. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

class CameraController: NSObject {
    var captureSession: AVCaptureSession?
    var frontCamera: AVCaptureDevice?
    var rearCamera: AVCaptureDevice?
    var currentCaptureDevice: AVCaptureDevice?
    var currentCameraPosition: CameraPosition?
    var frontCameraInput: AVCaptureDeviceInput?
    var rearCameraInput: AVCaptureDeviceInput?
    var photoOutput: AVCapturePhotoOutput?
    var output: AVCaptureVideoDataOutput?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var flashMode = AVCaptureDevice.FlashMode.off
    var photoCaptureCompletionBlock: ((UIImage?, Error?) -> Void)?
    let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: [CIDetectorAccuracy : CIDetectorAccuracyHigh])
    let faceView: FaceView = {
        let faceView = FaceView()
        faceView.setup()
        
        return faceView
    }()
    var currentComposition: Composition?
    var autoCaptureInProgress: Bool = false
    var captureTimer = Timer()
    var timeLeft = 4
}

extension CameraController {
    func prepare(completionHandler: @escaping (Error?) -> Void) {
        func createCaptureSession() {
            self.captureSession = AVCaptureSession()
            self.captureSession?.sessionPreset = AVCaptureSession.Preset.photo
        }
        
        func configureCaptureDevices() throws {
            
            let session = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .unspecified)
            let cameras = session.devices.compactMap { $0 }
            guard !cameras.isEmpty else { throw CameraControllerError.noCamerasAvailable }
            
            for camera in cameras {
                if camera.position == .front {
                    self.frontCamera = camera
                }
                
                if camera.position == .back {
                    self.rearCamera = camera
                    
                    try camera.lockForConfiguration()
                    camera.focusMode = .continuousAutoFocus
                    camera.unlockForConfiguration()
                }
            }
        }
        
        func configureDeviceInputs() throws {
            guard let captureSession = self.captureSession else { throw CameraControllerError.captureSessionIsMissing }
            
            if let rearCamera = self.rearCamera {
                self.rearCameraInput = try AVCaptureDeviceInput(device: rearCamera)
                
                if captureSession.canAddInput(self.rearCameraInput!) { captureSession.addInput(self.rearCameraInput!) }
                
                self.currentCameraPosition = .rear
                self.currentCaptureDevice = rearCamera
            }
                
            else if let frontCamera = self.frontCamera {
                self.frontCameraInput = try AVCaptureDeviceInput(device: frontCamera)
                
                if captureSession.canAddInput(self.frontCameraInput!) { captureSession.addInput(self.frontCameraInput!) }
                else { throw CameraControllerError.inputsAreInvalid }
                
                self.currentCameraPosition = .front
                self.currentCaptureDevice = frontCamera
            }
                
            else { throw CameraControllerError.noCamerasAvailable }
        }
        
        func configurePhotoOutput() throws {
            guard let captureSession = self.captureSession else { throw CameraControllerError.captureSessionIsMissing }
            
            self.photoOutput = AVCapturePhotoOutput()
            self.photoOutput!.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey : AVVideoCodecType.jpeg])], completionHandler: nil)

            if captureSession.canAddOutput(self.photoOutput!) {
                captureSession.addOutput(self.photoOutput!)
            }
            
            self.output = AVCaptureVideoDataOutput()
            self.output?.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String : NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            
            self.output?.alwaysDiscardsLateVideoFrames = true
            
            if captureSession.canAddOutput(self.output!) {
                captureSession.addOutput(self.output!)
            }
            
            captureSession.commitConfiguration()
            
            let queue = DispatchQueue(label: "output.queue")
            self.output?.setSampleBufferDelegate(self, queue: queue)
            
            captureSession.startRunning()
        }
        
        DispatchQueue(label: "prepare").async {
            do {
                createCaptureSession()
                try configureCaptureDevices()
                try configureDeviceInputs()
                try configurePhotoOutput()
            }
                
            catch {
                DispatchQueue.main.async {
                    completionHandler(error)
                }
                
                return
            }
            
            DispatchQueue.main.async {
                completionHandler(nil)
            }
        }
    }
    
    func displayPreview(on view: UIView) throws {
        guard let captureSession = self.captureSession, captureSession.isRunning else { throw CameraControllerError.captureSessionIsMissing }
        
        self.previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.previewLayer?.connection?.videoOrientation = .portrait
        
        view.layer.insertSublayer(self.previewLayer!, at: 0)
        self.previewLayer?.frame = view.frame
    }
    
    func switchCameras() throws {
        guard let currentCameraPosition = currentCameraPosition, let captureSession = self.captureSession, captureSession.isRunning else { throw CameraControllerError.captureSessionIsMissing }
        
        captureSession.beginConfiguration()
        
        func switchToFrontCamera() throws {
            
            guard let rearCameraInput = self.rearCameraInput, captureSession.inputs.contains(rearCameraInput),
                let frontCamera = self.frontCamera else { throw CameraControllerError.invalidOperation }
            
            self.frontCameraInput = try AVCaptureDeviceInput(device: frontCamera)
            
            captureSession.removeInput(rearCameraInput)
            
            if captureSession.canAddInput(self.frontCameraInput!) {
                captureSession.addInput(self.frontCameraInput!)
                
                self.currentCameraPosition = .front
            }
                
            else {
                throw CameraControllerError.invalidOperation
            }
        }
        
        func switchToRearCamera() throws {
            
            guard let frontCameraInput = self.frontCameraInput, captureSession.inputs.contains(frontCameraInput),
                let rearCamera = self.rearCamera else { throw CameraControllerError.invalidOperation }
            
            self.rearCameraInput = try AVCaptureDeviceInput(device: rearCamera)
            
            captureSession.removeInput(frontCameraInput)
            
            if captureSession.canAddInput(self.rearCameraInput!) {
                captureSession.addInput(self.rearCameraInput!)
                
                self.currentCameraPosition = .rear
                
            }
                
            else { throw CameraControllerError.invalidOperation }
        }
        
        switch currentCameraPosition {
        case .front:
            try switchToRearCamera()
            
        case .rear:
            try switchToFrontCamera()
        }
        
        captureSession.commitConfiguration()
        
        
    }
    
    func focusOnPoint(point: CGPoint, device: AVCaptureDevice?) {
        if let device = device {
            if device.isFocusPointOfInterestSupported {
                do {
                    try device.lockForConfiguration()
                    
                    device.focusPointOfInterest = point
                    device.focusMode = .autoFocus
                    device.exposurePointOfInterest = point
                    device.exposureMode = AVCaptureDevice.ExposureMode.continuousAutoExposure
                    device.unlockForConfiguration()
                } catch {
                    // do nothing
                }
            }
        }
    }
    
    func captureImage(completion: @escaping (UIImage?, Error?) -> Void) {
        guard let captureSession = captureSession, captureSession.isRunning else { completion(nil, CameraControllerError.captureSessionIsMissing); return }
        
        let settings = AVCapturePhotoSettings()
        settings.flashMode = self.flashMode
        self.photoOutput?.capturePhoto(with: settings, delegate: self)
        self.photoCaptureCompletionBlock = completion
    }
    
    
    // This method is called every second to decrement the timeleft variable and take a picture when timeLeft = 0
    // has @objc so it can be refered to in timer context
    @objc func countDown() {
        // if all the rects in getGoldenRegions have the center point of faceView in them then true else false\
        var isFaceInPicZone = false
        // self.currentComposition?.getGoldenRegions(frame: (self.previewLayer?.frame)!)
        if let regions = (self.currentComposition?.getGoldenRegions(frame: (self.previewLayer?.frame)!)) {
            for region in regions {
                // if middle of face frame in is in golden region
                if region.contains(CGPoint(x: self.faceView.frame.midX, y: self.faceView.frame.midY)) {
                    isFaceInPicZone = true
                    // exit loop and proceed
                    break
                }
            }
        }

        if self.faceView.eyesOpen && isFaceInPicZone  {
            // frame becomes green when in a pic taking zone
            self.faceView.layer.borderColor = UIColor.green.withAlphaComponent(0.7).cgColor
            self.timeLeft -= 1
            self.faceView.faceLabel.text = String(self.timeLeft)
            // update text on timer
            if self.timeLeft == 0 {
                // change timer label to done
                self.faceView.faceLabel.text = String("Photo Taken and Saved")
                // focus on center of face frame
                self.focusOnPoint(point: CGPoint(x: self.faceView.frame.midX, y: self.faceView.frame.midY), device: self.currentCaptureDevice)
                // takes a picture of the screen and saves it to photos
                self.captureImage { (image, error) in
                    guard let image = image else {
                        print(error ?? "Image capture error")
                        return
                    }
                    
                    try? PHPhotoLibrary.shared().performChangesAndWait {
                        PHAssetChangeRequest.creationRequestForAsset(from: image)
                    }
                }
                
                // invalidate the current timer
                self.captureTimer.invalidate()
                // instatiate a new timer
                self.captureTimer = Timer()
                // reset timer
                self.timeLeft = 4
                self.faceView.faceLabel.text = String(self.timeLeft)
                // set this to false so another autoCapture session can begin again
                self.autoCaptureInProgress = false
            }
        } else {
            // set frame back to red
            self.faceView.layer.borderColor = UIColor.red.withAlphaComponent(0.7).cgColor
            // else reset timer
            self.timeLeft = 4
            self.faceView.faceLabel.text = String("Face Not in Auto Capture Zone or Eyes Not Visible")
        }
    }
}

extension CameraController: AVCapturePhotoCaptureDelegate {
    public func photoOutput(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Swift.Error?) {
        if let error = error { self.photoCaptureCompletionBlock?(nil, error) }

        else if let buffer = photoSampleBuffer,
            let data = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: buffer, previewPhotoSampleBuffer: nil),
            let image = UIImage(data: data) {

            
            self.photoCaptureCompletionBlock?(image, nil)
        }

        else {
            self.photoCaptureCompletionBlock?(nil, CameraControllerError.unknown)
        }
    }
}

extension CameraController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        let attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate)
        
        let ciImage = CIImage(cvImageBuffer: pixelBuffer!, options: attachments as! [String : Any]?)
        let ciImageSize = ciImage.extent.size
        var transform = CGAffineTransform(scaleX: 1, y: -1)
        transform = transform.translatedBy(x: 0, y: -ciImageSize.height)
        
        let options: [String : Any] = [CIDetectorImageOrientation: exifOrientation(orientation: UIDevice.current.orientation),
                                       CIDetectorEyeBlink: true,
                                       CIDetectorFocalLength: true]
        
        let allFeatures = faceDetector?.features(in: ciImage, options: options)
        
        let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer)
        let cleanAperture = CMVideoFormatDescriptionGetCleanAperture(formatDescription!, false)
        
        guard let faces = allFeatures else { return }
        
        for face in faces as! [CIFaceFeature] {
            let faceViewBounds = face.bounds
            
            let faceRect = calculateFaceRect(facePosition: face.mouthPosition, faceBounds: faceViewBounds, clearAperture: cleanAperture)
            update(with: faceRect, eyesOpen: face.hasLeftEyePosition && face.hasRightEyePosition)
        }
        
        autoCaptureImage()
        if faces.count == 0 {
            DispatchQueue.main.async {
                self.faceView.alpha = 0.0
            }
        }
    }
    
    func exifOrientation(orientation: UIDeviceOrientation) -> Int {
        switch orientation {
        case .portraitUpsideDown:
            return 8
        case .landscapeRight:
            return 3
        case .landscapeLeft:
            return 1
        default:
            return 6
        }
    }
    
    func videoBox(frameSize: CGSize, apertureSize: CGSize) -> CGRect {
        let apertureRatio = apertureSize.height / apertureSize.width
        let viewRatio = frameSize.width / frameSize.height
        
        var size = CGSize.zero
        
        if (viewRatio > apertureRatio) {
            size.width = frameSize.width
            size.height = apertureSize.width * (frameSize.width / apertureSize.height)
        } else {
            size.width = apertureSize.height * (frameSize.height / apertureSize.width)
            size.height = frameSize.height
        }
        
        var videoBox = CGRect(origin: .zero, size: size)
        
        if (size.width < frameSize.width) {
            videoBox.origin.x = (frameSize.width - size.width) / 2.0
        } else {
            videoBox.origin.x = (size.width - frameSize.width) / 2.0
        }
        
        if (size.height < frameSize.height) {
            videoBox.origin.y = (frameSize.height - size.height) / 2.0
        } else {
            videoBox.origin.y = (size.height - frameSize.height) / 2.0
        }
        
        return videoBox
    }
    
    func calculateFaceRect(facePosition: CGPoint, faceBounds: CGRect, clearAperture: CGRect) -> CGRect {
        let parentFrameSize = self.previewLayer!.frame.size
        let previewBox = videoBox(frameSize: parentFrameSize, apertureSize: clearAperture.size)
        
        var faceRect = faceBounds
        
        swap(&faceRect.size.width, &faceRect.size.height)
        swap(&faceRect.origin.x, &faceRect.origin.y)
        
        let widthScaleBy = previewBox.size.width / clearAperture.size.height
        let heightScaleBy = previewBox.size.height / clearAperture.size.width
        
        faceRect.size.width *= widthScaleBy
        faceRect.size.height *= heightScaleBy
        faceRect.origin.x *= widthScaleBy
        faceRect.origin.y *= heightScaleBy
        
        faceRect = faceRect.offsetBy(dx: 0.0, dy: previewBox.origin.y)
        let frame = CGRect(x: parentFrameSize.width - faceRect.origin.x - faceRect.size.width / 2.0 - previewBox.origin.x / 2.0, y: faceRect.origin.y, width: faceRect.width, height: faceRect.height)
        
        return frame
    }
}

extension CameraController {
    //  updates facial rectangle from AVCaptureVideoDataOutputSampleBufferDelegate
    func update(with faceRect: CGRect, eyesOpen: Bool) {
        DispatchQueue.main.async {
            
            UIView.animate(withDuration: 0.2) {
                self.faceView.alpha = 0.5
                self.faceView.frame = faceRect
                self.faceView.eyesOpen = eyesOpen
            }
        }
    }
    
    // async takes photo after facial rectangle is within guidline's "golden region"
    func autoCaptureImage() {
        if (!self.autoCaptureInProgress) {
            // block this off before asynchronicity is begun by setting autoCaptureInProgress to true
            self.autoCaptureInProgress = true
            DispatchQueue.main.async {
                // instatiate timer
                self.captureTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(CameraController.countDown), userInfo: nil, repeats: true)
            }
        }
    }
}

extension CameraController {
    enum CameraControllerError: Swift.Error {
        case captureSessionAlreadyRunning
        case captureSessionIsMissing
        case inputsAreInvalid
        case invalidOperation
        case noCamerasAvailable
        case unknown
    }
    
    public enum CameraPosition {
        case front
        case rear
    }
}

class FaceView: UIView {
    
    lazy var faceLabel: UILabel = {
        let faceLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.frame.size.width/2, height: self.frame.size.height/2))
        faceLabel.textAlignment = .center
        faceLabel.font = UIFont(name: faceLabel.font.fontName, size: 20)
        faceLabel.textColor = UIColor.white
        faceLabel.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        
        return faceLabel
    }()
    
    var eyesOpen: Bool = false
    
    func setup() {
        layer.borderColor = UIColor.red.withAlphaComponent(0.7).cgColor
        layer.borderWidth = 5.0
        
        addSubview(faceLabel)
    }
    
    override var frame: CGRect {
        didSet(newFrame) {
            var faceFrame = faceLabel.frame
            faceFrame = CGRect(x: 0, y: newFrame.size.height, width: newFrame.size.width, height: newFrame.size.height/4)
            faceLabel.frame = faceFrame
        }
    }
}
