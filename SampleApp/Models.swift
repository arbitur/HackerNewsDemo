//
//  Models.swift
//  SampleApp
//
//  Created by Philip Fryklund on 4/Oct/19.
//  Copyright © 2019 Philip Fryklund. All rights reserved.
//

import Foundation


// MARK: - Item


/// Base Hackernews Item class
protocol Item: class, Decodable {
	
	/// Unique identifier for item
	var id: Int { get }
	
	/// Serialize json response into properties based on sub class
	func merge(with obj: Self)
}


// MARK: - Story

enum StoryList: String {
	case top = "v0/topstories"
	case new = "v0/newstories"
	case best = "v0/beststories"
}

final class Story: Item {
	
	enum CodingKeys: String, CodingKey {
		case id
		case score
		case title
		case numberOfComments = "descendants"
		case topCommentIds = "kids"
		case author = "by"
		case date = "time"
		case url
	}
	
	let id: Int
	private(set) var score: Int?
    private(set) var title: String?
	private(set) var numberOfComments: Int?
	/// The first comment of each discussion (comments to comments) within the story
	private(set) var topCommentIds: [Int]?
	private(set) var author: String?
	private(set) var date: Date?
	private(set) var url: URL?
	
	
	init(id: Int) {
		self.id = id
	}
	
	func merge(with obj: Story) {
		score = obj.score
		title = obj.title
		numberOfComments = obj.numberOfComments ?? 0
		topCommentIds = obj.topCommentIds
		author = obj.author
		date = obj.date
		url = obj.url
	}
	
	func load(completion: @escaping (LoaderResultSource, Error?) -> Void) {
		StoryLoader.shared.fetch(for: id) { (source, result) in
			switch result {
			case .success(let story):
				self.merge(with: story)
				completion(source, nil)
			case .failure(let error):
				completion(source, error)
			}
		}
	}
}


final class StoryLoader: Loader<Int, Story> {
	
	static let shared = StoryLoader() { (id, callback) in
		ApiManager.shared.getItem(with: id, completion: callback)
	}
}


// MARK: - Comment

final class Comment: Item {
	
	enum CodingKeys: String, CodingKey {
		case id
		case text
		case answeres = "kids"
		case author = "by"
		case date = "time"
	}
	
	let id: Int
    private(set) var text: String?
	private(set) var answeres: [Comment]?
	private(set) var author: String?
	private(set) var date: Date?
	
	var numberOfAnsweres: Int {
		answeres?.count ?? 0
	}
	
	init(id: Int) {
		self.id = id
	}
	
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		id = try container.decode(.id)
		text = try container.decodeIfPresent(.text) ?? "[Deleted]"
		answeres = try container.decodeIfPresent(.answeres, type: [Int].self)?.map(Comment.init(id:))
		author = try container.decodeIfPresent(.author) ?? "[Deleted]"
		date = try container.decode(.date)
	}
	
	func merge(with obj: Comment) {
		text = obj.text
		answeres = obj.answeres
		author = obj.author
		date = obj.date
	}
	
	func load(completion: @escaping (LoaderResultSource, Error?) -> Void) {
		CommentLoader.shared.fetch(for: id) { (source, result) in
			switch result {
			case .success(let comment):
				self.merge(with: comment)
				completion(source, nil)
			case .failure(let error):
				completion(source, error)
			}
		}
	}
}


final class CommentLoader: Loader<Int, Comment> {
	
	static let shared = CommentLoader() { (id, callback) in
		ApiManager.shared.getItem(with: id, completion: callback)
	}
}
