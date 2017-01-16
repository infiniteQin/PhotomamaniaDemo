//
//  PhotoCommentsViewController.swift
//  Photomania
//
//  Created by Essan Parto on 2014-08-25.
//  Copyright (c) 2014 Essan Parto. All rights reserved.
//

import UIKit
import Alamofire

class PhotoCommentsViewController: UITableViewController {
  var photoID = 0
  var comments = [Comment]()
    fileprivate var currPage = 1
    
  // MARK: Life-Cycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    tableView.rowHeight = UITableViewAutomaticDimension
    tableView.estimatedRowHeight = 50.0
    
    title = "Comments"
    navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dismissController))
    loadComments(page: 1)
    
  }
  
  private dynamic func dismissController() {
    dismiss(animated: true, completion: nil)
  }
  
  // MARK: - TableView
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return comments.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell", for: indexPath) as? PhotoCommentTableViewCell else { return UITableViewCell() }
    let comment = comments[indexPath.row]
    cell.userFullnameLabel.text = comment.userFullname
    cell.commentLabel.text = comment.commentBody
    
    cell.userImageView.image = nil
    
    let imageURL = comments[indexPath.row].userPictureURL
    
    Alamofire.request(imageURL, method: .get).validate().responseImage {
        response in
        if let image = response.result.value, response.request?.url?.absoluteString == imageURL {
            cell.userImageView.image = image
        }
    }
    return cell
  }
}

extension PhotoCommentsViewController {
    fileprivate func loadComments(page:Int) {
        Alamofire.request(Five100px.Router.comments(photoID, currPage)).validate().responseCollection { (collectionResp:DataResponse<[Comment]>) in
            if page == 1 {
                self.comments.removeAll()
            }
            guard case let .success(comments) = collectionResp.result else {
                self.reloadViews()
                return
            }
            
            self.comments.append(contentsOf: comments)
            self.reloadViews()
        }
    }
    private func reloadViews() {
        self.tableView.reloadData()
    }
}

class PhotoCommentTableViewCell: UITableViewCell {
  @IBOutlet fileprivate weak var userImageView: UIImageView!
  @IBOutlet fileprivate weak var commentLabel: UILabel!
  @IBOutlet fileprivate weak var userFullnameLabel: UILabel!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    userImageView.layer.cornerRadius = 5.0
    userImageView.layer.masksToBounds = true
    
    commentLabel.numberOfLines = 0
  }
}
