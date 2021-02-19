//
//  ItemListViewModel.swift
//  SampleApp
//
//  Created by Philip Fryklund on 3/Oct/19.
//  Copyright © 2019 Philip Fryklund. All rights reserved.
//

import UIKit


/// Base view model for hacker news item lists
protocol ItemListViewModel: class, UITableViewDataSource, UITableViewDelegate {
	
	associatedtype Cell: TableViewCellLoadable
	
	associatedtype Model: Item
	var data: [Model] { get }
	
	var tableView: UITableView! { get }
}

extension ItemListViewModel {
	
	func reloadItem(at indexPath: IndexPath) {
		tableView.reloadRows(at: [indexPath], with: .automatic)
	}
	
	func data(at indexPath: IndexPath) -> Model {
		data[indexPath.row]
	}
	
	func dequeueReusableCell(in tableView: UITableView, at indexPath: IndexPath) -> Cell {
		let cell = tableView.dequeueReusableCell(cellLoadable: Cell.self, for: indexPath)
		return cell
	}
}
