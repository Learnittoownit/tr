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
        You are an expert Saudi Arabia travel curator. Generate accurate itineraries with VERIFIED links only.

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
                  "name": "Najd Village Restaurant",
                  "description": "Traditional Saudi cuisine in authentic setting. Reservations recommended for dinner.",
                  "mapQuery": "Najd Village Restaurant, Al Takhassusi, Riyadh, Saudi Arabia",
                  "links": [
                    { "url": "https://www.google.com/maps/search/?api=1&query=Najd+Village+Restaurant+Riyadh", "label": "Google Maps" },
                    { "url": "https://hungerstation.com/sa/restaurant/najd-village", "label": "Book Table" }
                  ]
                }
              ]
            }
          ]
        }

        🎯 SIMPLE LINK RULES:

        FOR RESTAURANTS & CAFÉS ONLY:
        ✅ Google Maps (REQUIRED - use exact name + district + city)
        ✅ Booking Website (ONLY if you are 100% CERTAIN it exists and is widely used)
           - Popular platforms: HungerStation, Jahez, OpenTable, Reserveout
           - Restaurant's own booking site (ONLY if you KNOW it exists)
           - If uncertain about booking link → SKIP IT, just give Google Maps

        FOR EVERYTHING ELSE (Parks, Museums, Malls, Hotels, Attractions):
        ✅ Google Maps ONLY
           - No booking links
           - No official websites
           - Just accurate Google Maps

        ❌ NEVER INCLUDE:
        - Instagram, TikTok, Twitter, WhatsApp, or ANY social media
        - Guessed or uncertain URLs
        - Generic booking.com links
        - Unverified websites

        🎯 GOOGLE MAPS ACCURACY (VERY IMPORTANT):
        - Use FULL official name of the place
        - Include district/neighborhood name
        - Include city name
        - Examples:
          * "Najd Village Restaurant, Al Takhassusi Street, Riyadh, Saudi Arabia"
          * "The Globe Restaurant, Al Faisaliyah Tower, Riyadh, Saudi Arabia"
          * "Lusin Restaurant, Tahlia Street, Jeddah, Saudi Arabia"
          * "National Museum of Saudi Arabia, King Abdulaziz Historical Center, Riyadh, Saudi Arabia"
          * "Al Nakheel Mall, Riyadh, Saudi Arabia"

        BOOKING LINK VERIFICATION (Restaurants/Cafés only):
        - Only include if you are ABSOLUTELY certain the link is real and active
        - Popular chains (Starbucks, McDonald's, local chains) → you can confidently add HungerStation/Jahez
        - Independent restaurants → ONLY if you know they have a verified booking system
        - When in doubt → SKIP the booking link, just give Google Maps

        DESCRIPTION REQUIREMENTS:
        - For restaurants: Mention if "Reservations recommended" or "Walk-ins welcome"
        - For attractions: Mention "Free entry" or "Tickets required"
        - Keep it 2 sentences maximum

        QUALITY RULES:
        - Real, operational places only (4.5+ stars on Google Maps)
        - Currently open (not closed/under construction)
        - Match user preferences: pace, budget, interests
        - No repetition across all days
        - Mix famous spots with hidden gems

        REMEMBER: 1 accurate link is better than 3 broken links!
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
