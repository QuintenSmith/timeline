//
//  PhotoSelectViewController.swift
//  timeline
//
//  Created by Quinten Smith on 9/26/18.
//  Copyright © 2018 Quinten Smith. All rights reserved.
//

import UIKit

protocol PhotoSelectViewControllerDelegate: class {
    func photoSelectViewControllerSelected(photo: UIImage)
}

class PhotoSelectViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var selectImageBtn: UIButton!
    @IBOutlet weak var photoImageView: UIImageView!
    
    weak var delegate: PhotoSelectViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        selectImageBtn.setTitle("Select a Photo", for: .normal)
        photoImageView.image = nil
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        if let photo = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            selectImageBtn.setTitle("", for: .normal)
            photoImageView.image = photo
            delegate?.photoSelectViewControllerSelected(photo: photo)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil) 
    }
    
    @IBAction func selectImageBtnTapped(_ sender: Any) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        
        let actionSheet = UIAlertController(title: "Select a Photo", message: nil, preferredStyle: .actionSheet)
        
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
            actionSheet.addAction(UIAlertAction(title: "Photos", style: .default, handler: { (_) in
                imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
                self.present(imagePicker, animated: true, completion: nil)
            }))
            
        }
        if UIImagePickerController.isSourceTypeAvailable(.camera){
            
            imagePicker.sourceType = UIImagePickerController.SourceType.camera
            self.present(imagePicker, animated: true, completion: nil)
        }
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

       self.present(actionSheet, animated: true)
    }
}
