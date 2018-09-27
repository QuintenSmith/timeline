//
//  PostController.swift
//  timeline
//
//  Created by Quinten Smith on 9/25/18.
//  Copyright © 2018 Quinten Smith. All rights reserved.
//

import UIKit
import CloudKit
import UserNotifications

class PostController {
    
    static let shared = PostController()
    
    private init() {}
    
    var posts: [Post] = [] {
        didSet {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: self.postsChangeNotification, object: nil)
            }
        }
    }
    
    let postsChangeNotification = Notification.Name("Posts were updated")
    
    func addComment(text: String, post: Post, completion: @escaping (Comment?) -> Void) {
        let comment = Comment(text: text, post: post)
        post.comments.append(comment)
        CKContainer.default().publicCloudDatabase.save(CKRecord(comment)) { (record, error) in
            if let error = error {
                print("Error saving post \(error) \(error.localizedDescription)")
                completion(nil); return
            }
            completion(comment)
        }
    }
    
    // Check Availibility
    
    func checkAccountStatus(completion: @escaping (_ isLoggedIn: Bool) -> Void) {
        CKContainer.default().accountStatus { [weak self] (status, error) in
            if let error = error {
                print("Error checking accountStatus \(error) \(error.localizedDescription)")
                completion(false); return
            } else {
                let errorText = "Sign into iCloud in Settings"
                switch status {
                case .available:
                    completion(true)
                case .noAccount:
                    let noAccount = "No account found"
                    self?.presentErrorAlert(errorTitle: errorText, errorMessage: noAccount)
                    completion(false)
                case .couldNotDetermine:
                    self?.presentErrorAlert(errorTitle: errorText, errorMessage: "Error with iCloud account status")
                    completion(false)
                case .restricted:
                    self?.presentErrorAlert(errorTitle: errorText, errorMessage: "Restricted iCloud account")
                    completion(false)
                }
            }
        }
    }
    
    func presentErrorAlert(errorTitle: String, errorMessage: String) {
        DispatchQueue.main.async {
            if let appDelegate = UIApplication.shared.delegate,
                let appWindow = appDelegate.window!,
                let rootViewController = appWindow.rootViewController {
                rootViewController.showAlertMessage(titleStr: errorTitle, messageStr: errorMessage)
            }
        }
    }
    
    func createPostWith(image: UIImage, caption: String, completion: @escaping (Post?) -> Void) {
        let post = Post(photo: image, caption: caption)
        posts.append(post)
        CKContainer.default().publicCloudDatabase.save(CKRecord(post)) { (_, error) in
            if let error = error {
                print("Error saving post \(error) \(error.localizedDescription)")
                completion(nil); return
            }
            completion(post) 
        }
    }
    
    // Fetch
    
    func fetchPosts(completion: @escaping([Post]?) -> Void) {
        
        let predicate = NSPredicate(value: true)
        
        let query = CKQuery(recordType: "Post", predicate: predicate)
        
        CKContainer.default().publicCloudDatabase.perform(query, inZoneWith: nil) { (records, error) in
            if let error = error {
                print("Error fetching posts \(error) \(error.localizedDescription)")
                completion(nil); return
            }
            guard let records = records else { completion(nil); return }
            
            let posts = records.compactMap{ Post(ckRecord: $0)}
            
            self.posts = posts
            completion(posts)
        }
    }
    
    func fetchCommentsFor(post: Post, completion: @escaping (Bool) -> Void) {
        
        let postReference = post.recordID
        let predicate = NSPredicate(format: "postReference == %@", postReference)
        let commentIDs = post.comments.compactMap({$0.recordID})
        let predicate2 = NSPredicate(format: "NOT(recordID IN %@)", commentIDs)
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, predicate2])
        
        let query = CKQuery(recordType: "Comment", predicate: compoundPredicate)
        
        CKContainer.default().publicCloudDatabase.perform(query, inZoneWith: nil) { (records, error) in
            if let error = error {
                print("Error fetching comments: \(error) \(error.localizedDescription)")
                completion(false); return
            }
            
            guard let records = records else { completion(false); return }
            let comments = records.compactMap{ Comment(record: $0)}
            post.comments.append(contentsOf: comments)
            completion(true)
        }
    }
    
    // Subsciptions
    
    func subscribeToNewPosts(completion: @escaping (Bool, Error?) -> Void) {
        let predicate = NSPredicate(value: true)
        
        let subscription = CKQuerySubscription.init(recordType: "Post", predicate: predicate, options: .firesOnRecordCreation)
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.alertBody = "New post on timeline"
        notificationInfo.soundName = "default"
        notificationInfo.shouldSendContentAvailable = true
        notificationInfo.shouldBadge = true
        
        subscription.notificationInfo = notificationInfo
        
        CKContainer.default().publicCloudDatabase.save(subscription) { (subscription, error) in
            
            if let error = error {
                print("Error fetching comments: \(error) \(error.localizedDescription)")
                completion(false, error); return
            } else {
                completion(true, nil); return
            }
        }
    }
    
    func addSubscriptionTo(commentsForPost post: Post, completion: @escaping (Bool, Error?) -> Void) {
        
        let predicate = NSPredicate(format: "postReference = %@", post.recordID)
        
        let subscription = CKQuerySubscription(recordType: "Comment", predicate: predicate, subscriptionID: post.recordID.recordName, options: .firesOnRecordCreation)
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.alertBody = "New comment add to an post on timeline"
        notificationInfo.shouldSendContentAvailable = true
        notificationInfo.soundName = "default"
        notificationInfo.desiredKeys = nil
        
        subscription.notificationInfo = notificationInfo
        
        CKContainer.default().publicCloudDatabase.save(subscription) { (subscription, error) in
            
            if let error = error {
                print("Error fetching comments: \(error) \(error.localizedDescription)")
                completion(false, error); return
            } else {
                completion(true, nil); return
            }
        }
        
    }
    
    
    func removeSubscriptionTo(commentsForPost post: Post, completion: ((Bool) -> ())?){
        let subscriptionID = post.recordID.recordName
        CKContainer.default().publicCloudDatabase.delete(withSubscriptionID: subscriptionID) { (_, error) in
            if let error = error {
                print("There was an error in:\(error)  ; \(error.localizedDescription)")
                completion?(false)
                return
            }else {
                print("Subscription deleted")
                completion?(true)
            }
            
        }
    }
    
    func checkSubscription(to post: Post, completion: @escaping (Bool) -> Void) {
        let subscriptionID = post.recordID.recordName
        CKContainer.default().publicCloudDatabase.fetch(withSubscriptionID: subscriptionID) { (subscription, error) in
            if let error = error {
                print("Error fetching comments: \(error) \(error.localizedDescription)")
                completion(false); return
            }
            
            
            if subscription != nil {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    func toggleSubscriptionTo(commentsFor post: Post, completion: ((Bool, Error?) -> ())?) {
        checkSubscription(to: post) { (isSubscribed) in
            if isSubscribed{
                self.removeSubscriptionTo(commentsForPost: post, completion: { (success) in
                    if success {
                        print("Successfully removed subscription caption: \(post.caption)")
                        completion?(true, nil)
                    } else {
                        print("Problem removing caption: \(post.caption)") ; completion?(true, nil) ;
                        completion?(false, nil)
                    }
                })
            } else {
                self.addSubscriptionTo(commentsForPost: post, completion: { (success, error) in
                    if let error = error {
                        print("There was an error in: \(error)  ; \(error.localizedDescription)")
                        completion?(false, error)
                        return
                    }
                    if success {
                        print("Successfully added the subscription to the post with caption: \(post.caption)")
                        completion?(true, nil)
                    } else {
                        print("Something went wrong add subscription: \(post.caption)"); completion?(true,nil)
                        completion?(false, nil)
                    }
                })
            }
        }
    }
}
