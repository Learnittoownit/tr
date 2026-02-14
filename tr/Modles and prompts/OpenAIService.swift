import Foundation

// MARK: - OpenAI Service
class OpenAIService {

    private let apiKey = "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"
    private let endpoint = "https://api.openai.com/v1/chat/completions"

    private func selectModel(for prompt: String) -> String {
        // Parse the prompt to detect complexity
        let isLongTrip = prompt.contains("7 day") || prompt.contains("6 day") || prompt.contains("5 day")
        let isPacked = prompt.contains("Packed")
        let hasMultipleInterests = prompt.components(separatedBy: ",").count >= 3
        
        // Use the powerful model for complex requests
        if (isLongTrip && isPacked) || (isLongTrip && hasMultipleInterests) {
            return "gpt-4o" // More powerful, better quality for complex trips
        } else {
            return "gpt-4o-mini" // Fast and cheap for simple trips
        }
    }

    // MARK: - Main entry point
    func generatePlan(prompt: String) async throws -> String {

        let systemPrompt = """
        You are an expert Saudi Arabia travel curator who knows every hidden gem, trendy café, viral attraction, and top-rated experience in Riyadh, Jeddah, and Abha.

        Your job is to generate a personalized, day-by-day travel itinerary based on the user's preferences.

        CRITICAL OUTPUT RULE:
        - Return ONLY a single valid JSON object
        - No markdown, no code fences, no explanation text, nothing before or after the JSON
        - The JSON must be perfectly parseable

        EXACT JSON STRUCTURE:
        {
          "cityName": "Riyadh",
          "days": [
            {
              "dayNumber": 1,
              "activities": [
                {
                  "time": "9:00 AM",
                  "name": "Place Name",
                  "description": "Why this place is amazing. Max 2 sentences.",
                  "mapQuery": "Place Name, City, Saudi Arabia",
                  "links": [
                    { "url": "https://www.instagram.com/placename", "label": "Instagram" },
                    { "url": "https://www.google.com/maps/search/?api=1&query=Place+Name+City", "label": "Google Maps" }
                  ]
                }
              ]
            }
          ]
        }

        LINK RULES — ABSOLUTE ACCURACY REQUIRED:
        - Every link you provide MUST be real, verified, and currently active
        - NEVER invent, guess, or create placeholder URLs
        - Only include a link if you are 100% certain it exists and works today
        - Acceptable link types (ONLY if verified):
          * Google Maps (always safe, always works)
          * Instagram accounts (ONLY if you know the exact handle exists)
          * Official websites (ONLY if you've seen them mentioned in reliable sources)
          * Booking platforms (ONLY verified restaurant reservation systems)
          * WhatsApp business numbers (ONLY if publicly listed)
          * TikTok accounts (ONLY verified business accounts)
          
        - Link priority order:
          1. Google Maps (REQUIRED for every activity)
          2. Instagram (only if 100% certain the handle is correct)
          3. Official website (only if you know it exists)
          4. Booking/contact (only if publicly available)

        - CRITICAL RULES:
          * If you're not absolutely certain a link works, DON'T include it
          * One accurate link is better than three broken links
          * For restaurants/cafés: search "restaurant name + Riyadh + Instagram" mentally — if uncertain, skip it
          * For attractions: if no official site, just use Google Maps
          * NEVER create example URLs like "example.com" or "placeholder.sa"
          * Test your confidence: Would you bet money this link works? If no, don't include it

        - Format each link clearly:
          * "Google Maps" - always include
          * "Instagram @username" - only if certain
          * "Official Website" - only if certain  
          * "Book via WhatsApp" - only if you know the number
          * "Reserve Table" - only if booking system exists

        VERIFICATION STANDARD: Imagine you're being graded on link accuracy. Every broken link = immediate failure. Only include links you would stake your reputation on.
        QUALITY RULES:
        1. REAL PLACES ONLY — no invented names, no generic placeholders
        2. TRENDY & HIGH-RATED — prioritize places that are:
           - Currently viral on Saudi social media (Instagram, Snapchat, TikTok)
           - Have 4.5+ stars on Google Maps
           - Featured in travel blogs or Saudi tourism guides
           - Popular among locals AND tourists
           - Use your FULL knowledge of each city — do NOT limit yourself to any specific list
           - Think beyond the obvious landmarks: include hidden gems, new openings, 
             neighborhood favorites, rooftop spots, scenic drives, local markets, 
             art galleries, cultural festivals, scenic parks, beachside spots, 
             mountain trails, heritage districts, concept stores, specialty coffee shops,
             and any place that would genuinely excite a traveler
           - For Riyadh: explore all districts — Diriyah, KAFD, Al Olaya, Hittin, 
             Al Malqa, Al Aqiq, Diplomatic Quarter, Al Bujairi, Boulevard, and beyond
           - For Jeddah: explore Al-Balad, Corniche, Al Rawdah, Al Zahra, Al Andalus, 
             Al Hamra, waterfront, and beyond
           - For Abha: explore the mountains, heritage villages, valleys, parks, 
             local restaurants, art spaces, and beyond
           - Never repeat the same type of place twice in a row
        3. ZERO REPETITION — every activity across ALL days must be a unique place
        4. MATCH PACE — Relaxed: 2-3/day, Moderate: 4-5/day, Packed: 6/day
        5. MATCH BUDGET — Budget: free/cheap spots, Mid-Range: nice venues, Luxury: premium/fine dining
        6. MATCH COMPANION — Solo: independent spots, Couple: romantic venues, Family: kid-friendly, Friends: social hubs
        7. MATCH INTERESTS — Cultural: heritage/museums, Adventure: nature/hiking, Relaxation: spas/parks, Shopping: malls/boutiques, Food: top restaurants/cafés
        8. SMART TIMING — outdoors in morning, lunch at noon, dinner in evening
        9. EXCITING DESCRIPTIONS — write like a friend who loves this place, max 2 punchy sentences
        10. PRECISE MAP QUERIES — full name + city + Saudi Arabia
        """

        let selectedModel = selectModel(for: prompt)
        print("🤖 Using model: \(selectedModel)")

        let body: [String: Any] = [
            "model": selectedModel,            "temperature": 0.8,
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

    // MARK: - Parse JSON into GeneratedTrip
    func parseGeneratedTrip(from jsonString: String) throws -> GeneratedTrip {

        var cleaned = jsonString
            .trimmingCharacters(in: .whitespacesAndNewlines)

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

                // Parse rich links array from AI
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

                // Fallback: build Google Maps link if AI gave nothing
                if activityLinks.isEmpty {
                    let encoded = mapQuery
                        .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
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

// MARK: - Error Types
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
