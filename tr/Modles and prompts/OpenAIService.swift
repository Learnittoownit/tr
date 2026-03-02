import Foundation

// MARK: - Familiarity Tier
enum FamiliarityTier {
    case firstVisit      // "It's my first visit"
    case visitedBefore   // "I've visited before"
    case local           // "I'm a local here"

    init(from title: String) {
        switch title {
        case "I'm a local here":    self = .local
        case "I've visited before": self = .visitedBefore
        default:                    self = .firstVisit
        }
    }
}

// MARK: - OpenAI Service
class OpenAIService {

    private let apiKey = APIKeyManager.getOpenAIKey()
    private let endpoint = "https://api.openai.com/v1/chat/completions"

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Curated Place Dataset
    // Structure: City → Interest → Budget → [Place Names]
    // ONLY covers: Cafés & Coffee | Food & Dining | Shopping & Modern
    // Cultural & Historical, Adventure & Nature, Relaxation = fully AI-generated.
    // ─────────────────────────────────────────────────────────────────────────

    private let curatedPlaces: [String: [String: [String: [String]]]] = [

        "Riyadh": [

            "Cafés & Coffee": [
                "Budget-Friendly": [
                    "9th Street Coffee Roasters",
                    "Andarena",
                    "Barn's",
                    "Half Million",
                    "Camel Step Coffee Roasters"
                ],
                "Mid-Range": [
                    "Atmosphere Specialty Coffee",
                    "CARVE Coffee Bar",
                    "First Series Coffee",
                    "Wisdom Cafe",
                    "Elixir Bunn Coffee Roasters"
                ],
                "Luxury": [
                    "Urth Cafe",
                    "EL&N London",
                    "Angelina Paris",
                    "Ralph's Coffee"
                ]
            ],

            "Food & Dining": [
                "Budget-Friendly": [
                    "Mama Noura",
                    "Hamburgini",
                    "Shawarmer",
                    "AlBaik"
                ],
                "Mid-Range": [
                    "Piatto",
                    "Section-B",
                    "Burger Boutique",
                    "Najd Village"
                ],
                "Luxury": [
                    "MYAZU Riyadh",
                    "Kuuru",
                    "Spago Riyadh",
                    "Il Baretto Riyadh"
                ]
            ],

            "Shopping & Modern": [
                "Budget-Friendly": [
                    "Souq Al-Zal",
                    "Al Deira Market",
                    "Souq Al-Hilla"
                ],
                "Mid-Range": [
                    "Riyadh Park Mall",
                    "Riyadh Gallery Mall",
                    "Nakheel Mall",
                    "Panorama Mall"
                ],
                "Luxury": [
                    "Kingdom Centre Mall",
                    "Via Riyadh",
                    "U Walk Riyadh",
                    "Tahlia Street"
                ]
            ]
        ],

        "Jeddah": [

            "Cafés & Coffee": [
                "Budget-Friendly": [
                    "Vibes Cafe",
                    "Talent Cafe",
                    "Camel Step",
                    "Kyan Cafe",
                    "Dose Cafe",
                    "GoodHood Cafe"
                ],
                "Mid-Range": [
                    "BREW92",
                    "Cup & Couch",
                    "Hemi Cafe & Roastery",
                    "CLE Cafe",
                    "Urban Roastery",
                    "Cafecito Cafe",
                    "Medd Cafe & Roastery"
                ],
                "Luxury": [
                    "L'ETO Cafe",
                    "Urth Cafe",
                    "Overdose Cafe",
                    "Beauti Artisanal Cafe",
                    "Meraki Artisan Cafe",
                    "EL&N London Cafe",
                    "Angelina Paris Cafe"
                ]
            ],

            "Food & Dining": [
                "Budget-Friendly": [
                    "Al Baik",
                    "Al Romansiah",
                    "Al Saddah",
                    "Manoosha Alreef",
                    "Palm Beach Shawarma",
                    "Shawarmer",
                    "Section B"
                ],
                "Mid-Range": [
                    "Swiss Butter",
                    "Piatto",
                    "Portofino",
                    "Gather Restaurant",
                    "California Burger",
                    "The Cheesecake Factory"
                ],
                "Luxury": [
                    "MYAZU",
                    "Manko Jeddah",
                    "Niyyali",
                    "Amar Restaurant",
                    "Shababik",
                    "The Lucky Llama",
                    "Kuuru"
                ]
            ],

            "Shopping & Modern": [
                "Budget-Friendly": [
                    "Flamingo Mall",
                    "Al Andalus Mall",
                    "Aziz Mall",
                    "Al Salaam Mall",
                    "Souq Al Alawi",
                    "Souq Qabil",
                    "Corniche Commercial Center"
                ],
                "Mid-Range": [
                    "Mall of Arabia",
                    "Jeddah Park",
                    "Red Sea Mall",
                    "Jeddah Mall",
                    "The Village Mall",
                    "Heraa International Mall"
                ],
                "Luxury": [
                    "Tahlia Street",
                    "Stars Avenue Mall",
                    "Boulevard Jeddah",
                    "Atelier La Vie",
                    "Jeddah Yacht Club & Marina",
                    "Le Mall",
                    "Serafi Mega Mall"
                ]
            ]
        ],

        "Abha": [

            "Cafés & Coffee": [
                "Budget-Friendly": [
                    "Endpoint Cafe",
                    "Camel Step Coffee Roasters",
                    "Fog Coffee",
                    "Barn's Cafe",
                    "Dr. Cafe"
                ],
                "Mid-Range": [
                    "Be You Coffee Roasters",
                    "One Sip Cafe",
                    "CULT Cafe Abha",
                    "Once Specialty Coffee",
                    "Jia Cafe"
                ],
                "Luxury": [
                    "EPEE Coffee & Restaurant",
                    "Kaya Cafe",
                    "OTL Cafe",
                    "Vibe Cafe Abha"
                ]
            ],

            "Food & Dining": [
                "Budget-Friendly": [
                    "Rusticana Restaurant",
                    "Meshraq Restaurant",
                    "Al Tazaj"
                ],
                "Mid-Range": [
                    "Mahrani Restaurant",
                    "India Nights Restaurant",
                    "RAJ Restaurant Abha",
                    "Al Sinara Restaurant"
                ],
                "Luxury": [
                    "Olive Garden Abha",
                    "Giorno Restaurant",
                    "L'antico Restaurant",
                    "Farfyly Italian Restaurant",
                    "Saraya Palace Restaurant"
                ]
            ],

            "Shopping & Modern": [
                "Budget-Friendly": [
                    "Tuesday Market (Souq Al Thulatha)",
                    "Al Basta Traditional Market",
                    "Abha Popular Market"
                ],
                "Mid-Range": [
                    "Al Hawizi Plaza",
                    "Lavanda Park",
                    "Abha Mall"
                ],
                "Luxury": [
                    "Al Rashid Mall Abha",
                    "Al Muftaha Village Shops"
                ]
            ]
        ]
    ]

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Interests that have a curated dataset
    // Adventure & Nature, Relaxation, Cultural & Historical = AI only
    // ─────────────────────────────────────────────────────────────────────────

    private let curatedInterestKeys: [String] = [
        "Cafés & Coffee", "Food & Dining", "Shopping & Modern"
    ]

    private func isCurated(_ interest: String) -> Bool {
        curatedInterestKeys.contains { interest.contains($0) || $0.contains(interest) }
    }

    private func buildCuratedList(city: String, interests: [String], budget: String) -> String {
        guard let cityData = curatedPlaces[city] else { return "" }

        let budgetKey: String
        if budget.contains("Budget") {
            budgetKey = "Budget-Friendly"
        } else if budget.contains("Mid") {
            budgetKey = "Mid-Range"
        } else {
            budgetKey = "Luxury"
        }

        var result = ""
        let normalizedInterests = interests.map { $0.replacingOccurrences(of: "\n", with: " ") }

        for interest in normalizedInterests where isCurated(interest) {
            let interestKey = cityData.keys.first { $0.contains(interest) || interest.contains($0) } ?? interest
            if let budgetTiers = cityData[interestKey],
               let places = budgetTiers[budgetKey], !places.isEmpty {
                result += "\n[\(interest.uppercased()) — \(budgetKey.uppercased())]\n"
                result += places.map { "  • \($0)" }.joined(separator: "\n")
                result += "\n"
            }
        }

        return result
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - System Prompt Builder
    // ─────────────────────────────────────────────────────────────────────────

    private func buildSystemPrompt(
        tier: FamiliarityTier,
        city: String,
        interests: [String],
        budget: String,
        companions: String
    ) -> String {

        let normalizedInterests = interests.map { $0.replacingOccurrences(of: "\n", with: " ") }
        let curatedList = buildCuratedList(city: city, interests: normalizedInterests, budget: budget)
        let hasCuratedData = !curatedList.isEmpty

        let aiOnlyInterests = normalizedInterests.filter { !isCurated($0) }
        let curatedInterestNames = normalizedInterests.filter { isCurated($0) }

        // ── Shared JSON format + universal rules ──────────────────────────────
        let sharedRules = """
        CRITICAL: Return ONLY valid JSON. No markdown, no explanation, no text outside the JSON.

        JSON FORMAT:
        {
          "cityName": "\(city)",
          "days": [
            {
              "dayNumber": 1,
              "activities": [
                {
                  "time": "9:00 AM",
                  "name": "Place Name",
                  "description": "Sharp, specific description. 1–2 sentences. Mention what it's actually known for — the vibe, the signature item, or what makes it stand out. Never generic.",
                  "mapQuery": "Full Place Name, District, \(city), Saudi Arabia",
                  "links": [
                    { "url": "https://www.google.com/maps/search/?api=1&query=Place+Name+District+\(city)", "label": "Google Maps" }
                  ]
                }
              ]
            }
          ]
        }

        ── LINK RULES ──
        Every activity gets EXACTLY ONE link: Google Maps only.
        No booking links, no websites, no social media.

        ── GOOGLE MAPS FORMAT ──
        "Place Name, District, \(city), Saudi Arabia"
        Always use the real district/neighborhood. Never guess — only write what you know.

        ══════════════════════════════════════════
        DESCRIPTION QUALITY — NON-NEGOTIABLE
        ══════════════════════════════════════════
         Write like a knowledgeable local friend — specific, confident, real
         For cafés: mention the specialty drink, aesthetic, or what makes people go back
         For restaurants: mention the cuisine type, signature dish, or the crowd/vibe
         For shopping: mention what kind of shopping experience or what it's known for
         For experiences: mention what you see, feel, or do there
         NEVER write: "a great place to relax", "known for good food", "a must-visit spot"
         NEVER use filler like "perfect for", "you'll love", "a wonderful experience"
         NEVER make up details you don't know — if you're unsure, describe the category-level vibe accurately

        ══════════════════════════════════════════
        GEOGRAPHIC CLUSTERING — MANDATORY
        ══════════════════════════════════════════
        Every day must be geographically tight. All activities on a given day must be in the same neighborhood or zone of \(city).
        - Users must be able to move between activities in under 10 minutes by car
        - Think of each day as owning one zone — pick the zone first, then fill it
        - A nearby average place beats a great place across the city
         NEVER mix activities from distant districts on the same day
         NEVER build a day that requires crossing the city
         One neighborhood per day, explored properly
        """

        // ── Companion context ─────────────────────────────────────────────────
        let companionBlock = companions.isEmpty ? "" : """


        ══════════════════════════════════════════
        WHO THEY'RE TRAVELING WITH: \(companions.uppercased())
        ══════════════════════════════════════════
        Adjust every place selection and description to reflect this:
        - Solo → self-paced, immersive, single-friendly spots
        - Couple → romantic ambiance, scenic or intimate settings
        - Friends Group → social, energetic, group-friendly venues
        - Family with Children → accessible, safe, easy logistics, family-appropriate
        """

        // ── Curated dataset block ─────────────────────────────────────────────
        let curatedBlock = hasCuratedData ? """


        ══════════════════════════════════════════
        YOUR CURATED PLACE LIST
        ══════════════════════════════════════════
        These are verified, real, hand-picked places for: \(curatedInterestNames.joined(separator: ", "))
        \(curatedList)
         These are place NAMES only — no address included.
        You must look up each place's real district in \(city) and use it in mapQuery.
        Only use places from this list that you can confirm exist and are currently operating in \(city).
        """ : ""

        // ── AI-only interests block ───────────────────────────────────────────
        let aiBlock = aiOnlyInterests.isEmpty ? "" : """


        ══════════════════════════════════════════
        AI-GENERATED INTERESTS (no dataset provided)
        ══════════════════════════════════════════
        For these interests, generate entirely from your own knowledge:
        \(aiOnlyInterests.map { "  • \($0)" }.joined(separator: "\n"))
        Use only real, currently operating, well-known places in \(city) that match the user's budget and group.
        """

        // ── Per-tier strategy ─────────────────────────────────────────────────
        switch tier {

        case .firstVisit:
            return """
            You are an expert Saudi Arabia travel curator. Build an itinerary for someone visiting \(city) FOR THE FIRST TIME.

            \(sharedRules)\(companionBlock)\(curatedBlock)\(aiBlock)

            ══════════════════════════════════════════
            FIRST-TIME VISITOR STRATEGY
            ══════════════════════════════════════════
            This person has never been to \(city). Give them a well-rounded, rewarding experience.

             For Cafés / Dining / Shopping: use 2–3 places from the curated list per interest as day anchors. Fill the rest of each day's zone with AI-generated nearby places in the same neighborhood.
             For all other interests: generate from your knowledge — go for iconic, accessible, celebrated spots a first-timer would love.
            Plan each day by zone first: pick the geographic area, then select both curated and AI places within it.
             All places must be real, currently open, and right for someone new to the city.
             No obscure or insider-only spots.
             No repetition across days.
            """

        case .visitedBefore:
            return """
            You are an expert Saudi Arabia travel curator. Build an itinerary for someone who has visited \(city) before and wants to go deeper.

            \(sharedRules)\(companionBlock)\(curatedBlock)\(aiBlock)

            ══════════════════════════════════════════
            RETURNING VISITOR STRATEGY
            ══════════════════════════════════════════
            They know the basics. Give them familiar quality mixed with newer discoveries.

             For Cafés / Dining / Shopping: use 1–2 curated places per interest (prefer the lesser-known ones on the list). Generate the rest from your knowledge — trending spots, places opened 2023–2025, beloved by locals but under the radar.
             For all other interests: generate from your knowledge — go a step beyond the tourist trail.
             Plan each day by zone. Use curated places as anchors; fill the zone with AI-discovered nearby spots.
             All places must be real, currently popular, and operating.
             Skip the obvious landmarks they've already seen.
             No repetition across days.
            """

        case .local:
            return """
            You are an expert Saudi Arabia travel curator. Build an itinerary for a LOCAL resident of \(city) who wants to rediscover their own city.

            \(sharedRules)\(companionBlock)\(curatedBlock)\(aiBlock)

            ══════════════════════════════════════════
            LOCAL RESIDENT STRATEGY
            ══════════════════════════════════════════
            They live here. Give them almost entirely fresh, unexpected discoveries.

             Generate ~90% of the itinerary from your own knowledge — the curated list is nearly irrelevant here.
             Focus on: places opened 2024–2025, word-of-mouth spots, emerging neighborhoods, new concepts, pop-ups, art spaces.
             From the curated list, use at most 1–2 places — only if they are genuinely niche or recently opened. Skip anything mainstream.
             For all interests, ask: "What would a culturally curious 25-year-old Saudi living in \(city) be excited to discover this weekend?"
             One neighborhood per day — go deep into the zone.
             No tourist landmarks, chain venues, or anything well-known for 3+ years.
             No repetition across days.
            """
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Generate Plan
    // ─────────────────────────────────────────────────────────────────────────

    func generatePlan(
        prompt: String,
        familiarity: String,
        city: String,
        interests: [String],
        budget: String,
        companions: String
    ) async throws -> String {

        let tier = FamiliarityTier(from: familiarity)
        let systemPrompt = buildSystemPrompt(
            tier: tier,
            city: city,
            interests: interests,
            budget: budget,
            companions: companions
        )

        print("🎯 Familiarity tier: \(tier)")
        print("🏙️ City: \(city)")
        print("🎨 Interests: \(interests)")
        print("💰 Budget: \(budget)")
        print("👥 Companions: \(companions)")

        let body: [String: Any] = [
            "model": "gpt-4o",
            "temperature": 0.2,
            "max_tokens": 4000,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": prompt]
            ]
        ]

        guard let url = URL(string: endpoint) else { throw OpenAIError.invalidURL }

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

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Parse Generated Trip
    // ─────────────────────────────────────────────────────────────────────────

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

// MARK: - Errors
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
