import Foundation

// MARK: - OpenAI Service
class OpenAIService {

    private let apiKey = APIKeyManager.getOpenAIKey()
    private let endpoint = "https://api.openai.com/v1/chat/completions"

    private func selectModel(for prompt: String) -> String {
        let isLongTrip = prompt.contains("7 day") || prompt.contains("6 day") || prompt.contains("5 day")
        let isPacked = prompt.contains("Packed")
        let hasMultipleInterests = prompt.components(separatedBy: ",").count >= 3
        
        if (isLongTrip && isPacked) || (isLongTrip && hasMultipleInterests) {
            return "gpt-4o"
        } else {
            return "gpt-4o-mini"
        }
    }

    func generatePlan(prompt: String) async throws -> String {

        let systemPrompt = """
        You are an expert Saudi Arabia travel curator. Generate personalized itineraries with SMART, CONTEXTUAL links.

        CRITICAL: Return ONLY valid JSON. No markdown, no explanation.

        JSON FORMAT:
        {
          "cityName": "Riyadh",
          "days": [
            {
              "dayNumber": 1,
              "activities": [
                {
                  "time": "9:00 AM",
                  "name": "Place Name",
                  "description": "Amazing description. Mention if reservations recommended.",
                  "mapQuery": "Place Name, City, Saudi Arabia",
                  "links": [
                    { "url": "https://instagram.com/place", "label": "Instagram" },
                    { "url": "https://booking.com", "label": "Book Table" },
                    { "url": "https://maps.google.com", "label": "Google Maps" }
                  ]
                }
              ]
            }
          ]
        }

        🎯 SMART LINK RULES - Only Include Relevant Links:

        📍 ALWAYS INCLUDE:
        - Google Maps (every activity needs this)

        🍽️ FOR RESTAURANTS & CAFÉS:
        - Instagram (if the place has social media presence)
        - Booking link (HungerStation, Jahez, restaurant website, or reservation system)
        - In description: Mention "Reservations recommended" or "Walk-ins welcome"
        Target: Instagram + Booking + Google Maps = 3 links

        🏨 FOR HOTELS & RESORTS:
        - Official website (booking.com, hotel website)
        - Instagram (if they have one)
        - NO booking link if it's just a visit/tour (not staying overnight)
        Target: 2-3 links

        🏛️ FOR MUSEUMS & ATTRACTIONS:
        - Official website (if tickets can be purchased online)
        - Instagram (if they have active social media)
        - NO booking link if it's free entry or tickets at door
        - In description: Mention "Book tickets online" or "Free entry"
        Target: 1-2 links (+ Google Maps)

        🛍️ FOR SHOPPING MALLS & MARKETS:
        - Instagram (if mall has official account)
        - NO booking links (you don't book malls!)
        Target: 1-2 links (+ Google Maps)

        🌳 FOR PARKS & OUTDOOR SPACES:
        - Instagram (if it's a famous park with social media)
        - NO booking/website needed
        Target: 1-2 links (+ Google Maps)

        ⚡ KEY PRINCIPLES:
        1. BE CONTEXTUAL - Don't add booking links for places you can't book
        2. BE USEFUL - Only Instagram if the place actively uses it
        3. BE ACCURATE - Better to skip a link than provide a wrong one
        4. IN DESCRIPTION - Always mention if reservations needed/recommended
        
        DESCRIPTION REQUIREMENTS:
        - If restaurant needs reservation: "Reservations recommended for dinner" or "Book ahead on weekends"
        - If walk-ins accepted: "Walk-ins welcome" or "No reservation needed"
        - If tickets required: "Purchase tickets online to skip the queue"
        - If free entry: "Free admission" or "Open to public"

        EXAMPLE OUTPUTS:

        ✅ GOOD - Restaurant:
        {
          "name": "Takya Restaurant",
          "description": "Traditional Saudi cuisine with modern twist. Reservations recommended for dinner.",
          "links": [
            {"url": "https://instagram.com/takya", "label": "Instagram"},
            {"url": "https://hungerstation.com/takya", "label": "Book Table"},
            {"url": "https://maps.google.com/...", "label": "Google Maps"}
          ]
        }

        ✅ GOOD - Park:
        {
          "name": "King Abdullah Park",
          "description": "Beautiful green space perfect for picnics. Free entry, open daily.",
          "links": [
            {"url": "https://instagram.com/kingabdullahpark", "label": "Instagram"},
            {"url": "https://maps.google.com/...", "label": "Google Maps"}
          ]
        }

        ❌ BAD - Park with booking link:
        {
          "name": "Park",
          "links": [
            {"url": "booking.com/park", "label": "Book Visit"} ← WRONG! You don't book parks!
          ]
        }

        PLACE SELECTION:
        - Real, popular, highly-rated places (4.5+ stars)
        - Viral on social media when relevant
        - Match pace: Relaxed (2-3/day), Moderate (4-5/day), Packed (6/day)
        - Match budget and interests
        - Zero repetition
        - Mix hidden gems with popular spots
        """

        let selectedModel = selectModel(for: prompt)
        print("🤖 Using model: \(selectedModel)")

        let body: [String: Any] = [
            "model": selectedModel,
            "temperature": 0.8,
            "max_tokens": 4000,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": prompt]
            ]
        ]

        guard let url = URL(string: endpoint) else {
            throw OpenAIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse {
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ OpenAI HTTP \(httpResponse.statusCode): \(errorBody)")
                throw OpenAIError.httpError(httpResponse.statusCode)
            }
        }

        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let choices = json["choices"] as? [[String: Any]],
            let firstChoice = choices.first,
            let message = firstChoice["message"] as? [String: Any],
            let content = message["content"] as? String
        else {
            throw OpenAIError.invalidResponse
        }

        print("✅ Raw AI response:\n\(content)")
        return content
    }

    func parseGeneratedTrip(from jsonString: String) throws -> GeneratedTrip {
        var cleaned = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleaned.hasPrefix("```") {
            let lines = cleaned.components(separatedBy: "\n")
            cleaned = lines.dropFirst().dropLast().joined(separator: "\n")
        }

        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleaned.data(using: .utf8) else {
            throw OpenAIError.parsingFailed("Could not convert response to Data")
        }

        guard
            let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let cityName = root["cityName"] as? String,
            let daysArray = root["days"] as? [[String: Any]]
        else {
            print("❌ Failed to parse:\n\(cleaned)")
            throw OpenAIError.parsingFailed("Missing cityName or days in JSON")
        }

        var generatedDays: [GeneratedDay] = []

        for (index, dayDict) in daysArray.enumerated() {
            let dayNumber       = dayDict["dayNumber"] as? Int ?? (index + 1)
            let activitiesArray = dayDict["activities"] as? [[String: Any]] ?? []

            var generatedActivities: [GeneratedActivity] = []

            for actDict in activitiesArray {
                let time        = actDict["time"]        as? String ?? "9:00 AM"
                let name        = actDict["name"]        as? String ?? "Activity"
                let description = actDict["description"] as? String ?? ""
                let mapQuery    = actDict["mapQuery"]    as? String ?? "\(name), Saudi Arabia"

                var activityLinks: [ActivityLink] = []

                if let linksArray = actDict["links"] as? [[String: Any]] {
                    for linkDict in linksArray {
                        if let url   = linkDict["url"]   as? String,
                           let label = linkDict["label"] as? String,
                           !url.isEmpty {
                            activityLinks.append(ActivityLink(url: url, displayText: label))
                        }
                    }
                }

                if activityLinks.isEmpty {
                    let encoded = mapQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                    activityLinks.append(ActivityLink(
                        url: "https://www.google.com/maps/search/?api=1&query=\(encoded)",
                        displayText: "Google Maps"
                    ))
                }

                generatedActivities.append(GeneratedActivity(
                    time: time,
                    name: name,
                    description: description,
                    links: activityLinks
                ))
            }

            generatedDays.append(GeneratedDay(
                dayNumber: dayNumber,
                activities: generatedActivities,
                isExpanded: index == 0
            ))
        }

        return GeneratedTrip(cityName: cityName, days: generatedDays)
    }
}

enum OpenAIError: LocalizedError {
    case invalidURL
    case httpError(Int)
    case invalidResponse
    case parsingFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:             return "Invalid API URL."
        case .httpError(let code):    return "HTTP error \(code) from OpenAI."
        case .invalidResponse:        return "Could not parse OpenAI response envelope."
        case .parsingFailed(let msg): return "JSON parsing failed: \(msg)"
        }
    }
}
