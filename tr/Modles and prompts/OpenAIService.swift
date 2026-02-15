import Foundation

// MARK: - OpenAI Service
class OpenAIService {

    private let apiKey = APIKeyManager.getOpenAIKey()
    private let endpoint = "https://api.openai.com/v1/chat/completions"

    private func selectModel(for prompt: String) -> String {
        return "gpt-4o"
    }

    func generatePlan(prompt: String) async throws -> String {

        let systemPrompt = """
        You are an EXPERT Saudi Arabia travel curator with DEEP, UP-TO-DATE knowledge of trendy spots in Riyadh, Jeddah, and Abha.

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
                  "name": "Specialty Coffee Shop Name",
                  "description": "What makes this place amazing and why it's trending. Keep it exciting and concise.",
                  "mapQuery": "Full Place Name, District, Riyadh, Saudi Arabia",
                  "links": [
                    { "url": "https://www.google.com/maps/search/?api=1&query=Place+Name+District+Riyadh", "label": "Google Maps" }
                  ]
                }
              ]
            }
          ]
        }

        🎯 LINK RULES - ULTRA SIMPLE:
        ✅ Google Maps ONLY for ALL activities
        ❌ NO booking links, NO websites, NO social media, NO additional links
        
        Every activity gets EXACTLY ONE link: Google Maps

        🎯 GOOGLE MAPS ACCURACY (CRITICAL):
        - Use FULL official name
        - Include district/neighborhood
        - Include city name
        - Format: "Place Name, District, City, Saudi Arabia"

        ☕ CAFÉS & COFFEE - FIND THE TRENDIEST SPOTS:

        When user selects "Cafés & Coffee", you MUST find:

        **CURRENT TRENDING CAFÉS:**
        - Use your FULL knowledge of Saudi café culture
        - Third-wave specialty coffee shops with skilled baristas
        - Places viral on Saudi social media RIGHT NOW
        - Cafés that opened recently (2023-2025) with modern concepts
        - Popular among young Saudis and coffee enthusiasts
        - Known for: exceptional coffee, latte art, aesthetic interiors, unique concepts

        **WHAT TO LOOK FOR:**
        ✅ Specialty coffee with single-origin beans
        ✅ Instagrammable, aesthetic interiors
        ✅ Unique concepts (bookshop café, art café, garden café, rooftop)
        ✅ Signature drinks or viral menu items
        ✅ Places locals actually go to (not tourist traps)
        ✅ 4.5+ star ratings on Google Maps
        ✅ Recently opened or recently renovated spots

        **AVOID:**
        ❌ International chains (Starbucks, Costa, etc.)
        ❌ Old, outdated cafés from 5+ years ago
        ❌ Generic mall food court cafés
        ❌ Places with low ratings or bad reviews

        **CURATION STRATEGY:**
        - If user selected "Cafés & Coffee": 50%+ activities should be cafés
        - Mix types: specialty coffee → dessert café → unique themed café
        - Never repeat the same café across different days
        - Morning: Specialty coffee spots
        - Afternoon: Dessert/pastry cafés
        - Evening: Rooftop/garden cafés with ambiance
        - Match budget: Budget (affordable local), Mid-Range (trendy spots), Luxury (premium specialty)

        **USE YOUR COMPLETE KNOWLEDGE:**
        - Search your training data for the BEST, most current cafés
        - Think: "What would a 25-year-old Saudi coffee enthusiast visit?"
        - Include hidden gems that locals love
        - Find places featured in recent Saudi food/lifestyle blogs
        - Prioritize quality over famous names

        🎯 GENERAL PLACE SELECTION:
        - ONLY real, operational, currently popular places
        - 4.5+ star ratings minimum
        - Mix famous landmarks with hidden gems
        - Match user preferences: pace, budget, interests
        - Zero repetition across all days
        - Use FULL knowledge - don't limit yourself
        - For "Food & Culinary": Focus on restaurants
        - For "Cafés & Coffee": Focus on trendy cafés

        **DESCRIPTION QUALITY:**
        - For cafés: What they're known for + why they're popular (2 sentences max)
        - For restaurants: Cuisine type + signature dish or vibe
        - For attractions: What to expect + practical tip
        - Make it exciting and concise!

        **CRITICAL REMINDER:**
        You have extensive knowledge of Saudi Arabia. Use ALL of it to find the BEST places.
        Don't rely on old or generic recommendations. Find what's actually trending NOW.
        For cafés especially: quality is everything. Only recommend places you'd personally visit.
        """

        let selectedModel = selectModel(for: prompt)
        print("🤖 Using model: \(selectedModel)")

        let body: [String: Any] = [
            "model": selectedModel,
            "temperature": 0.2,
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
