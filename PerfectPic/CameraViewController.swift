//
//  CameraViewController.swift
//  PerfectPic
//
//  Created by Jonathan Ligh on 4/9/18.
//  Copyright © 2018 JonathanLigh. All rights reserved.
//

import UIKit
import Photos

class CameraViewController: UIViewController {
    let cameraController = CameraController()
    let compositionController = CompositionController()
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var compositionView: UIView!
    @IBOutlet weak var toggleFlashButton: UIButton!
    @IBOutlet weak var toggleCameraButton: UIButton!
    @IBAction func toggleFlash(_ sender: UIButton) {
        if cameraController.flashMode == .on {
            cameraController.flashMode = .off
//            toggleFlashButton.setImage(#imageLiteral(resourceName: "Flash Off Icon"), for: .normal)
        } else {
            cameraController.flashMode = .on
//            toggleFlashButton.setImage(#imageLiteral(resourceName: "Flash On Icon"), for: .normal)
        }
    }
    @IBAction func switchCameras(_ sender: UIButton) {
        do {
            try cameraController.switchCameras()
        }
            
        catch {
            print(error)
        }
        
        // This is where we will change the icon of the button
        switch cameraController.currentCameraPosition {
        case .some(.front): break
//            toggleCameraButton.setImage(#imageLiteral(resourceName: "Front Camera Icon"), for: .normal)
            
        case .some(.rear): break
//            toggleCameraButton.setImage(#imageLiteral(resourceName: "Rear Camera Icon"), for: .normal)
            
        case .none:
            return
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let screenSize = previewView.bounds.size
        if let touchPoint = touches.first {
            let x = touchPoint.location(in: previewView).y / screenSize.height
            let y = 1.0 - touchPoint.location(in: previewView).x / screenSize.width
            let focusPoint = CGPoint(x: x, y: y)
            
            if let device = cameraController.currentCaptureDevice {
                if device.isFocusPointOfInterestSupported {
                    do {
                        try device.lockForConfiguration()
                        
                        device.focusPointOfInterest = focusPoint
                        //device.focusMode = .continuousAutoFocus
                        device.focusMode = .autoFocus
                        //device.focusMode = .locked
                        device.exposurePointOfInterest = focusPoint
                        device.exposureMode = AVCaptureDevice.ExposureMode.continuousAutoExposure
                        device.unlockForConfiguration()
                    }
                    catch {
                        // just ignore
                    }
                }
            }
        }
    }
}

extension CameraViewController {
    override func viewDidLoad() {
        func configureCameraController() {
            cameraController.prepare {(error) in
                if let error = error {
                    print(error)
                }
                
                try? self.cameraController.displayPreview(on: self.previewView)
            }
        }
        
        func configureCompositionController() {
            self.compositionController.drawCurrentBezierPath(view: self.compositionView)
        }
        
        super.viewDidLoad()
        configureCameraController()
        configureCompositionController()
    }
    
    // captures image on screen
    func captureImage() {
        cameraController.captureImage { (image, error) in
            guard let image = image else {
                print(error ?? "Image capture error")
                return
            }
            
            try? PHPhotoLibrary.shared().performChangesAndWait {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
