//
//  ViewController.swift
//  Flower
//
//  Created by Andre Elandra on 27/07/20.
//  Copyright © 2020 Andre Elandra. All rights reserved.
//

import UIKit
import CoreML
import Vision
import SDWebImage
import ColorThiefSwift

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var cameraView: UIImageView!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    private var imagePicker = UIImagePickerController()
    private var flowerManager = FlowerManager()
    private var pickedImage: UIImage?
    private var i = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        flowerManager.delegate = self
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .camera
        descriptionLabel.sizeToFit()
        descriptionLabel.adjustsFontSizeToFitWidth = true
        setupNavBar(bgColor: #colorLiteral(red: 0.1592048705, green: 0.7238836884, blue: 0.4517703056, alpha: 1))
    }
    
    func setupNavBar(bgColor: UIColor) {
        guard let navBar = navigationController?.navigationBar else { fatalError("Navigation bar does not exist.") }
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.backgroundColor = bgColor
    
        navBar.standardAppearance = navBarAppearance
        navBar.compactAppearance = navBarAppearance
        navBar.scrollEdgeAppearance = navBarAppearance
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let userPickedImage = info[.editedImage] as? UIImage {
            guard let ciImage = CIImage(image: userPickedImage) else { fatalError() }
            detect(image: ciImage)
            
            pickedImage = userPickedImage
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    func detect(image: CIImage) {
        
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("Loading CoreML Model failed.")
        }
        let request = VNCoreMLRequest(model: model) { (request, error) in
            if let e = error {
                print("Failed request: \(e.localizedDescription).")
            }
            guard let result = request.results as? [VNClassificationObservation] else {fatalError("Model failed to processed.")}
            
            if let firstResult = result.first {
                self.flowerManager.fetchFlower(flowerName: firstResult.identifier)
            }
//            self.i = 0
//            for r in result {
//                self.i += 1
//                print("Result \(self.i): \(r.identifier)")
//            }
//            print("Results List: \(result)")
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        
        do {
            try handler.perform([request])
        } catch {
            print("Failed perform request \(error.localizedDescription).")
        }
        
    }
    
    func showAlert() {
        let alert = UIAlertController(title: nil, message: "Please wait...", preferredStyle: .alert)
        
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = UIActivityIndicatorView.Style.medium
        
        loadingIndicator.startAnimating()
        
        alert.view.addSubview(loadingIndicator)
        self.present(alert, animated: true, completion: nil)
    }
    
    func dismissAlert() {
        if let vc = self.presentedViewController, vc is UIAlertController {             dismiss(animated: false, completion: nil)
        }
    }
    
    @IBAction func cameraPressed(_ sender: UIButton) {
        present(imagePicker, animated: true, completion: nil)
    }
    
}

extension ViewController: FlowerManagerDelegate {
    
    func didFailWithError(_ error: Error) {
        DispatchQueue.main.async {
            print("Failed to update with JSON: \(error)\n\(error.localizedDescription).")
            self.title = "Failed to detect"
            self.cameraView.image = self.pickedImage
            self.descriptionLabel.text = "Could not get information on flower from Wikipedia."
        }
    }
    
    func didUpdateFlower(_ flowerManager: FlowerManager, _ flowerModel: FlowerModel) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            // wait two seconds to simulate some work happening
            // then remove the spinner view controller
            self.dismissAlert()
            let locale = Locale(identifier: Locale.current.identifier)
            self.title = flowerModel.title.capitalized(with: locale)
            self.descriptionLabel.text = flowerModel.desc
            self.cameraView.sd_setImage(with: URL(string: flowerModel.flowerImageURL)) { (image, error, cache, url) in
                if let currentImage = self.cameraView.image {
                    
                    guard let dominantColor = ColorThief.getColor(from: currentImage) else { fatalError("Can't get dominant color") }
                    self.navigationController?.navigationBar.barTintColor = dominantColor.makeUIColor()
                    self.navigationController?.navigationBar.backgroundColor = dominantColor.makeUIColor()
                    
                } else {
                    print("can't get the image from wikipedia")
                }
            }
        }
        
        DispatchQueue.main.async {
            self.showAlert()
        }
    }
    
}


//extension UIView {
//    func showBlurLoader() {
//        let blurLoader = BlurLoader(frame: frame)
//        self.addSubview(blurLoader)
//    }
//
//    func removeBluerLoader() {
//        if let blurLoader = subviews.first(where: { $0 is BlurLoader }) {
//            blurLoader.removeFromSuperview()
//        }
//    }
//}


//class BlurLoader: UIView {
//
//    var blurEffectView: UIVisualEffectView?
//
//    override init(frame: CGRect) {
//        let blurEffect = UIBlurEffect(style: .dark)
//        let blurEffectView = UIVisualEffectView(effect: blurEffect)
//        blurEffectView.frame = frame
//        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//        self.blurEffectView = blurEffectView
//        super.init(frame: frame)
//        addSubview(blurEffectView)
//        addLoader()
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    private func addLoader() {
//        guard let blurEffectView = blurEffectView else { return }
//        let activityIndicator = UIActivityIndicatorView(style: .large)
//        activityIndicator.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
//        blurEffectView.contentView.addSubview(activityIndicator)
//        activityIndicator.center = blurEffectView.contentView.center
//        activityIndicator.startAnimating()
//    }
//}

//class SpinnerViewController: UIViewController {
//    var spinner = UIActivityIndicatorView(style: .whiteLarge)
//
//    override func loadView() {
//        view = UIView()
//        view.backgroundColor = UIColor(white: 0, alpha: 0.7)
//
//        spinner.translatesAutoresizingMaskIntoConstraints = false
//        spinner.startAnimating()
//        view.addSubview(spinner)
//
//        spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
//        spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
//    }
//}
