//
//  ApiManager.swift
//  SampleApp
//
//  Created by Philip Fryklund on 2021-02-19.
//  Copyright © 2021 Philip Fryklund. All rights reserved.
//

import Foundation
import Combine


/**
	Handles http requests and serialization of models
*/
final class ApiManager {
	
	static let shared = ApiManager()
	private init() {} // Disallows outsiders from instantiating new api managers
	
	private func responseDecodable <T: Decodable, D: TopLevelDecoder> (request: URLRequest, decoder: D, completion: @escaping (Result<T, Error>) -> Void) -> URLSessionDataTask where D.Input == Data {
		URLSession.shared.dataTask(with: request) { (data, _, error) in
			if let error = error {
				return DispatchQueue.main.async {
					completion(.failure(error))
				}
			}
			guard let data = data, !data.isEmpty else {
				return DispatchQueue.main.async {
					completion(.failure(URLError(URLError.Code.badServerResponse)))
				}
			}
			
			do {
				let obj = try decoder.decode(T.self, from: data) // Decode on background thread in case its a heavy decode
				DispatchQueue.main.async {
					completion(.success(obj))
				}
			}
			catch {
				DispatchQueue.main.async {
					completion(.failure(error))
				}
			}
		}
	}
	
	/// Fetch the stories in specified `list`
	func getStories(from list: StoryList, completion: @escaping (Result<[Story], Error>) -> Void) {
		let url = URL(string: "https://hacker-news.firebaseio.com/\(list.rawValue).json")!
		let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 10)
		responseDecodable(request: request, decoder: JSONDecoder()) { (result: Result<[Int], Error>) in
			completion(result.map { $0.map(Story.init) })
		}.resume()
	}
	
	/// Fetch a hacker news Item
	func getItem <T: Item> (_ type: T.Type = T.self, with id: Int, completion: @escaping (Result<T, Error>) -> Void) {
		let url = URL(string: "https://hacker-news.firebaseio.com/v0/item/\(id).json")!
		let request = URLRequest(url: url, cachePolicy: .reloadRevalidatingCacheData, timeoutInterval: 10)
		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = .secondsSince1970
		responseDecodable(request: request, decoder: decoder, completion: completion).resume()
	}
}
