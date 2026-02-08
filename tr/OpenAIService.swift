import Foundation

class OpenAIService {

    private let apiKey = "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" // حطي الـ API Key حقك

    func generatePlan(prompt: String) async throws -> String {

        let url = URL(string: "https://api.openai.com/v1/chat/completions")!

        let body: [String: Any] = [
            "model": "gpt-5-mini",
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: body)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        let (data, _) = try await URLSession.shared.data(for: request)

        let response = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let choices = response?["choices"] as? [[String: Any]]
        let message = choices?.first?["message"] as? [String: Any]

        return message?["content"] as? String ?? "No response"
    }
}

