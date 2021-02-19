//
//  Extensions.swift
//  SampleApp
//
//  Created by Philip Fryklund on 4/Oct/19.
//  Copyright © 2019 Philip Fryklund. All rights reserved.
//

import UIKit



extension UIViewController {
	
	func presentError(title: String = "Error", error: Error, configureAlert configure: ((UIAlertController) -> Void)? = nil) {
		let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
		configure?(alert)
		alert.addAction(.init(title: "OK", style: .cancel, handler: nil))
		self.present(alert, animated: true, completion: nil)
	}
}


//MARK: - Table view extension

extension UITableView {
	
	/// `tableHeaderView` doesnt work automatically with autolayout so we have to update do it manually so it gets the correct size
	func updateTableHeaderViewFrameWithAutoLayout() {
		self.tableHeaderView.map {
			self.setTableHeaderViewWithAutoLayout($0)
		}
	}
	
	/// `tableHeaderView` doesnt work automatically with autolayout so we have to update do it manually so it gets the correct size
	func setTableHeaderViewWithAutoLayout(_ view: UIView) {
		if self.tableHeaderView !== view {
			self.tableHeaderView = view // Put the new view in the view hierarchy so it can size properly
		}
		view.setNeedsLayout()
		view.layoutIfNeeded()
		view.frame.size = view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
		self.tableHeaderView = view // Resubmit the view to the tableview so the tableview updates it layout
	}
	
	
	/// Animates refresh control and scrolls scrollView downwards so it gets displayed properly
	@discardableResult
	func beginAnimateRefreshControl() -> UIRefreshControl? {
		guard let refreshControl = self.refreshControl else {
			return nil
		}
		
		refreshControl.beginRefreshing()
		self.setContentOffset(CGPoint(x: 0, y: self.contentOffset.y - (refreshControl.frame.height)), animated: true)
		
		return refreshControl
	}
}


//MARK: - Date extension

/// Caches unique dateformatters dynamically based on their styles
fileprivate var dateFormatters = [Date.DateStylingKey: DateFormatter]()

extension Date {
	
	/// Construct a unique key for date style combinations
	fileprivate struct DateStylingKey: Hashable {
		let dateStyle: DateFormatter.Style
		let timeStyle: DateFormatter.Style
	}
	
	/// Convenience method for formatting a date
	func format(date dateStyle: DateFormatter.Style, time timeStyle: DateFormatter.Style, locale: Locale = .current) -> String {
		let dateStyling = DateStylingKey(dateStyle: dateStyle, timeStyle: timeStyle)
		let formatter = dateFormatters[dateStyling] ?? DateFormatter().apply {
			$0.dateStyle = dateStyle
			$0.timeStyle = timeStyle
			dateFormatters[dateStyling] = $0
		}
		if formatter.locale != locale {
			formatter.locale = locale
		}
		return formatter.string(from: self)
	}
}


// MARK: - Decodable

// Conveniences
extension KeyedDecodingContainer {
	
	public func decode <T: Decodable> (_ key: Key, type: T.Type = T.self) throws -> T {
		return try self.decode(type, forKey: key)
	}
	
	public func decodeIfPresent <T: Decodable> (_ key: Key, type: T.Type = T.self) throws -> T? {
		return try decodeIfPresent(type, forKey: key)
	}
}



// MARK: - Apply

protocol Appliable: class { }
extension Appliable {
	
	/// Kotlin apply function
	@discardableResult
	func apply(closure: (Self) -> Void) -> Self {
		closure(self)
		return self
	}
}
extension NSObject: Appliable {}



// MARK: - UITableViewCell loadable

/// Allows class to define how it is being initialized, most convenient if cell is stand-alone i.e initialized from a .xib
protocol TableViewCellLoadable: UITableViewCell {
	
	static var identifier: String { get }
	static var nib: UINib? { get }
}

extension TableViewCellLoadable {
	
	static var identifier: String {
		"\(Self.self)"
	}
	
	static var nib: UINib? {
		nil
	}
}

extension UITableView {
	
	func register(_ cellLoadable: TableViewCellLoadable.Type) {
		if let nib = cellLoadable.nib {
			self.register(nib, forCellReuseIdentifier: cellLoadable.identifier)
		}
		else {
			self.register(cellLoadable, forCellReuseIdentifier: cellLoadable.identifier)
		}
	}
	
	func dequeueReusableCell <T: TableViewCellLoadable> (cellLoadable: T.Type, for indexPath: IndexPath) -> T {
		self.dequeueReusableCell(withIdentifier: cellLoadable.identifier, for: indexPath) as! T
	}
}
