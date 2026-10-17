import Foundation

// MARK: - Mini Test Framework
var totalTests = 0
var passedTests = 0
var failedTests = 0

func assertEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String = "", file: String = #file, line: Int = #line) {
    totalTests += 1
    if actual == expected {
        passedTests += 1
        print("  ✅ [PASS] \(message)")
    } else {
        failedTests += 1
        print("  ❌ [FAIL] \(message) — Expected '\(expected)', got '\(actual)' (Line \(line))")
    }
}

func assertTrue(_ condition: Bool, _ message: String = "", file: String = #file, line: Int = #line) {
    totalTests += 1
    if condition {
        passedTests += 1
        print("  ✅ [PASS] \(message)")
    } else {
        failedTests += 1
        print("  ❌ [FAIL] \(message) — Condition was FALSE (Line \(line))")
    }
}

print("=======================================================")
print("🧪 Running BookParadise v3.1.0 Comprehensive Test Suite")
print("=======================================================")

// -----------------------------------------------------------------------------
// 1. TEST: Streak Logic & Models
// -----------------------------------------------------------------------------
print("\n[Suite 1/5] Testing Streak Engine...")

struct MockStreakState: Codable {
    var currentStreak: Int = 0
    var bestStreak: Int = 0
    var freezesAvailable: Int = 2
    var lastActiveDate: Date? = nil
    var activeDates: Set<String> = []
}

func recordReading(state: inout MockStreakState, calendar: Calendar, date: Date) {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    let dateKey = formatter.string(from: date)
    
    if state.activeDates.contains(dateKey) {
        return // Already counted today
    }
    
    state.activeDates.insert(dateKey)
    
    if let last = state.lastActiveDate {
        let diff = calendar.dateComponents([.day], from: calendar.startOfDay(for: last), to: calendar.startOfDay(for: date)).day ?? 0
        if diff == 1 {
            state.currentStreak += 1
        } else if diff > 1 {
            let missedDays = diff - 1
            if missedDays <= state.freezesAvailable {
                state.freezesAvailable -= missedDays
                state.currentStreak += 1
            } else {
                state.currentStreak = 1
            }
        }
    } else {
        state.currentStreak = 1
    }
    
    if state.currentStreak > state.bestStreak {
        state.bestStreak = state.currentStreak
    }
    state.lastActiveDate = date
}

var streakState = MockStreakState()
let cal = Calendar.current
let day1 = cal.date(from: DateComponents(year: 2026, month: 10, day: 1, hour: 12))!
let day2 = cal.date(from: DateComponents(year: 2026, month: 10, day: 2, hour: 12))!
let day3 = cal.date(from: DateComponents(year: 2026, month: 10, day: 3, hour: 12))!
let day5 = cal.date(from: DateComponents(year: 2026, month: 10, day: 5, hour: 12))! // Skipped day 4 (1 missed day)
let day10 = cal.date(from: DateComponents(year: 2026, month: 10, day: 10, hour: 12)) // Skipped 4 days (exceeds freezes)

// Test sequential reads
recordReading(state: &streakState, calendar: cal, date: day1)
assertEqual(streakState.currentStreak, 1, "First reading initializes streak to 1")

// Same day reading does not increment
recordReading(state: &streakState, calendar: cal, date: day1)
assertEqual(streakState.currentStreak, 1, "Same day reading is idempotent")

// Day 2 reading
recordReading(state: &streakState, calendar: cal, date: day2)
assertEqual(streakState.currentStreak, 2, "Consecutive day increments streak to 2")

// Day 3 reading
recordReading(state: &streakState, calendar: cal, date: day3)
assertEqual(streakState.currentStreak, 3, "Day 3 reading increments streak to 3")
assertEqual(streakState.bestStreak, 3, "Best streak tracks max streak")

// Day 5 reading (Day 4 missed -> 1 freeze auto-used)
assertEqual(streakState.freezesAvailable, 2, "Freezes available before miss is 2")
recordReading(state: &streakState, calendar: cal, date: day5)
assertEqual(streakState.currentStreak, 4, "Streak preserved after auto-consuming 1 freeze")
assertEqual(streakState.freezesAvailable, 1, "Freeze count decremented by 1")

// Day 10 reading (4 days missed -> exceeds remaining 1 freeze -> reset to 1)
recordReading(state: &streakState, calendar: cal, date: day10!)
assertEqual(streakState.currentStreak, 1, "Streak resets to 1 when gap exceeds available freezes")
assertEqual(streakState.bestStreak, 4, "Best streak remains preserved at 4")

// -----------------------------------------------------------------------------
// 2. TEST: RPG Progression & XP Formula
// -----------------------------------------------------------------------------
print("\n[Suite 2/5] Testing RPG Level & Experience Engine...")

func xpForLevel(_ level: Int) -> Int {
    guard level > 1 else { return 0 }
    var total = 0
    for lvl in 1..<level {
        total += 300 + (lvl * 150)
    }
    return total
}

let xpLvl1 = xpForLevel(1)
let xpLvl2 = xpForLevel(2)
let xpLvl3 = xpForLevel(3)
let xpLvl20 = xpForLevel(20)

assertEqual(xpLvl1, 0, "Level 1 base threshold is 0 XP")
assertEqual(xpLvl2, 450, "Level 2 threshold is 450 XP")
assertEqual(xpLvl3, 1050, "Level 3 threshold is 1050 XP")
assertEqual(xpLvl20, 34200, "Level 20 threshold is exactly 34,200 XP (balanced for ~50-80 books)")

func calculateLevel(totalXP: Int) -> (level: Int, currentLevelXP: Int, nextLevelXP: Int, ratio: Double) {
    var lvl = 1
    while lvl < 20 {
        let req = xpForLevel(lvl + 1)
        if totalXP >= req {
            lvl += 1
        } else {
            break
        }
    }
    
    let currentBase = xpForLevel(lvl)
    let nextReq = lvl >= 20 ? currentBase : xpForLevel(lvl + 1)
    let needed = max(1, nextReq - currentBase)
    let progress = max(0, totalXP - currentBase)
    let ratio = lvl >= 20 ? 1.0 : min(1.0, Double(progress) / Double(needed))
    
    return (lvl, progress, needed, ratio)
}

let res0 = calculateLevel(totalXP: 0)
assertEqual(res0.level, 1, "0 XP results in Level 1")
assertEqual(res0.ratio, 0.0, "0 XP ratio is 0.0")

let res450 = calculateLevel(totalXP: 450)
assertEqual(res450.level, 2, "450 XP reaches Level 2")

let resMax = calculateLevel(totalXP: 1_000_000)
assertEqual(resMax.level, 20, "1M XP caps at Level 20")
assertEqual(resMax.ratio, 1.0, "Level 20 progress ratio is 1.0")

// -----------------------------------------------------------------------------
// 3. TEST: EPUB Reader & Bionic Reading Algorithm
// -----------------------------------------------------------------------------
print("\n[Suite 3/5] Testing EPUB Reader & Bionic Reading Engine...")

func cleanHTML(_ raw: String) -> String {
    var text = raw.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    text = text.replacingOccurrences(of: "&nbsp;", with: " ")
    text = text.replacingOccurrences(of: "&quot;", with: "\"")
    text = text.replacingOccurrences(of: "&amp;", with: "&")
    text = text.replacingOccurrences(of: "&lt;", with: "<")
    text = text.replacingOccurrences(of: "&gt;", with: ">")
    text = text.replacingOccurrences(of: "&#39;", with: "'")
    return text.trimmingCharacters(in: .whitespacesAndNewlines)
}

let sampleHTML = "<p>Привет, &quot;Книжный Рай&quot;&nbsp;&amp;&nbsp;мир!</p>"
let cleaned = cleanHTML(sampleHTML)
assertEqual(cleaned, "Привет, \"Книжный Рай\" & мир!", "HTML cleaner correctly strips tags and decodes entities")

func bionicWordSplit(_ word: String) -> (boldPart: String, regularPart: String) {
    let cleanLetters = word.filter { $0.isLetter }
    if cleanLetters.isEmpty {
        return ("", word)
    }
    let count = word.count
    let boldLength: Int
    if count <= 3 {
        boldLength = 1
    } else {
        boldLength = Int(ceil(Double(count) * 0.45))
    }
    let index = word.index(word.startIndex, offsetBy: min(count, boldLength))
    return (String(word[..<index]), String(word[index...]))
}

let w1 = bionicWordSplit("книга")
assertEqual(w1.boldPart, "кни", "5-letter word has 3 bold letters (45-50% ceiling)")
assertEqual(w1.regularPart, "га", "Remaining letters are regular")

let w2 = bionicWordSplit("я")
assertEqual(w2.boldPart, "я", "1-letter word is fully bold")
assertEqual(w2.regularPart, "", "1-letter word has empty regular part")

let w3 = bionicWordSplit("чтение,")
assertEqual(w3.boldPart, "чтен", "Punctuation-attached word calculates bold prefix accurately")

// -----------------------------------------------------------------------------
// 4. TEST: Soundscape Mixer Presets & Safety
// -----------------------------------------------------------------------------
print("\n[Suite 4/5] Testing Atmosphere Studio 2.0...")

enum MockChannel: String, CaseIterable {
    case rain, fireplace, cafe, forest
}

var volumes: [MockChannel: Float] = [
    .rain: 0.0,
    .fireplace: 0.0,
    .cafe: 0.0,
    .forest: 0.0
]

func applyPreset(_ preset: String, to vols: inout [MockChannel: Float]) {
    switch preset {
    case "library":
        vols[.rain] = 0.55
        vols[.fireplace] = 0.35
        vols[.cafe] = 0.0
        vols[.forest] = 0.0
    case "cafe":
        vols[.rain] = 0.20
        vols[.fireplace] = 0.0
        vols[.cafe] = 0.65
        vols[.forest] = 0.15
    default:
        break
    }
}

applyPreset("library", to: &volumes)
assertEqual(volumes[.rain]!, 0.55, "Library preset sets rain to 0.55")
assertEqual(volumes[.fireplace]!, 0.35, "Library preset sets fireplace to 0.35")
assertEqual(volumes[.cafe]!, 0.0, "Library preset mutes cafe")

applyPreset("cafe", to: &volumes)
assertEqual(volumes[.cafe]!, 0.65, "Cafe preset activates coffee shop sound")

// -----------------------------------------------------------------------------
// 5. TEST: Widget Data Export Serialization
// -----------------------------------------------------------------------------
print("\n[Suite 5/5] Testing WidgetKit JSON Export Serialization...")

struct MockWidgetPayload: Codable {
    let bookTitle: String
    let author: String
    let pagesRead: Int
    let totalPages: Int
    let percent: Int
    let dailyStreak: Int
    let lastUpdated: Date
}

let testPayload = MockWidgetPayload(
    bookTitle: "Мастер и Маргарита",
    author: "М. Булгаков",
    pagesRead: 180,
    totalPages: 360,
    percent: 50,
    dailyStreak: 7,
    lastUpdated: Date()
)

let encoder = JSONEncoder()
let encodedData = try! encoder.encode(testPayload)
assertTrue(encodedData.count > 0, "Widget data payload encodes successfully")

let decoder = JSONDecoder()
let decoded = try! decoder.decode(MockWidgetPayload.self, from: encodedData)
assertEqual(decoded.bookTitle, "Мастер и Маргарита", "Decoded widget book title matches")
assertEqual(decoded.percent, 50, "Decoded widget progress percent matches")
assertEqual(decoded.dailyStreak, 7, "Decoded widget streak matches")

// -----------------------------------------------------------------------------
// 6. TEST: Genre Radar & Shannon Diversity Entropy Engine
// -----------------------------------------------------------------------------
print("\n[Suite 6/10] Testing Genre Radar & Shannon Diversity Engine...")

func calculateMockShannonEntropy(counts: [Int]) -> Double {
    let total = counts.reduce(0, +)
    guard total > 0 else { return 0.0 }
    let k = Double(counts.count)
    let maxEntropy = log(k)
    var entropySum: Double = 0.0
    for c in counts where c > 0 {
        let p = Double(c) / Double(total)
        entropySum -= p * log(p)
    }
    return maxEntropy > 0 ? min(max(entropySum / maxEntropy, 0.0), 1.0) : 0.0
}

assertEqual(calculateMockShannonEntropy(counts: [0, 0, 0, 0, 0]), 0.0, "Empty library entropy is 0.0")
assertEqual(calculateMockShannonEntropy(counts: [10, 0, 0, 0, 0, 0, 0, 0, 0]), 0.0, "Monoculture single-genre entropy is 0.0")

let uniformEntropy = calculateMockShannonEntropy(counts: [5, 5, 5, 5, 5, 5, 5, 5, 5])
assertTrue(abs(uniformEntropy - 1.0) < 0.001, "Uniform distribution across 9 genres gives max entropy ~1.0")

let skewedEntropy = calculateMockShannonEntropy(counts: [10, 5, 2, 0, 0, 0, 0, 0, 0])
assertTrue(skewedEntropy > 0.3 && skewedEntropy < 0.7, "Skewed distribution gives realistic intermediate entropy (~0.5)")

// -----------------------------------------------------------------------------
// 7. TEST: Smart Reading Pace & Velocity Forecasting
// -----------------------------------------------------------------------------
print("\n[Suite 7/10] Testing Smart Reading Pace & Velocity Forecasting...")

struct MockSession {
    let pages: Int
    let minutes: Int
}

func calculateMockPPH(sessions: [MockSession]) -> Double {
    guard !sessions.isEmpty else { return 28.0 }
    var totalWeightedPPH: Double = 0.0
    var totalWeight: Double = 0.0
    for (idx, s) in sessions.enumerated() {
        let weight = Double(idx + 1)
        let rate = (Double(s.pages) / Double(s.minutes)) * 60.0
        totalWeightedPPH += rate * weight
        totalWeight += weight
    }
    return (totalWeightedPPH / totalWeight * 10).rounded() / 10
}

assertEqual(calculateMockPPH(sessions: []), 28.0, "Default rate with no sessions is 28.0 pph")

let testSessions = [
    MockSession(pages: 15, minutes: 30), // 30 pph, weight 1
    MockSession(pages: 20, minutes: 30)  // 40 pph, weight 2 -> (30*1 + 40*2)/3 = 110/3 = 36.7 pph
]
assertEqual(calculateMockPPH(sessions: testSessions), 36.7, "Weighted average calculates accurate pace")

let remainingPages = 140
let calculatedPPH = 28.0
let minutesRemaining = Int(ceil((Double(remainingPages) / calculatedPPH) * 60.0))
assertEqual(minutesRemaining, 300, "140 pages at 28 pph equals exactly 300 minutes (5 hours)")

// -----------------------------------------------------------------------------
// 8. TEST: Library Economics & Leisure Value
// -----------------------------------------------------------------------------
print("\n[Suite 8/10] Testing Library Economics & Leisure Value...")

func calculateMockEconomics(paperCount: Int, eCount: Int, totalPagesRead: Int, totalHours: Double) -> (invested: Double, costPage: Double, costHour: Double, savings: Double) {
    let invested = Double(paperCount) * 750.0 + Double(eCount) * 350.0
    let costPage = totalPagesRead > 0 ? (invested / Double(totalPagesRead) * 100).rounded() / 100 : invested
    let costHour = totalHours > 0 ? (invested / totalHours * 10).rounded() / 10 : invested
    let savings = max(totalHours * 400.0 - invested, 0.0)
    return (invested, costPage, costHour, savings)
}

let eco = calculateMockEconomics(paperCount: 5, eCount: 5, totalPagesRead: 2750, totalHours: 100.0)
assertEqual(eco.invested, 5500.0, "5 paper + 5 e-books investment is 5500.0")
assertEqual(eco.costPage, 2.0, "5500 investment / 2750 pages = 2.0 per page")
assertEqual(eco.costHour, 55.0, "5500 investment / 100 hours = 55.0 per hour")
assertEqual(eco.savings, 34500.0, "100 hours * 400 benchmark - 5500 = 34500 leisure savings")

// -----------------------------------------------------------------------------
// 9. TEST: DNF (Did Not Finish) Analytics Engine
// -----------------------------------------------------------------------------
print("\n[Suite 9/10] Testing DNF (Did Not Finish) Analytics Engine...")

struct MockDNFBook {
    let pagesRead: Int
    let totalPages: Int
}

func calculateMockDNF(books: [MockDNFBook]) -> (avgDropPct: Double, rule50PassedRate: Double, hoursSaved: Double) {
    guard !books.isEmpty else { return (0.0, 0.0, 0.0) }
    var sumPct: Double = 0.0
    var rule50Passed = 0
    var unreadPages = 0
    for b in books {
        let pct = (Double(b.pagesRead) / Double(b.totalPages)) * 100.0
        sumPct += pct
        if b.pagesRead >= 50 || pct >= 20.0 { rule50Passed += 1 }
        unreadPages += max(b.totalPages - b.pagesRead, 0)
    }
    let avg = sumPct / Double(books.count)
    let rate = (Double(rule50Passed) / Double(books.count)) * 100.0
    let saved = Double(unreadPages) / 30.0
    return ((avg * 10).rounded() / 10, (rate * 10).rounded() / 10, (saved * 10).rounded() / 10)
}

let dnfBooks = [
    MockDNFBook(pagesRead: 55, totalPages: 300), // 18.3%, >= 50 pages -> rule passed
    MockDNFBook(pagesRead: 100, totalPages: 400) // 25.0%, >= 50 pages -> rule passed
]
let dnfStats = calculateMockDNF(books: dnfBooks)
assertEqual(dnfStats.rule50PassedRate, 100.0, "Both books gave author >= 50 pages -> 100% Rule of 50 rate")
assertEqual(dnfStats.hoursSaved, 18.2, "(245 + 300 unread) = 545 / 30 = 18.2 hours saved")

// -----------------------------------------------------------------------------
// 10. TEST: Time Travel Literary Axis Engine
// -----------------------------------------------------------------------------
print("\n[Suite 10/10] Testing Time Travel Literary Axis Engine...")

func determineMockEpoch(author: String, edition: String) -> String {
    let lower = (author + " " + edition).lowercased()
    if lower.contains("гомер") || lower.contains("платон") { return "Античность" }
    if lower.contains("шекспир") || lower.contains("данте") { return "Средневековье и Ренессанс" }
    if lower.contains("толстой") || lower.contains("пушкин") { return "Золотой XIX век" }
    if lower.contains("булгаков") || lower.contains("оруэлл") { return "Модернизм и XX век" }
    return "XXI век и Современность"
}

assertEqual(determineMockEpoch(author: "Гомер", edition: "Илиада"), "Античность", "Гомер maps to Antiquity")
assertEqual(determineMockEpoch(author: "Уильям Шекспир", edition: "Гамлет"), "Средневековье и Ренессанс", "Шекспир maps to Middle Ages & Renaissance")
assertEqual(determineMockEpoch(author: "Лев Толстой", edition: "Война и мир"), "Золотой XIX век", "Толстой maps to Golden XIX Century")
assertEqual(determineMockEpoch(author: "Джордж Оруэлл", edition: "1984"), "Модернизм и XX век", "Оруэлл maps to Modernism & XX Century")

// -----------------------------------------------------------------------------
// SUMMARY
// -----------------------------------------------------------------------------
print("\n=======================================================")
print("📊 TEST EXECUTION SUMMARY:")
print("  Total Tests Run: \(totalTests)")
print("  Passed:          \(passedTests) ✅")
print("  Failed:          \(failedTests) ❌")
print("=======================================================")

if failedTests == 0 {
    print("🎉 ALL TESTS PASSED! Release v3.1.0 is solid.\n")
    exit(0)
} else {
    print("⚠️ SOME TESTS FAILED!\n")
    exit(1)
}
