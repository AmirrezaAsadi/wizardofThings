//
//  ChatGPTClient.swift
//  WizardofHome
//
//  Created by Amir on 1/30/24.
//

import Foundation

class ChatGPTClient {
    let networkManager = NetworkManager() // Assuming this is a custom class for handling network requests
    let apiURL = URL(string: "https://api.openai.com/v1/chat/completions")! // Ensure this is the correct URL for the Chat API
    let apiKey = "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" // Replace with your actual API key

    func sendMessage(_ message: String, completion: @escaping (String) -> Void) {
        let requestBody: [String: Any] = [
            "model": "gpt-4-turbo-preview", // Make sure this model name is correct
            "messages": [
                ["role": "user", "content": message]
            ],
            "temperature": 1.0,
            "max_tokens": 256,
            "top_p": 1.0,
            "frequency_penalty": 0.0,
            "presence_penalty": 0.0
        ]
        guard let bodyData = try? JSONSerialization.data(withJSONObject: requestBody, options: []) else {
            completion("Failed to create request body")
            return
        }

        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyData

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion("Network error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            // Debugging aid: Print the raw data as a string
            if let rawResponseString = String(data: data, encoding: .utf8) {
                print("Raw Response: \(rawResponseString)")
            }

            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let choices = jsonResponse["choices"] as? [[String: Any]],
                   !choices.isEmpty,
                   let message = choices[0]["message"] as? [String: Any], // Adjust based on actual structure
                   let content = message["content"] as? String {
                    completion(content)
                } else {
                    completion("Failed to parse response: Unexpected structure")
                }
            } catch {
                completion("Error parsing response: \(error.localizedDescription)")
            }
        }
        task.resume()
    }
}
