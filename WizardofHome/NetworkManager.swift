//
//  NetworkManager.swift
//  WizardofHome
//
//  Created by Amir on 1/30/24.
//

import Foundation
struct NetworkManager {
    func sendRequest(to url: URL, with body: Data, headers: [String: String], completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        headers.forEach { request.addValue($1, forHTTPHeaderField: $0) }

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                completion(data, response, error)
            }
        }.resume()
    }
}
