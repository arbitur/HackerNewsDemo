//
//  StoryDetailViewController.swift
//  SampleApp
//
//  Created by Philip Fryklund on 2/Oct/19.
//  Copyright © 2019 Philip Fryklund. All rights reserved.
//

import UIKit
import SafariServices



final class StoryDetailViewController: UITableViewController {
	
	enum SegueId: String {
		/// CommentDetailViewController
		case comment = "comment"
	}
	
	@IBOutlet var scoreLabel: UILabel!
	@IBOutlet var authorLabel: UILabel!
	@IBOutlet var dateLabel: UILabel!
	@IBOutlet var titleLabel: UILabel!
	@IBOutlet var numberOfCommentsLabel: UILabel!
	@IBOutlet var linkButton: UIButton!
	
	var viewModel: StoryDetailItemListViewModel!
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.tableView.estimatedRowHeight = 100
		self.tableView.rowHeight = UITableView.automaticDimension
		viewModel.tableView = self.tableView
		viewModel.didSelectRowAt = didSelectRow(at:)
		
		let refreshControl = UIRefreshControl()
		refreshControl.addTarget(self, action: #selector(handleRefresh(refreshControl:)), for: .valueChanged)
		self.tableView.refreshControl = refreshControl
		
		updateStory()
	}
	
	
	func updateStory() {
		scoreLabel.text = viewModel.story.score.map { "\($0)" }
		authorLabel.text = viewModel.story.author
		dateLabel.text = viewModel.story.date?.format(date: .medium, time: .short)
		titleLabel.text = viewModel.story.title
		numberOfCommentsLabel.text = viewModel.story.numberOfComments.map { "\($0)" }
		if let url = viewModel.story.url, let host = url.host {
			linkButton.isHidden = false
			linkButton.setTitle(host, for: .normal)
		}
		else {
			linkButton.isHidden = true
		}
		
		self.tableView.updateTableHeaderViewFrameWithAutoLayout()
	}
	
	
	@objc func handleRefresh(refreshControl: UIRefreshControl) {
		viewModel.refresh { (error) in
			refreshControl.endRefreshing()
			if let error = error {
				self.presentError(error: error)
			}
			else {
				self.updateStory()
			}
		}
	}
	
	
	@IBAction func handleTouchLinkButton() {
		guard let url = viewModel.story.url else {
			return
		}
		
		let vc = SFSafariViewController(url: url)
		self.present(vc, animated: true, completion: nil)
	}
	
	
	func didSelectRow(at indexPath: IndexPath) {
		let comment = viewModel.data(at: indexPath)
		if comment.numberOfAnsweres > 0 { // Dont try to open answers if none exist
			self.performSegue(withIdentifier: SegueId.comment.rawValue, sender: comment)
		}
	}
	
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		guard let segueId = segue.identifier.flatMap(SegueId.init) else {
			return
		}
		
		switch segueId {
		case .comment:
			let vc = segue.destination as! CommentDetailViewController
			vc.viewModel = CommentDetailItemListViewModel(comment: sender as! Comment)
		}
	}
}



//MARK: - View model

final class StoryDetailItemListViewModel: NSObject, ItemListViewModel {
	
	typealias Cell = CommentTableViewCell
	
	
	let story: Story
	var data = [Comment]()
	var didSelectRowAt: ((IndexPath) -> Void)!
	var tableView: UITableView! {
		didSet {
			tableView.dataSource = self
			tableView.delegate = self
			tableView.register(Cell.self)
		}
	}
	
	
	init(story: Story) {
		self.story = story
		self.data = story.topCommentIds?.map(Comment.init) ?? []
	}
	
	
	/// Refresh everything in Story, invalidate story and its comments and fetch them from scratch
	func refresh(completion: @escaping (Error?) -> Void) {
		StoryLoader.shared.invalidateCache(for: story.id)
		self.story.topCommentIds.map(CommentLoader.shared.invalidateCache)
		story.load { (_, error) in
			if error == nil {
				self.data = self.story.topCommentIds?.map(Comment.init) ?? []
				self.tableView.reloadData()
			}
			
			completion(error)
		}
	}
	
	
	// MARK: Tableview delegate
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		didSelectRowAt(indexPath)
	}
	
	
	// MARK: Tableview data source
	
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
		return cell
	}
}
