//
//  CommentDetailViewController.swift
//  SampleApp
//
//  Created by Philip Fryklund on 3/Oct/19.
//  Copyright © 2019 Philip Fryklund. All rights reserved.
//

import UIKit



final class CommentDetailViewController: UITableViewController {
	
	var viewModel: CommentDetailItemListViewModel!
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.tableView.estimatedRowHeight = 100
        self.tableView.rowHeight = UITableView.automaticDimension
		viewModel.tableView = self.tableView
		viewModel.didSelectRowAt = didSelectRow(at:)
				
		let refreshControl = UIRefreshControl()
		refreshControl.addTarget(self, action: #selector(refresh(refreshControl:)), for: .valueChanged)
		self.tableView.refreshControl = refreshControl
	}
	
	
	@objc func refresh(refreshControl: UIRefreshControl) {
		viewModel.refresh { (error) in
			refreshControl.endRefreshing()
			error.map { self.presentError(error: $0) }
		}
	}
	
	
	func didSelectRow(at indexPath: IndexPath) {
		let comment = viewModel.data(at: indexPath)
		if comment.numberOfAnsweres > 0 {
			let vc = self.storyboard?.instantiateViewController(withIdentifier: "comment_detail") as! CommentDetailViewController // Creates a new instance of itself so no segues available, that wouldbe be very scalable...
			vc.viewModel = CommentDetailItemListViewModel(comment: comment)
			self.navigationController?.pushViewController(vc, animated: true)
		}
	}
}



//MARK: - View model

final class CommentDetailItemListViewModel: NSObject, ItemListViewModel {
	
	typealias Cell = CommentTableViewCell
	
	let comment: Comment
	var data: [Comment]
	var didSelectRowAt: ((IndexPath) -> Void)!
	
	var tableView: UITableView! {
		didSet {
			tableView.dataSource = self
			tableView.delegate = self
			tableView.register(Cell.self)
		}
	}
	
	
	init(comment: Comment) {
		self.comment = comment
		self.data = [comment] + (comment.answeres ?? [])
	}
	
	
	func refresh(completion: @escaping (Error?) -> Void) {
		CommentLoader.shared.invalidateCache(for: data.map(\.id))
		comment.load { (_, error) in
			if error == nil {
				self.data = [self.comment] + self.comment.answeres!
				self.tableView.reloadData()
			}
			completion(error)
		}
	}
	
	
	//MARK: Tableview delegate
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		didSelectRowAt(indexPath)
	}
	
	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		if indexPath.row == 0 {
			cell.setSelected(true, animated: false) // Make first comment pop out from the rest, must be in `willDisplay` otherwise will get reset
		}
	}
	
	
	//MARK: Tableview data source
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		data.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let comment = data(at: indexPath)
		comment.load { (source, _) in
			if source == .remote {
				self.reloadItem(at: indexPath)
			}
		}
		let cell = self.dequeueReusableCell(in: tableView, at: indexPath)
		cell.comment = comment
		if indexPath.row == 0 {
			cell.accessoryType = .none
			cell.isUserInteractionEnabled = false
			cell.numberOfAnsweresLabel.isHidden = true
		}
		return cell
	}
}
