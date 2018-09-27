//
//  PostTableViewCell.swift
//  timeline
//
//  Created by Quinten Smith on 9/25/18.
//  Copyright © 2018 Quinten Smith. All rights reserved.
//

import UIKit

class PostTableViewCell: UITableViewCell {

    @IBOutlet weak var postImageView: UIImageView!
    @IBOutlet weak var captionLabel: UILabel!
    @IBOutlet weak var commentLabel: UILabel!
    
    var post: Post? {
        didSet {
            updateViews()
        }
    }
    
    func updateViews() {
        guard let post = post else {return}
        postImageView.image = post.photo
        captionLabel.text = "Post caption: \(post.caption)"
        PostController.shared.fetchCommentsFor(post: post) { (success) in
            if success {
                DispatchQueue.main.async {
                     self.commentLabel.text = "\(post.comments.count) Comments"
                }
            }
        }
    }
    
}
