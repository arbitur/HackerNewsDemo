//
//  Loaders.swift
//  SampleApp
//
//  Created by Philip Fryklund on 2021-02-19.
//  Copyright © 2021 Philip Fryklund. All rights reserved.
//

import Foundation



enum LoaderResultSource {
	case local
	case remote
}

/**
	Class for fetching data from either local cashe or remote.
	`Key` is the unique identifier for a value.
	Denpends on a `LoaderFetcher` to handle fetching from remote.
	
*/
class Loader<Key: Hashable, Value> {
		
	private var cache: [Key: Value] = [:]
	fileprivate let fetcher: LoaderFetcher<Key, Value>
	init(fetcher: @escaping LoaderFetcher<Key, Value>.Fetch) {
		self.fetcher = .init(fetch: fetcher)
	}
	
	/// Fetch a value by key and receive a result and from what source the value came from.
	func fetch(for key: Key, completion: @escaping (LoaderResultSource, Result<(Value), Error>) -> Void) {
		if let item = cache[key] {
			completion(.local, .success(item))
		}
		else {
			fetcher.fetch(forKey: key) { (result) in
				if case let .success(value) = result {
					self.cache[key] = value
				}
				completion(.remote, result)
			}
		}
	}
	
	func invalidateCache() {
		cache = [:]
	}
	
	func invalidateCache(for keys: Key...) {
		invalidateCache(for: keys)
	}
	func invalidateCache(for keys: [Key]) {
		for key in keys {
			cache.removeValue(forKey: key)
		}
	}
}

// MARK: - Fetcher

/**
	Class accompanying Loader with matching generic parameters.
	Makes sure only one concurring http request is made per Key while still responding to every instance asking for the same Value
*/
class LoaderFetcher<Key: Hashable, Value> {
	
	/// The fetch result as viewed from the outside
	typealias Result = Swift.Result<Value, Error>
	/// Function type that takes 2 parameters, a Key and an escaping function which takes a Result as parameter
	typealias Fetch = (Key, @escaping (Result) -> Void) -> Void
	/// Definition of the FetchTask
	private typealias FetchTask = LoaderFetchTask<Result>
	
	/// Pending tasks for a Key to be reused if another instance requests the same value so not more than one request is made
	private var tasks: [Key: FetchTask] = [:]
	/// The function that does the actual http request
	private let fetch: Fetch
	
	init(fetch: @escaping Fetch) {
		self.fetch = fetch
	}
	
	func fetch(forKey key: Key, completion: @escaping (Result) -> Void) {
		if let task = tasks[key] {
			task.subscribe(subscriber: completion)
		}
		else {
			let task = FetchTask()
			task.subscribe(subscriber: completion)
			fetch(key) { result in
				task.publish(with: result)
				self.tasks.removeValue(forKey: key) // Remove the task for allowing a new request for the Key can be a made
			}
			tasks[key] = task
		}
	}
}


// MARK: - Fetcher task

/**
	Used by LoaderFetcher to store listeners of a request
*/
private class LoaderFetchTask<Result> {
	
	typealias Subscriber = (Result) -> Void
	private var subscribers: [Subscriber] = []
	
	fileprivate func publish(with result: Result) {
		subscribers.forEach {
			$0(result)
		}
	}
	
	fileprivate func subscribe(subscriber: @escaping Subscriber) {
		subscribers.append(subscriber)
	}
}
