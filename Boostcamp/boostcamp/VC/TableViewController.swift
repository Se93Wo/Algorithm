//
//  TableViewController.swift
//  boostcamp
//
//  Created by SeungWoo Jang on 2018. 12. 10..
//  Copyright © 2018년 SeungWoo Jang. All rights reserved.
//

import UIKit

extension NSNotification.Name {
    static let TableValueSender = NSNotification.Name("TableValueSender")
}

class TableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var movieListTableView: UITableView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    let cellIdentifier: String = "tableViewMovieListCell"
    let refreshControl = UIRefreshControl()
    var movieList: [MovieList] = []
    var orderType: Int = 0
    var token : NSObjectProtocol?
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return movieList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = movieListTableView.dequeueReusableCell(withIdentifier: self.cellIdentifier, for: indexPath) as! MovieListTableViewCell
        
        let movie: MovieList = self.movieList[indexPath.row]
        cell.coverImage?.image = nil
        cell.titleLabel.text = movie.title
        cell.ageImage?.image = UIImage(named: "ic_\(movie.grade)")
        cell.infoLabel.text = movie.tableViewInfoText
        cell.dateLabel.text = "개봉일 : \(movie.date)"
        
        DispatchQueue.global().async {
            guard let imageURL: URL = URL(string: movie.thumb) else { return }
            guard let imageData: Data = try? Data(contentsOf: imageURL) else { return }
            DispatchQueue.main.async {
                if let index: IndexPath = self.movieListTableView.indexPath(for: cell) {
                    if index.row == indexPath.row {
                        cell.coverImage?.image = UIImage(data: imageData)
                    }
                }
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func refresh() {
        movieListTableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshTarget(_:)), for: .valueChanged)
    }
    
    @objc func refreshTarget(_ sender: Any) {
        movieListTableView.reloadData()
        self.refreshControl.endRefreshing()
    }
    
    func tableViewURL(orderType: Int) {
        self.indicator.startAnimating()
        guard let url: URL = URL(string: "http://connect-boxoffice.run.goorm.io/movies?order_type=\(orderType)") else { return }
        
        let session: URLSession = URLSession(configuration: .default)
        let dataTask: URLSessionDataTask = session.dataTask(with: url) { (data: Data?, response: URLResponse?, error: Error?) in
            
            if let error = error {
                let alert = UIAlertController(title: "Error", message: "\(error.localizedDescription)", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "취소", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }
            
            guard let data = data else { return }
            
            do {
                let apiRespon: Movie_List = try
                    JSONDecoder().decode(Movie_List.self, from: data)
                self.movieList = apiRespon.movies
                
                DispatchQueue.main.async {
                    self.movieListTableView.reloadData()
                }
                
            }catch let DecodingError.dataCorrupted(context) {
                print(context)
            }catch let DecodingError.keyNotFound(key, context) {
                print("Key '\(key)' not found:", context.debugDescription)
                print("codingPath:", context.codingPath)
            }catch let DecodingError.valueNotFound(value, context) {
                print("Value '\(value)' not found:", context.debugDescription)
                print("codingPath:", context.codingPath)
            }catch let DecodingError.typeMismatch(type, context)  {
                print("Type '\(type)' mismatch:", context.debugDescription)
                print("codingPath:", context.codingPath)
            }catch(let err) {
                let alert = UIAlertController(title: "Error", message: "\(err.localizedDescription)", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "취소", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }
        }
        
        self.indicator.stopAnimating()
        dataTask.resume()
        navigationBarTitle()
    }
    
    @IBAction func SettingBarButtonClick(_ sender: Any) {
        self.showAlertController(style: UIAlertController.Style.actionSheet)
    }
    
    func showAlertController(style: UIAlertController.Style) {
        let alertController: UIAlertController
        alertController = UIAlertController(title: "정렬방식 선택", message: "영화를 어떤 순서로 정렬하시겠습니까?", preferredStyle: style)
        
        
        let reservationRateAction: UIAlertAction
        reservationRateAction = UIAlertAction(title: "예매율", style: UIAlertAction.Style.default, handler: { (action: UIAlertAction) in
            self.orderType = 0
            //self.navigationController?.navigationBar.topItem?.title = "예매율순"
            DispatchQueue.global().async {
                NotificationCenter.default.post(name: NSNotification.Name.TableValueSender, object: nil, userInfo: ["orderType": self.orderType])
            }
            return self.tableViewURL(orderType: self.orderType)
        })
        
        let curationAction: UIAlertAction
        curationAction = UIAlertAction(title: "큐레이션", style: UIAlertAction.Style.default, handler: {(action: UIAlertAction) in
            self.orderType = 1
            //self.navigationController?.navigationBar.topItem?.title = "큐레이션순"
            DispatchQueue.global().async {
                NotificationCenter.default.post(name: NSNotification.Name.TableValueSender, object: nil, userInfo: ["orderType": self.orderType])
            }
            return self.tableViewURL(orderType: self.orderType)
        })
        
        let releaseDateAction: UIAlertAction
        releaseDateAction = UIAlertAction(title: "개봉일", style: UIAlertAction.Style.default, handler: {(action: UIAlertAction) in
            self.orderType = 2
            //self.navigationController?.navigationBar.topItem?.title = "개봉일순"
            DispatchQueue.global().async {
                NotificationCenter.default.post(name: NSNotification.Name.TableValueSender, object: nil, userInfo: ["orderType": self.orderType])
            }
            return self.tableViewURL(orderType: self.orderType)
        })
        let cancel = UIAlertAction(title: "취소", style: .cancel, handler: nil)
        
        alertController.addAction(reservationRateAction)
        alertController.addAction(curationAction)
        alertController.addAction(releaseDateAction)
        alertController.addAction(cancel)
        
        self.present(alertController, animated: true, completion: {
            print("Alert controller shown")
        })
    }
    
    func navigationBarTitle() {
        if (orderType == 0) {
            self.navigationController?.navigationBar.topItem?.title = "예매율순"
        }
        else if(orderType == 1){
            self.navigationController?.navigationBar.topItem?.title = "큐레이션순"
        }
        else if(orderType == 2) {
            self.navigationController?.navigationBar.topItem?.title = "개봉일순"
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let detailViewController = segue.destination as? DetailViewController {
            if let cell = sender as? MovieListTableViewCell {
                if let indexPath = movieListTableView.indexPath(for: cell) {
                    let target = movieList[indexPath.row]
                    detailViewController.receiveId = target.id
                    detailViewController.receiveTitle = target.title
                }
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tableViewURL(orderType: self.orderType)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        token = NotificationCenter.default.addObserver(forName: NSNotification.Name.CollectionValueSender, object: nil, queue: OperationQueue.main) { [weak self] (notification) in guard let type = notification.userInfo?["orderType"] as? Int else { return }
            
            self?.orderType = type
            self?.tableViewURL(orderType: self?.orderType ?? 0)
        }
    }

    deinit {
        if let token = token { NotificationCenter.default.removeObserver(token) }
    }
}