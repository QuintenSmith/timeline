//
//  AddPostTableViewController.swift
//  timeline
//
//  Created by Quinten Smith on 9/25/18.
//  Copyright © 2018 Quinten Smith. All rights reserved.
//

import UIKit

class AddPostTableViewController: UITableViewController, UINavigationControllerDelegate  {
    
//    func photoSelectViewControllerSelected(photo: UIImage) {
//       self.photo = photo
//    }


    @IBOutlet weak var postTextField: UITextField!
    
    var photo: UIImage?
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
   }
    
    @IBAction func addPostBtnTapped(_ sender: Any) {
        guard let photo = photo else { return }
        guard let caption = postTextField.text, !caption.isEmpty else {return}
        PostController.shared.createPostWith(image: photo, caption: caption) { (post) in
            
        }
        self.tabBarController?.selectedIndex = 0
    }
    
    @IBAction func cancelBtnTapped(_ sender: Any) {
        self.tabBarController?.selectedIndex = 0
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ToPhotoSelectVC"{
            guard let destinationVC = segue.destination as? PhotoSelectViewController else {return}
            destinationVC.delegate = self
        }
    }
    
}

extension AddPostTableViewController: PhotoSelectViewControllerDelegate{
    func photoSelectViewControllerSelected(photo: UIImage) {
        self.photo = photo
    }
}

