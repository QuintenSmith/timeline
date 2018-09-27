//
//  PostDetailTableViewController.swift
//  timeline
//
//  Created by Quinten Smith on 9/25/18.
//  Copyright © 2018 Quinten Smith. All rights reserved.
//

import UIKit

class PostDetailTableViewController: UITableViewController {
    
    let formatter: DateFormatter = {
        var dateformatter = DateFormatter()
        dateformatter.dateStyle = .short
        dateformatter.timeStyle = .short
        return dateformatter
    }()
    
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var followPostBtn: UIButton!
    
    
    var post: Post? {
        didSet {
            loadViewIfNeeded()
            updateViews()
        }
    }
    
    func updateViews() {
        guard let post = post else {return}
        photoImageView.image = post.photo
        PostController.shared.checkSubscription(to: post) { (isSubscribed) in
            DispatchQueue.main.async {
                let buttonTitle = isSubscribed ? "Unfollow" : "Follow"
                self.followPostBtn.setTitle(buttonTitle, for: .normal)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120 
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return post?.comments.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell", for: indexPath)
        let comment = post?.comments[indexPath.row]
        cell.textLabel?.text = comment?.text
        if let timestamp = comment?.timestamp {
            cell.detailTextLabel?.text = formatter.string(from: timestamp)
        }
        
        return cell
    }
 
    @IBAction func commentBtnTapped(_ sender: Any) {
        let alertController = UIAlertController(title: "Add a comment", message: "Tell us what you think about this post: ", preferredStyle: .alert)
        alertController.addTextField { (commentTextField) in
            commentTextField.placeholder = "Your comment here"
        }
        
        let okAction = UIAlertAction(title: "OK", style: .default) { (_) in
            guard var commentText = alertController.textFields?.first?.text,
                let post = self.post else { return }
            guard !commentText.isEmpty else { return }
            PostController.shared.addComment(text: commentText, post: post, completion: { (comment) in
                DispatchQueue.main.async {
                    guard let comment = comment else {return}
                    commentText = comment.text
                    self.tableView.reloadData()
                }
            })
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true)
    }
    
    @IBAction func shareBtnTapped(_ sender: Any) {
        guard let post = post, let photo = post.photo else {return}
        let activityViewController = UIActivityViewController(activityItems: [photo, post.caption], applicationActivities: nil)
        DispatchQueue.main.async {
            self.present(activityViewController, animated:true)
        }
    }
    
    @IBAction func followBtnTapped(_ sender: Any) {
        guard let post = post else {return}
        PostController.shared.toggleSubscriptionTo(commentsFor: post) { (success, error) in
            if let error = error {
                print("There was an error in: \(error) \(error.localizedDescription)")
                return
            }
            if success {
                DispatchQueue.main.async {
                    self.updateViews()
                }
            }
        }
    }
    
    
}
