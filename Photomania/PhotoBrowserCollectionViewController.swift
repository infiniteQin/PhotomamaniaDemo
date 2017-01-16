//
//  PhotoBrowserCollectionViewController.swift
//  Photomania
//
//  Created by Essan Parto on 2014-08-20.
//  Copyright (c) 2014 Essan Parto. All rights reserved.
//

import UIKit
import Alamofire

class PhotoBrowserCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
  
    var photos = Set<PhotoInfo>()
    
    fileprivate var currPage = 1
    fileprivate var loading = false
    
    private var imageCache = NSCache<NSString,UIImage>()
    
    private let refreshControl = UIRefreshControl()
  
    private let PhotoBrowserCellIdentifier = "PhotoBrowserCell"
    private let PhotoBrowserFooterViewIdentifier = "PhotoBrowserFooterView"
  
  // MARK: Life-cycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupView()
    handleRefresh()
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  // MARK: CollectionView
  
  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return photos.count
  }
  
  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoBrowserCellIdentifier, for: indexPath) as? PhotoBrowserCollectionViewCell else { return UICollectionViewCell() }
    let photoInfo = photos[photos.index(photos.startIndex, offsetBy: indexPath.item)]
    
    cell.request?.cancel()
    if let image = imageCache.object(forKey: photoInfo.url as NSString) {
        cell.imageView.image = image
    }else {
        cell.imageView.image = nil
        cell.request = Alamofire.request(photoInfo.url).responseImage { (imageResponse) in
            guard let image = imageResponse.result.value else {
                return;
            }
            self.imageCache.setObject(image, forKey: photoInfo.url as NSString)
            cell.imageView.image = image
        }
    }
    
    return cell
  }
  
  override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
    return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: PhotoBrowserFooterViewIdentifier, for: indexPath)
  }
  
  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    performSegue(withIdentifier: "ShowPhoto", sender: photos[photos.index(photos.startIndex, offsetBy: indexPath.item)].id)
  }
  
  // MARK: Helper
  private func setupView() {
    navigationController?.setNavigationBarHidden(false, animated: true)
    
    guard let collectionView = collectionView else { return }
    let layout = UICollectionViewFlowLayout()
    let itemWidth = (view.bounds.width - 2) / 3
    layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
    layout.minimumInteritemSpacing = 1
    layout.minimumLineSpacing = 1
    layout.footerReferenceSize = CGSize(width: collectionView.bounds.width, height: 100)
    
    collectionView.collectionViewLayout = layout
    
    let titleLabel = UILabel(frame: CGRect(x: 0.0, y: 0.0, width: 60.0, height: 30.0))
    titleLabel.text = "Photomania"
    titleLabel.textColor = .white
    titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
    navigationItem.titleView = titleLabel
    
    collectionView.register(PhotoBrowserCollectionViewCell.classForCoder(), forCellWithReuseIdentifier: PhotoBrowserCellIdentifier)
    collectionView.register(PhotoBrowserCollectionViewLoadingCell.classForCoder(), forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: PhotoBrowserFooterViewIdentifier)
    
    refreshControl.tintColor = .white
    refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
    collectionView.addSubview(refreshControl)
  }
  
    //MARK: 
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? PhotoViewerViewController, let id = sender as? Int, segue.identifier == "ShowPhoto" {
          destination.photoID = id
          destination.hidesBottomBarWhenPushed = true
        }
    }
  
    private dynamic func handleRefresh() {
        loadNetData(1)
    }
    
    //MARK: Private Method
    fileprivate func loadNetData(_ page: Int) {
        loading = true
        refreshControl.beginRefreshing()
        Alamofire.request(Five100px.Router.photos(page)).responseJSON { response in
                            self.refreshControl.endRefreshing()
            DispatchQueue.global().async {
                guard let respJson = response.result.value else {
                    self.loading = false
                    return
                }
                guard let photosJson = (respJson as AnyObject).value(forKey: "photos") as? [[String:Any]] else {
                    self.loading = false
                    return
                }
                self.currPage = page
                if page == 1 {
                    self.photos.removeAll()
                }
                
                let lastItemCount = self.photos.count
                photosJson.forEach {
                    guard let _ = $0["nsfw"] as? Bool,
                        let id = $0["id"] as? Int,
                        let imgUrl = $0["image_url"] as? String else {
                            return
                    }
                    self.photos.insert(PhotoInfo(id: id, url: imgUrl))
                }
                
                let indexPaths = (lastItemCount ..< self.photos.count).map { IndexPath(item: $0, section: 0) }
                DispatchQueue.main.async {
                    if page == 1 {
                        self.collectionView?.reloadData();
                    }else {
                        guard indexPaths.count > 0 else {
                            self.loading = false
                            return;
                        }
                        self.collectionView?.insertItems(at: indexPaths)
                    }
                }
                self.loading = false
            }
        }
    }
    
    
}

//MARK: UIScrollViewDelegate
extension PhotoBrowserCollectionViewController {
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y + view.frame.height > scrollView.contentSize.height - 50 && !loading {
            loadNetData(currPage+1)
        }
    }
}

class PhotoBrowserCollectionViewCell: UICollectionViewCell {
    
    fileprivate let imageView = UIImageView()
    
    fileprivate var request : DataRequest?
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    backgroundColor = UIColor(white: 0.1, alpha: 1.0)
    
    imageView.frame = bounds
    addSubview(imageView)
  }
}

class PhotoBrowserCollectionViewLoadingCell: UICollectionReusableView {
  fileprivate let spinner = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    spinner.startAnimating()
    spinner.center = center
    addSubview(spinner)
  }
}
