//
//  StoryListTableViewController.swift
//  SampleApp
//
//  Created by Philip Fryklund on 2019-01-21.
//  Copyright © 2019 Philip Fryklund. All rights reserved.
//

import UIKit



final class StoryListTableViewController: UITableViewController {
	
	enum SegueId: String {
		/// StoryDetailViewController
		case detail = "detail"
	}
	
	var viewModel: StoryItemListViewModel!
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.tableView.estimatedRowHeight = 100
		self.tableView.rowHeight = UITableView.automaticDimension
		viewModel.tableView = tableView
		viewModel.didSelectRowAt = didSelectRow(at:)
		
		let refreshControl = UIRefreshControl()
		refreshControl.addTarget(self, action: #selector(handleRefresh(refreshControl:)), for: .valueChanged)
		self.tableView.refreshControl = refreshControl
	}
	
	private var _first = true
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		if _first {
			_first = false
			// Only auto-fetch the first time opening and do it in didAppear so UI is properly configured before doing animations
			self.tableView.beginAnimateRefreshControl()?.sendActions(for: .valueChanged)
		}
	}
	
	
	@objc func handleRefresh(refreshControl: UIRefreshControl) {
		viewModel.refresh { (error) in
			refreshControl.endRefreshing()
			error.map { self.presentError(error: $0) }
		}
	}
	
	
	func didSelectRow(at indexPath: IndexPath) {
		// Open StoryDetail
		self.performSegue(withIdentifier: SegueId.detail.rawValue, sender: indexPath)
	}
	
	@IBAction private func handleSegmentedControlValueChanged(_ segmentedControl: UISegmentedControl) {
		let list: StoryList
		switch segmentedControl.selectedSegmentIndex {
		case 0: list = .top
		case 1: list = .new
		case 2: list = .best
		default: return assertionFailure() // Dont crash in production but do in development
		}
		
		self.tableView.beginAnimateRefreshControl()
		viewModel.selectList(list) { (error) in
			self.tableView.refreshControl?.endRefreshing()
			error.map { self.presentError(error: $0) }
		}
	}
	
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		guard let segueId = segue.identifier.flatMap(SegueId.init) else {
			return
		}
		
		switch segueId {
		case .detail:
			let indexParth = sender as! IndexPath
			let vc = segue.destination as! StoryDetailViewController
			vc.viewModel = viewModel.storyDetailViewModel(for: indexParth)
		}
	}
}



//MARK: - View model

final class StoryItemListViewModel: NSObject, ItemListViewModel {
	
	typealias Cell = StoryTableViewCell
	
	var data = [Story]()
	var didSelectRowAt: ((IndexPath) -> Void)!
	var tableView: UITableView! {
		didSet {
			tableView.dataSource = self
			tableView.delegate = self
		}
	}
	var storyList: StoryList = .top // Initially use the "top" list.
	
	/// Invalidates cache and fetches the list
	func refresh(completion: @escaping (Error?) -> Void) {
		ApiManager.shared.getStories(from: storyList) { (result) in
			switch result {
			case .success(let stories):
				StoryLoader.shared.invalidateCache(for: self.data.map(\.id))
				self.data = stories
				self.tableView.reloadData()
				completion(nil)
			case .failure(let error):
				completion(error)
			}
		}
	}
	
	/// Fetches the list without invalidating cache
	func selectList(_ list: StoryList, completion: @escaping (Error?) -> Void) {
		self.storyList = list
		ApiManager.shared.getStories(from: list) { (result) in
			switch result {
			case .success(let stories):
				self.data = stories
				self.tableView.reloadData()
				completion(nil)
			case .failure(let error):
				completion(error)
			}
		}
	}
	
	func storyDetailViewModel(for indexPath: IndexPath) -> StoryDetailItemListViewModel {
		let story = data(at: indexPath)
		return .init(story: story)
	}
	
	
	// MARK: - Tableview delegate
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		didSelectRowAt(indexPath)
	}
	
	
	// MARK: - Tableview data source
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		data.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let story = data(at: indexPath)
		story.load { (source, _) in // Load from cache if available before setting the cells properties
			if source == .remote { // If it was from remote this will be called in the future and when received reload the cell to update the cell
				self.reloadItem(at: indexPath)
			}
		}
		let cell = self.dequeueReusableCell(in: tableView, at: indexPath)
		cell.story = story
		return cell
	}
}
