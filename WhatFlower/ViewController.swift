//
//  ViewController.swift
//  WhatFlower
//
//  Created by Ivan Teo on 28/12/20.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var imageView: UIImageView!
    let imagePicker = UIImagePickerController()
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let userPickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage{
            guard let ciimage = CIImage(image: userPickedImage) else{
                fatalError("Error converting image to ciimage")
            }
            detect(image: ciimage)
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    func detect(image: CIImage){
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else{
            fatalError("Error setting up model")
        }
        var flowerName:String?
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let results = request.results as? [VNClassificationObservation] else{
                fatalError("Unable to process image")
            }
            if let firstResult = results.first?.identifier{
                flowerName = firstResult
                self.navigationItem.title = flowerName?.capitalized
            }
        }
        let handler = VNImageRequestHandler(ciImage: image)
        do{
            try handler.perform([request])
        }catch{
            print(error)
        }
        // use name of flower to send get request to wiki api
        // get the
        let wikipediaURl = "https://en.wikipedia.org/w/api.php"

        let parameters : [String:String] = [
          "format" : "json",
          "action" : "query",
          "prop" : "extracts|pageimages",
          "exintro" : "",
          "explaintext" : "",
          "titles" : flowerName ?? "",
          "indexpageids" : "",
          "redirects" : "1",
            "pithumbsize" : "500"
          ]

        AF.request(wikipediaURl, parameters: parameters).responseJSON {(response) in
            switch response.result {
                    case .success(let value):
                        let result = JSON(value)
                        let pageid = result["query"]["pageids"][0]
                        self.descLabel.text = "\(result["query"]["pages"]["\(pageid)"]["extract"])"
                        let imageURL = result["query"]["pages"]["\(pageid)"]["thumbnail"]["source"].stringValue
                        self.imageView.sd_setImage(with: URL(string: imageURL))
                    case .failure(let error):
                        print(error)
                    }
        }
    }
    @IBAction func plusButtonPressed(_ sender: UIBarButtonItem) {
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    @IBAction func cameraButtonPressed(_ sender: UIBarButtonItem) {
        imagePicker.sourceType = .camera
        present(imagePicker, animated: true, completion: nil)
}

    @IBOutlet weak var descLabel: UILabel!
}


