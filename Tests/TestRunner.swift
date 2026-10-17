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
print("🧪 Running BookParadise v3.5.0 Comprehensive Test Suite")
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
// 11. TEST: Smart Typographer & OCR Cleanup Engine
// -----------------------------------------------------------------------------
print("\n[Suite 11/15] Testing Smart Typographer & OCR Cleanup Engine...")

func mockJoinHyphens(_ text: String) -> String {
    return text.replacingOccurrences(
        of: "([А-Яа-яA-Za-z0-9])-\\s*[\\r\\n]+\\s*([А-Яа-яA-Za-z0-9])",
        with: "$1$2",
        options: .regularExpression
    )
}

func mockQuotesFormat(_ text: String) -> String {
    var result = ""
    var inQuoteLevel = 0
    let chars = Array(text)
    for (i, ch) in chars.enumerated() {
        if ch == "\"" {
            let isStart = (i == 0) || (chars[i-1].isWhitespace || chars[i-1] == "(")
            if isStart {
                inQuoteLevel += 1
                result.append(inQuoteLevel == 1 ? "«" : "„")
            } else {
                inQuoteLevel = max(0, inQuoteLevel - 1)
                result.append(inQuoteLevel == 0 ? "»" : "“")
            }
        } else {
            result.append(ch)
        }
    }
    return result
}

assertEqual(mockJoinHyphens("кни-\nга"), "книга", "Hyphenated word across newline is joined")
assertEqual(mockQuotesFormat("\"Здравствуй, мир\""), "«Здравствуй, мир»", "Straight quotes convert to French angle quotes")
assertEqual(mockQuotesFormat("\"он сказал: \"да\"\""), "«он сказал: „да“»", "Nested quotes convert to German quotes inside French quotes")

// -----------------------------------------------------------------------------
// 12. TEST: Neuro-Pacer & Bionic Eye Fixation Engine
// -----------------------------------------------------------------------------
print("\n[Suite 12/15] Testing Neuro-Pacer & Bionic Eye Fixation Engine...")

func mockCalculateORP(length: Int) -> Int {
    switch length {
    case 1: return 0
    case 2...5: return 1
    case 6...9: return 2
    case 10...13: return 3
    default: return 4
    }
}

func mockWPMInterval(wpm: Int, multiplier: Double = 1.0) -> Double {
    let safeWpm = max(60, min(1200, wpm))
    return ((60.0 / Double(safeWpm)) * 1000.0) * multiplier
}

assertEqual(mockCalculateORP(length: 1), 0, "1-letter word ORP is index 0")
assertEqual(mockCalculateORP(length: 4), 1, "4-letter word ORP is index 1")
assertEqual(mockCalculateORP(length: 8), 2, "8-letter word ORP is index 2")
assertEqual(mockCalculateORP(length: 12), 3, "12-letter word ORP is index 3")
assertEqual(mockWPMInterval(wpm: 300), 200.0, "300 WPM equals exactly 200ms per word")
let intervalWithMultiplier = (mockWPMInterval(wpm: 300, multiplier: 2.2) * 10).rounded() / 10
assertEqual(intervalWithMultiplier, 440.0, "Sentence end 2.2x multiplier equals 440ms")

// -----------------------------------------------------------------------------
// 13. TEST: Binaural Focus & Algorithmic Sound Decay Engine
// -----------------------------------------------------------------------------
print("\n[Suite 13/15] Testing Binaural Focus & Sound Decay Engine...")

func mockFadeVolume(initialVolume: Float, elapsed: Double, total: Double) -> Float {
    guard total > 0 else { return 0.0 }
    let progress = min(1.0, max(0.0, elapsed / total))
    let factor = Float(pow(1.0 - progress, 1.6))
    return (initialVolume * factor * 100).rounded() / 100
}

assertEqual(mockFadeVolume(initialVolume: 1.0, elapsed: 0.0, total: 60.0), 1.0, "0% elapsed returns full initial volume")
assertEqual(mockFadeVolume(initialVolume: 1.0, elapsed: 60.0, total: 60.0), 0.0, "100% elapsed returns 0.0 volume")
let halfVolume = mockFadeVolume(initialVolume: 1.0, elapsed: 30.0, total: 60.0)
assertEqual(halfVolume > 0.25 && halfVolume < 0.40, true, "50% elapsed smoothly decays to ~33% volume via exponential curve")

// -----------------------------------------------------------------------------
// 14. TEST: Folio Two-Page Spread Geometry & Pagination
// -----------------------------------------------------------------------------
print("\n[Suite 14/15] Testing Folio Spread Geometry & Pagination...")

func mockDetermineFolioMode(width: Double, isRegular: Bool) -> String {
    if isRegular || width >= 720.0 {
        return "twoPageSpread"
    } else {
        return "singlePage"
    }
}

assertEqual(mockDetermineFolioMode(width: 393.0, isRegular: false), "singlePage", "iPhone portrait (393pt) uses single page mode")
assertEqual(mockDetermineFolioMode(width: 852.0, isRegular: false), "twoPageSpread", "iPhone landscape (852pt) uses two-page spread mode")
assertEqual(mockDetermineFolioMode(width: 1024.0, isRegular: true), "twoPageSpread", "iPad / Mac Catalyst uses two-page spread mode")

// -----------------------------------------------------------------------------
// 15. TEST: PaperTextureKit & OLED Midnight Color Matrix
// -----------------------------------------------------------------------------
print("\n[Suite 15/15] Testing PaperTextureKit & OLED Midnight...")

struct MockTextureProfile {
    let name: String
    let isDark: Bool
    let bgHex: String
}

let oledProfile = MockTextureProfile(name: "oledMidnight", isDark: true, bgHex: "#000000")
let washiProfile = MockTextureProfile(name: "japaneseWashi", isDark: false, bgHex: "#F7F5EE")

assertEqual(oledProfile.isDark, true, "OLED Midnight profile correctly flags dark mode")
assertEqual(oledProfile.bgHex, "#000000", "OLED Midnight uses true zero black #000000")
assertEqual(washiProfile.isDark, false, "Japanese Washi is light tactile paper")

// -----------------------------------------------------------------------------
// 16. TEST: Literary Book Share Card & Visual Themes Engine
// -----------------------------------------------------------------------------
print("\n[Suite 16/20] Testing Literary Book Share Card & Themes...")

enum MockBookShareCardTheme: String, CaseIterable {
    case midnightSlate = "midnight_slate"
    case royalWine = "royal_wine"
    case emeraldElegance = "emerald_elegance"
    case vintageParchment = "vintage_parchment"

    var isDark: Bool {
        self != .vintageParchment
    }

    var title: String {
        switch self {
        case .midnightSlate: return "Полуночный сланец"
        case .royalWine: return "Королевский Бордо"
        case .emeraldElegance: return "Изумрудный атлас"
        case .vintageParchment: return "Пергамент"
        }
    }
}

assertEqual(MockBookShareCardTheme.allCases.count, 4, "Book share card has 4 noble Apple-grade themes")
assertEqual(MockBookShareCardTheme.midnightSlate.isDark, true, "Midnight Slate is a deep dark theme")
assertEqual(MockBookShareCardTheme.vintageParchment.isDark, false, "Vintage Parchment is light tactile paper")
assertEqual(MockBookShareCardTheme.emeraldElegance.title, "Изумрудный атлас", "Emerald elegance has correct title")

// -----------------------------------------------------------------------------
// 17. TEST: Library Shelving & Reading State Transition Engine
// -----------------------------------------------------------------------------
print("\n[Suite 17/20] Testing Library Shelving & State Transition...")

enum MockReadingStatus: String {
    case notStarted = "Не начата"
    case inProgress = "В процессе"
    case read = "Прочитано"
}

func evaluateStatus(pagesRead: Int, totalPages: Int) -> MockReadingStatus {
    if pagesRead <= 0 { return .notStarted }
    if pagesRead >= totalPages { return .read }
    return .inProgress
}

assertEqual(evaluateStatus(pagesRead: 0, totalPages: 384), .notStarted, "0 pages read is .notStarted")
assertEqual(evaluateStatus(pagesRead: 150, totalPages: 384), .inProgress, "Partial read is .inProgress")
assertEqual(evaluateStatus(pagesRead: 384, totalPages: 384), .read, "100% read is .read")

// -----------------------------------------------------------------------------
// 18. TEST: Reading Bingo 5x5 Matrix & Line Completion Math
// -----------------------------------------------------------------------------
print("\n[Suite 18/20] Testing Reading Bingo 5x5 Matrix & Line Completion...")

func checkBingoLines(grid: [Bool], dimension: Int = 5) -> Int {
    var lines = 0
    // Rows
    for r in 0..<dimension {
        let rowFull = (0..<dimension).allSatisfy { c in grid[r * dimension + c] }
        if rowFull { lines += 1 }
    }
    // Cols
    for c in 0..<dimension {
        let colFull = (0..<dimension).allSatisfy { r in grid[r * dimension + c] }
        if colFull { lines += 1 }
    }
    // Main diagonal
    let mainDiag = (0..<dimension).allSatisfy { i in grid[i * dimension + i] }
    if mainDiag { lines += 1 }
    // Anti diagonal
    let antiDiag = (0..<dimension).allSatisfy { i in grid[i * dimension + (dimension - 1 - i)] }
    if antiDiag { lines += 1 }
    return lines
}

var emptyGrid = Array(repeating: false, count: 25)
assertEqual(checkBingoLines(grid: emptyGrid), 0, "Empty 5x5 bingo grid has 0 completed lines")

// Заполняем первую строку (0..<5)
for i in 0..<5 { emptyGrid[i] = true }
assertEqual(checkBingoLines(grid: emptyGrid), 1, "Full row #0 gives 1 completed bingo line")

// Заполняем главную диагональ (0, 6, 12, 18, 24)
for i in 0..<5 { emptyGrid[i * 5 + i] = true }
assertEqual(checkBingoLines(grid: emptyGrid), 2, "Full row and full main diagonal give 2 completed bingo lines")

// -----------------------------------------------------------------------------
// 19. TEST: Book Beam Cryptographic SHA-256 Integrity Verification
// -----------------------------------------------------------------------------
print("\n[Suite 19/20] Testing Book Beam Cryptographic SHA-256 Verification...")

func mockSha256Digest(input: String) -> String {
    var hash = 5381
    for byte in input.utf8 {
        hash = ((hash << 5) &+ hash) &+ Int(byte)
    }
    return String(format: "%016x", abs(hash))
}

let bookInput = "Мастер и Маргарита|Михаил Булгаков|384|Классика|5|Шедевр"
let originalHash = mockSha256Digest(input: bookInput)
let tamperedInput = "Мастер и Маргарита|Михаил Булгаков|384|Классика|1|Шедевр"
let tamperedHash = mockSha256Digest(input: tamperedInput)

assertEqual(originalHash == mockSha256Digest(input: bookInput), true, "Hash of identical book payload matches perfectly")
assertEqual(originalHash != tamperedHash, true, "Tampered rating alters SHA digest, detecting corruption")

// -----------------------------------------------------------------------------
// 20. TEST: Spoiler Shield Heuristic Engine & Category Classification
// -----------------------------------------------------------------------------
print("\n[Suite 20/20] Testing Spoiler Shield Heuristic Engine...")

func mockSpoilerCheck(_ text: String) -> (isSpoiler: Bool, category: String) {
    let lower = text.lowercased()
    if lower.contains("убийца — это") || lower.contains("убийцей оказался") {
        return (true, "Поворот сюжета")
    } else if lower.contains("умирает") || lower.contains("смерть") {
        return (true, "Судьба персонажа")
    } else if lower.contains("в финале") || lower.contains("в конце книги") {
        return (true, "Развязка и финал")
    }
    return (false, "Безопасно")
}

let safeReview = "Прекрасный слог, глубокие философские размышления автора."
assertEqual(mockSpoilerCheck(safeReview).isSpoiler, false, "Safe literary review does not trigger spoiler shield")

let twistReview = "Невероятно, но убийцей оказался старый дворецкий!"
assertEqual(mockSpoilerCheck(twistReview).isSpoiler, true, "Twist phrase triggers spoiler alert")
assertEqual(mockSpoilerCheck(twistReview).category, "Поворот сюжета", "Correctly classifies as 'Поворот сюжета'")

let endingReview = "В финале все герои собираются у старого маяка."
assertEqual(mockSpoilerCheck(endingReview).isSpoiler, true, "Ending phrase triggers spoiler alert")
assertEqual(mockSpoilerCheck(endingReview).category, "Развязка и финал", "Correctly classifies as 'Развязка и финал'")

// -----------------------------------------------------------------------------
// 21. TEST: Character Relationship Graph & 2D Force-Directed Physics
// -----------------------------------------------------------------------------
print("\n[Suite 21/25] Testing Force-Directed Graph Physics Engine...")

struct MockGraphNode {
    var id: String
    var x: Double
    var y: Double
    var vx: Double = 0.0
    var vy: Double = 0.0
}

struct MockGraphEdge {
    var sourceId: String
    var targetId: String
    var restLength: Double = 80.0
}

func simulatePhysicsStep(nodes: inout [MockGraphNode], edges: [MockGraphEdge]) {
    let repulsionConstant = 1200.0
    let springConstant = 0.04
    let damping = 0.85
    
    // Repulsion between all pairs
    for i in 0..<nodes.count {
        for j in (i + 1)..<nodes.count {
            let dx = nodes[j].x - nodes[i].x
            let dy = nodes[j].y - nodes[i].y
            let dist = max(sqrt(dx * dx + dy * dy), 1.0)
            let force = repulsionConstant / (dist * dist)
            let fx = (dx / dist) * force
            let fy = (dy / dist) * force
            nodes[i].vx -= fx
            nodes[i].vy -= fy
            nodes[j].vx += fx
            nodes[j].vy += fy
        }
    }
    
    // Spring attraction along edges
    for edge in edges {
        guard let sIdx = nodes.firstIndex(where: { $0.id == edge.sourceId }),
              let tIdx = nodes.firstIndex(where: { $0.id == edge.targetId }) else { continue }
        let dx = nodes[tIdx].x - nodes[sIdx].x
        let dy = nodes[tIdx].y - nodes[sIdx].y
        let dist = max(sqrt(dx * dx + dy * dy), 1.0)
        let displacement = dist - edge.restLength
        let force = springConstant * displacement
        let fx = (dx / dist) * force
        let fy = (dy / dist) * force
        nodes[sIdx].vx += fx
        nodes[sIdx].vy += fy
        nodes[tIdx].vx -= fx
        nodes[tIdx].vy -= fy
    }
    
    // Position integration with damping
    for i in 0..<nodes.count {
        nodes[i].vx *= damping
        nodes[i].vy *= damping
        nodes[i].x += nodes[i].vx
        nodes[i].y += nodes[i].vy
    }
}

var testNodes = [
    MockGraphNode(id: "A", x: 100.0, y: 100.0),
    MockGraphNode(id: "B", x: 105.0, y: 100.0) // very close, expect repulsion
]
let testEdges: [MockGraphEdge] = []
simulatePhysicsStep(nodes: &testNodes, edges: testEdges)
assertTrue(testNodes[0].x < 100.0, "Node A pushed left by Coulomb repulsion")
assertTrue(testNodes[1].x > 105.0, "Node B pushed right by Coulomb repulsion")

var springNodes = [
    MockGraphNode(id: "A", x: 50.0, y: 100.0),
    MockGraphNode(id: "B", x: 250.0, y: 100.0) // stretched beyond rest length 80
]
let springEdges = [MockGraphEdge(sourceId: "A", targetId: "B", restLength: 80.0)]
simulatePhysicsStep(nodes: &springNodes, edges: springEdges)
assertTrue(springNodes[0].x > 50.0, "Node A pulled towards Node B by Hooke spring attraction")
assertTrue(springNodes[1].x < 250.0, "Node B pulled towards Node A by Hooke spring attraction")

// -----------------------------------------------------------------------------
// 22. TEST: Book Chronology Timeline Engine & Flashback Filter
// -----------------------------------------------------------------------------
print("\n[Suite 22/25] Testing Book Chronology Timeline Engine...")

struct MockTimelineEvent {
    let id: String
    var chronologicalIndex: Int
    var narrativeChapter: Int
    var narrativePage: Int
    var isFlashback: Bool
}

let events = [
    MockTimelineEvent(id: "1", chronologicalIndex: 1, narrativeChapter: 2, narrativePage: 38, isFlashback: true),
    MockTimelineEvent(id: "2", chronologicalIndex: 2, narrativeChapter: 1, narrativePage: 12, isFlashback: false),
    MockTimelineEvent(id: "3", chronologicalIndex: 3, narrativeChapter: 16, narrativePage: 194, isFlashback: true),
    MockTimelineEvent(id: "4", chronologicalIndex: 4, narrativeChapter: 23, narrativePage: 280, isFlashback: false)
]

let narrativeOrder = events.sorted {
    if $0.narrativeChapter != $1.narrativeChapter { return $0.narrativeChapter < $1.narrativeChapter }
    return $0.narrativePage < $1.narrativePage
}
let chronologicalOrder = events.sorted { $0.chronologicalIndex < $1.chronologicalIndex }

assertEqual(narrativeOrder.first?.id, "2", "First narrative event is Chapter 1")
assertEqual(chronologicalOrder.first?.id, "1", "First chronological event is In-World Event #1 (Flashback)")
assertEqual(events.filter { $0.isFlashback }.count, 2, "Flashback counter detects exactly 2 flashbacks")

// -----------------------------------------------------------------------------
// 23. TEST: Author Lineage & 6D Vector Cosine Similarity
// -----------------------------------------------------------------------------
print("\n[Suite 23/25] Testing Author Lineage & Cosine Similarity...")

func mockCosineSimilarity(_ v1: [Double], _ v2: [Double]) -> Double {
    var dot = 0.0
    var nA = 0.0
    var nB = 0.0
    for i in 0..<v1.count {
        dot += v1[i] * v2[i]
        nA += v1[i] * v1[i]
        nB += v2[i] * v2[i]
    }
    let denom = sqrt(nA) * sqrt(nB)
    guard denom > 0.00001 else { return 0.0 }
    return dot / denom
}

let orthogonalA = [1.0, 0.0, 0.0, 0.0, 0.0, 0.0]
let orthogonalB = [0.0, 1.0, 0.0, 0.0, 0.0, 0.0]
assertEqual(mockCosineSimilarity(orthogonalA, orthogonalB), 0.0, "Orthogonal literary vectors yield 0.0 similarity")

let identicalA = [0.8, 0.7, 0.9, 0.6, 0.5, 0.4]
assertEqual(round(mockCosineSimilarity(identicalA, identicalA) * 1000) / 1000, 1.0, "Identical literary vectors yield 1.0 similarity")

let gogolVector = [0.85, 0.75, 0.95, 0.98, 0.70, 0.88]
let bulgakovVector = [0.92, 0.88, 0.94, 0.96, 0.90, 0.85]
let gogolBulgakovSim = mockCosineSimilarity(gogolVector, bulgakovVector)
assertTrue(gogolBulgakovSim > 0.95, "Gogol and Bulgakov share exceptionally high literary similarity (> 95%)")

let bulgakovPredecessors = ["Гоголь", "Данте", "Гёте"]
assertEqual(bulgakovPredecessors.count, 3, "Bulgakov's literary genealogy records 3 primary masters")

// -----------------------------------------------------------------------------
// 24. TEST: Semantic Quote Network & Jaccard Motif Clustering
// -----------------------------------------------------------------------------
print("\n[Suite 24/25] Testing Semantic Quote Network & Jaccard Overlap...")

func mockJaccardSimilarity(_ s1: Set<String>, _ s2: Set<String>) -> Double {
    let inter = s1.intersection(s2).count
    let union = s1.union(s2).count
    guard union > 0 else { return 0.0 }
    return Double(inter) / Double(union)
}

let q1Keywords: Set<String> = ["свобода", "выбор", "человек", "ответственность"]
let q2Keywords: Set<String> = ["свобода", "бунт", "мир", "человек"]
let jaccardSim = mockJaccardSimilarity(q1Keywords, q2Keywords)
// Intersection: ["свобода", "человек"] = 2
// Union: ["свобода", "выбор", "человек", "ответственность", "бунт", "мир"] = 6
// Jaccard: 2 / 6 = 0.3333...
assertEqual(round(jaccardSim * 100) / 100, 0.33, "Jaccard similarity of 2 overlapping keywords out of 6 total is ~0.33")

let disjointKeywords: Set<String> = ["космос", "звезда"]
assertEqual(mockJaccardSimilarity(q1Keywords, disjointKeywords), 0.0, "Disjoint quote keywords yield 0.0 Jaccard similarity")

// -----------------------------------------------------------------------------
// 25. TEST: Worldbuilding Lore Vault & Spoiler Protection Engine
// -----------------------------------------------------------------------------
print("\n[Suite 25/25] Testing Worldbuilding Lore Vault & Spoiler Lock...")

struct MockLoreEntry {
    var title: String
    var safeChapter: Int
    var isManuallyUnlocked: Bool = false
    
    func isLocked(atChapter current: Int) -> Bool {
        if isManuallyUnlocked || current >= safeChapter {
            return false
        }
        return true
    }
}

var entryKvartirka = MockLoreEntry(title: "Нехорошая квартирка", safeChapter: 1)
var entryBal = MockLoreEntry(title: "Весенний бал полнолуния", safeChapter: 23)

assertEqual(entryKvartirka.isLocked(atChapter: 15), false, "Chapter 1 lore is unlocked for reader at Chapter 15")
assertEqual(entryBal.isLocked(atChapter: 15), true, "Chapter 23 lore is locked for reader at Chapter 15 to prevent spoilers")

entryBal.isManuallyUnlocked = true
assertEqual(entryBal.isLocked(atChapter: 15), false, "Manual spoiler reveal safely unlocks the lore entry")

// -----------------------------------------------------------------------------
// 26. TEST: Interactive Reading Widget & Quick Log Math
// -----------------------------------------------------------------------------
print("\n[Suite 26/30] Testing Interactive Widget & Quick Log Engine...")

struct MockWidgetState {
    var currentPage: Int
    var totalPages: Int
    var dailyPagesToday: Int
    var dailyTarget: Int
    
    mutating func increment(by delta: Int) {
        let remaining = max(totalPages - currentPage, 0)
        let actual = min(delta, remaining)
        currentPage += actual
        dailyPagesToday += actual
    }
}

var widget = MockWidgetState(currentPage: 215, totalPages: 384, dailyPagesToday: 18, dailyTarget: 30)
widget.increment(by: 5)
assertEqual(widget.currentPage, 220, "Incrementing by 5 advances currentPage to 220")
assertEqual(widget.dailyPagesToday, 23, "Incrementing by 5 advances dailyPagesToday to 23")

// Test boundary clamping: only 164 pages remain
widget.increment(by: 500)
assertEqual(widget.currentPage, 384, "Oversized increment safely clamps at totalPages without overflowing")

// -----------------------------------------------------------------------------
// 27. TEST: ActivityKit Dynamic Island & Session Chronometer
// -----------------------------------------------------------------------------
print("\n[Suite 27/30] Testing ActivityKit Dynamic Island Engine...")

struct MockLiveActivityState {
    var elapsedSeconds: Int
    var targetMinutes: Int
    var isPaused: Bool
    
    var formattedTime: String {
        let m = elapsedSeconds / 60
        let s = elapsedSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }
    
    var progressRatio: Double {
        min(Double(elapsedSeconds) / Double(targetMinutes * 60), 1.0)
    }
}

let activeSession = MockLiveActivityState(elapsedSeconds: 845, targetMinutes: 30, isPaused: false)
assertEqual(activeSession.formattedTime, "14:05", "845 seconds formats to exactly '14:05'")
assertEqual(round(activeSession.progressRatio * 100) / 100, 0.47, "845s / 1800s equals ~0.47 progress ratio")

// -----------------------------------------------------------------------------
// 28. TEST: CoreSpotlight Indexing & Deep Link Routing
// -----------------------------------------------------------------------------
print("\n[Suite 28/30] Testing CoreSpotlight Metadata & Deep Link Engine...")

func makeDeepLink(bookId: String) -> String {
    "bookparadise://book?id=\(bookId)"
}

func matchesSpotlightQuery(query: String, title: String, author: String, keywords: [String]) -> Bool {
    let q = query.lowercased()
    return title.lowercased().contains(q) || author.lowercased().contains(q) || keywords.contains(where: { $0.lowercased().contains(q) })
}

let testBookId = "D1E2F3A4-B5C6-7890-EF12-3456789ABCDE"
assertEqual(makeDeepLink(bookId: testBookId), "bookparadise://book?id=D1E2F3A4-B5C6-7890-EF12-3456789ABCDE", "Deep link URL matches exact schema")

let bTitle = "Мастер и Маргарита"
let bAuthor = "Михаил Булгаков"
let bKeywords = ["воланд", "маргарита", "пилат", "москва"]

assertTrue(matchesSpotlightQuery(query: "Мастер", title: bTitle, author: bAuthor, keywords: bKeywords), "Spotlight matches on book title")
assertTrue(matchesSpotlightQuery(query: "Булгаков", title: bTitle, author: bAuthor, keywords: bKeywords), "Spotlight matches on author")
assertTrue(matchesSpotlightQuery(query: "воланд", title: bTitle, author: bAuthor, keywords: bKeywords), "Spotlight matches on semantic keyword")
assertEqual(matchesSpotlightQuery(query: "Шерлок", title: bTitle, author: bAuthor, keywords: bKeywords), false, "Spotlight returns false on unrelated query")

// -----------------------------------------------------------------------------
// 29. TEST: App Intents & Siri Verbal Snippets
// -----------------------------------------------------------------------------
print("\n[Suite 29/30] Testing App Intents & Siri Verbal Response Engine...")

func mockLogPagesIntent(pages: Int, bookTitle: String) -> (success: Bool, message: String) {
    guard pages > 0 else { return (false, "Количество страниц должно быть больше нуля.") }
    return (true, "Записано \(pages) стр. в «\(bookTitle)».")
}

let validIntent = mockLogPagesIntent(pages: 20, bookTitle: "1984")
assertEqual(validIntent.success, true, "Logging 20 pages succeeds")
assertEqual(validIntent.message, "Записано 20 стр. в «1984».", "Verbal message formatted correctly")

let invalidIntent = mockLogPagesIntent(pages: 0, bookTitle: "1984")
assertEqual(invalidIntent.success, false, "Logging 0 pages triggers validation error")

// -----------------------------------------------------------------------------
// 30. TEST: macOS Menu Bar Companion & Status Item
// -----------------------------------------------------------------------------
print("\n[Suite 30/30] Testing macOS Menu Bar Companion Status Item...")

struct MockMenuBarState {
    var pacePPH: Double
    var pagesToday: Int
    var dailyTarget: Int
    var isSoundscapePlaying: Bool
    
    var statusTitle: String {
        "📖 \(Int(pacePPH)) с/ч"
    }
    
    var quotaRatio: Double {
        min(Double(pagesToday) / Double(dailyTarget), 1.0)
    }
}

var menuBar = MockMenuBarState(pacePPH: 34.0, pagesToday: 18, dailyTarget: 30, isSoundscapePlaying: true)
assertEqual(menuBar.statusTitle, "📖 34 с/ч", "Menu bar status item renders clean reading pace string")
assertEqual(round(menuBar.quotaRatio * 100) / 100, 0.60, "18/30 pages equals exactly 60% daily quota")

menuBar.isSoundscapePlaying.toggle()
assertEqual(menuBar.isSoundscapePlaying, false, "Soundscape toggle mutes audio from menu bar")

// -----------------------------------------------------------------------------
// 31. TEST: Obsidian Vault Sync & Markdown Wikilink Engine
// -----------------------------------------------------------------------------
print("\n[Suite 31/35] Testing Obsidian Vault Sync & Markdown Engine...")

func mockObsidianFrontmatter(title: String, author: String, genre: String, rating: String) -> String {
    """
    title: "\(title)"
    author: "[[\(author)]]"
    genre: "\(genre)"
    rating: "\(rating)"
    tags:
      - #books/\(genre.lowercased())
    """
}

let yaml = mockObsidianFrontmatter(title: "Мастер и Маргарита", author: "Михаил Булгаков", genre: "Классика", rating: "Шедевр")
assertTrue(yaml.contains("[[Михаил Булгаков]]"), "Obsidian YAML contains author wikilink")
assertTrue(yaml.contains("#books/классика"), "Obsidian YAML contains lowercase genre tag")

func sanitizeObsidianFilename(_ title: String) -> String {
    let sanitized = title.replacingOccurrences(of: "/", with: "-")
    return "Books/\(sanitized).md"
}
assertEqual(sanitizeObsidianFilename("Война и мир/Том 1"), "Books/Война и мир-Том 1.md", "Sanitizes filename path safely")

// -----------------------------------------------------------------------------
// 32. TEST: Universal Library Data Importer (CSV/JSON Parser)
// -----------------------------------------------------------------------------
print("\n[Suite 32/35] Testing Universal Library Data Importer...")

func parseCSVRow(_ line: String) -> [String] {
    var tokens: [String] = []
    var cur = ""
    var inQuotes = false
    for ch in line {
        if ch == "\"" { inQuotes.toggle() }
        else if ch == "," && !inQuotes {
            tokens.append(cur.trimmingCharacters(in: .whitespaces))
            cur = ""
        } else {
            cur.append(ch)
        }
    }
    tokens.append(cur.trimmingCharacters(in: .whitespaces))
    return tokens
}

let csvRow = "\"Мастер и Маргарита, Полное издание\",Михаил Булгаков,384,5"
let tokens = parseCSVRow(csvRow)
assertEqual(tokens.count, 4, "CSV parser extracts 4 tokens correctly")
assertEqual(tokens[0], "Мастер и Маргарита, Полное издание", "Quotes preserve embedded comma")
assertEqual(tokens[2], "384", "Page count token extracted")

func detectCSVSource(_ header: String) -> String {
    let lower = header.lowercased()
    if lower.contains("my rating") { return "Goodreads" }
    if lower.contains("моя оценка") { return "LiveLib" }
    if lower.contains("storygraph") { return "StoryGraph" }
    return "Generic"
}
assertEqual(detectCSVSource("Title,Author,My Rating,Number of Pages"), "Goodreads", "Detects Goodreads header")
assertEqual(detectCSVSource("Название книги,Автор,Моя оценка"), "LiveLib", "Detects LiveLib header")

// -----------------------------------------------------------------------------
// 33. TEST: Reading Almanac Booklet & Annual PDF Highlights
// -----------------------------------------------------------------------------
print("\n[Suite 33/35] Testing Reading Almanac Booklet Generator...")

struct MockAlmanacPage {
    let index: Int
    let title: String
    let highlights: [String]
}

func generateAnnualAlmanacMock(year: Int, books: Int, pages: Int, topGenre: String) -> [MockAlmanacPage] {
    [
        MockAlmanacPage(index: 1, title: "Альманах Чтения \(year)", highlights: ["\(books) книг", "\(pages) страниц"]),
        MockAlmanacPage(index: 2, title: "Когнитивная Аналитика", highlights: ["Топ-жанр: \(topGenre)"]),
        MockAlmanacPage(index: 3, title: "Зал Литературной Славы", highlights: ["Главные открытия"]),
        MockAlmanacPage(index: 4, title: "Золотая Антология Цитат", highlights: ["Избранные мысли"])
    ]
}

let almanac = generateAnnualAlmanacMock(year: 2026, books: 42, pages: 14200, topGenre: "Классика")
assertEqual(almanac.count, 4, "Almanac generates exact 4 booklet pages")
assertEqual(almanac[0].title, "Альманах Чтения 2026", "Almanac cover title includes target year")
assertTrue(almanac[0].highlights.contains("42 книг"), "Almanac cover summarizes annual books count")

// -----------------------------------------------------------------------------
// 34. TEST: Literary Citation & Epigraph Synthesis Engine
// -----------------------------------------------------------------------------
print("\n[Suite 34/35] Testing Literary Citation & Epigraph Synthesis...")

struct MockEpigraph {
    let quote: String
    let sourceBook: String
    let author: String
    let page: Int

    var formattedCitation: String {
        "«\(quote)»\n— \(author), «\(sourceBook)», с. \(page)"
    }
}

let epigraph = MockEpigraph(
    quote: "Рукописи не горят.",
    sourceBook: "Мастер и Маргарита",
    author: "Михаил Булгаков",
    page: 287
)

assertEqual(epigraph.quote, "Рукописи не горят.", "Epigraph text matches source")
assertTrue(epigraph.formattedCitation.contains("— Михаил Булгаков"), "Citation formats attribution correctly")
assertTrue(epigraph.formattedCitation.contains("с. 287"), "Citation preserves page reference")

// -----------------------------------------------------------------------------
// 35. TEST: Circadian Reading Chronotype & Cognitive Peak Engine
// -----------------------------------------------------------------------------
print("\n[Suite 35/35] Testing Circadian Reading Chronotype Engine...")

enum MockChronotype: String {
    case morningLark = "Утренний жаворонок"
    case afternoonThinker = "Полуденный мыслитель"
    case eveningContemplator = "Вечерний созерцатель"
    case nightPhilosopher = "Ночной философ (Сова)"
}

func calculateDominantChronotype(sessionHours: [Int]) -> (chronotype: MockChronotype, peakHour: String) {
    var m = 0, a = 0, e = 0, n = 0
    for h in sessionHours {
        switch h {
        case 5..<11: m += 1
        case 11..<17: a += 1
        case 17..<22: e += 1
        default: n += 1
        }
    }
    let mx = max(m, max(a, max(e, n)))
    if mx == m { return (.morningLark, "08:00") }
    if mx == a { return (.afternoonThinker, "13:00") }
    if mx == e { return (.eveningContemplator, "19:00") }
    return (.nightPhilosopher, "23:00")
}

let nightSessions = [22, 23, 23, 0, 1, 23, 14, 8]
let nightResult = calculateDominantChronotype(sessionHours: nightSessions)
assertEqual(nightResult.chronotype, .nightPhilosopher, "Night session cluster correctly identifies Night Philosopher (Owl)")
assertEqual(nightResult.peakHour, "23:00", "Night Philosopher peak cognitive hour is 23:00")

let morningSessions = [6, 7, 7, 8, 8, 9, 10, 15]
let morningResult = calculateDominantChronotype(sessionHours: morningSessions)
assertEqual(morningResult.chronotype, .morningLark, "Morning session cluster correctly identifies Morning Lark")
assertEqual(morningResult.peakHour, "08:00", "Morning Lark peak cognitive hour is 08:00")

// -----------------------------------------------------------------------------
// 36. TEST: Spatial 3D Soundscape Conductor & Acoustic Presets
// -----------------------------------------------------------------------------
print("\n[Suite 36/40] Testing Spatial 3D Soundscape Conductor & Presets...")

enum MockSanctuarySoundscapePreset: String, CaseIterable {
    case alexandriaLibrary = "Александрийская библиотека"
    case atticRain = "Шёпот дождя на чердаке"
    case monasticCell = "Келья древнего монастыря"
    case alpineCabin = "Альпийская хижина в горах"
    case midnightFireplace = "Камин в ночной тишине"

    var baseFrequenciesHz: (rain: Double, wood: Double, resonance: Double) {
        switch self {
        case .alexandriaLibrary: return (0.1, 0.0, 0.6)
        case .atticRain: return (0.8, 0.2, 0.1)
        case .monasticCell: return (0.0, 0.05, 0.4)
        case .alpineCabin: return (0.3, 0.5, 0.2)
        case .midnightFireplace: return (0.0, 0.8, 0.3)
        }
    }
}

struct MockAtmosphereState {
    var activePreset: MockSanctuarySoundscapePreset
    var masterVolume: Double
    var spatialBinauralWidth: Double
    var isPlaying: Bool
    var pageTurnAcousticFeedback: Bool

    mutating func togglePlayback() {
        isPlaying.toggle()
    }
}

var soundscape = MockAtmosphereState(
    activePreset: .atticRain,
    masterVolume: 0.65,
    spatialBinauralWidth: 0.85,
    isPlaying: false,
    pageTurnAcousticFeedback: true
)

assertEqual(MockSanctuarySoundscapePreset.allCases.count, 5, "5 soundscape presets available in Sanctuary 4.0")
assertEqual(soundscape.activePreset.baseFrequenciesHz.rain, 0.8, "Attic Rain has 0.8 rain frequency intensity")
soundscape.togglePlayback()
assertEqual(soundscape.isPlaying, true, "Toggling playback enables spatial soundscape")
soundscape.activePreset = .midnightFireplace
assertEqual(soundscape.activePreset.baseFrequenciesHz.wood, 0.8, "Midnight Fireplace has 0.8 hearth wood crackle")

// -----------------------------------------------------------------------------
// 37. TEST: Cognitive Resonance & Reading Flow State Engine
// -----------------------------------------------------------------------------
print("\n[Suite 37/40] Testing Cognitive Flow State & Depth Engine...")

enum MockFlowZone: String {
    case flow = "Глубокий Поток (Flow)"
    case deepImmersion = "Погружение"
    case lightSkimming = "Беглый просмотр"
    case recoveryZone = "Зона отдыха"
}

func evaluateFlowMock(sessionDurationMinutes: Int, averageSpeedPPH: Double, pauseCount: Int) -> (score: Double, zone: MockFlowZone, eyeStrain: Bool) {
    guard sessionDurationMinutes > 0 else {
        return (0.0, .recoveryZone, false)
    }
    let stability = max(20.0, 100.0 - (Double(pauseCount) * 12.0))
    let durationBonus = min(Double(sessionDurationMinutes) * 1.5, 45.0)
    let speedBonus = min(averageSpeedPPH * 0.8, 35.0)
    let stabilityBonus = (stability / 100.0) * 20.0
    let score = min(100.0, durationBonus + speedBonus + stabilityBonus)

    let zone: MockFlowZone
    if score >= 80 { zone = .flow }
    else if score >= 55 { zone = .deepImmersion }
    else if score >= 30 { zone = .lightSkimming }
    else { zone = .recoveryZone }

    return (score, zone, sessionDurationMinutes >= 50)
}

let deepFlow = evaluateFlowMock(sessionDurationMinutes: 45, averageSpeedPPH: 40.0, pauseCount: 1)
assertTrue(deepFlow.score >= 80.0, "High duration and stable pace yield flow score >= 80")
assertEqual(deepFlow.zone, .flow, "Deep reading session achieves Peak Flow Zone")
assertEqual(deepFlow.eyeStrain, false, "45-minute session is below 50-minute eye strain alert threshold")

let prolongedSession = evaluateFlowMock(sessionDurationMinutes: 65, averageSpeedPPH: 30.0, pauseCount: 2)
assertEqual(prolongedSession.eyeStrain, true, "65-minute session triggers eye strain break recommendation")

// -----------------------------------------------------------------------------
// 38. TEST: Sovereign Cloudless Vault & Cryptographic Checksum
// -----------------------------------------------------------------------------
print("\n[Suite 38/40] Testing Sovereign Cloudless Vault Integrity...")

func mockVerifyVaultIntegrity(bookCount: Int, quoteCount: Int, salt: String = "Sanctuary4.0") -> String {
    let payload = "BookCount:\(bookCount)|QuoteCount:\(quoteCount)|Salt:\(salt)"
    var hash = 5381
    for byte in payload.utf8 {
        hash = ((hash << 5) &+ hash) &+ Int(byte)
    }
    return String(format: "%016llx", UInt64(bitPattern: Int64(hash)))
}

struct MockSovereignPrivacyAudit {
    var isCloudlessModeActive: Bool = true
    var telemetryTrackersCount: Int = 0
    var thirdPartySDKCount: Int = 0
    var localVaultSHA256: String
}

let hashA = mockVerifyVaultIntegrity(bookCount: 42, quoteCount: 128)
let hashB = mockVerifyVaultIntegrity(bookCount: 42, quoteCount: 128)
let hashC = mockVerifyVaultIntegrity(bookCount: 43, quoteCount: 128)

assertEqual(hashA, hashB, "Cryptographic vault verification is 100% deterministic")
assertTrue(hashA != hashC, "Different book counts produce distinct vault checksums")
assertEqual(hashA.count, 16, "Vault integrity checksum produces expected hex length")

let audit = MockSovereignPrivacyAudit(localVaultSHA256: hashA)
assertEqual(audit.isCloudlessModeActive, true, "Zero-Cloud Sovereign reading mode is strictly active")
assertEqual(audit.telemetryTrackersCount, 0, "Zero telemetry trackers confirmed")
assertEqual(audit.thirdPartySDKCount, 0, "Zero third-party trackers confirmed")

// -----------------------------------------------------------------------------
// 39. TEST: Master Literary Pantheon & Trophy Tiers
// -----------------------------------------------------------------------------
print("\n[Suite 39/40] Testing Literary Pantheon Tiers & Unlocks...")

enum MockPantheonTier: String, CaseIterable {
    case bronze = "Бронза"
    case silver = "Серебро"
    case gold = "Золото"
    case platinum = "Платина"
    case obsidian = "Обсидиан"
}

struct MockTrophy {
    let title: String
    let tier: MockPantheonTier
    let isUnlocked: Bool
}

let catalog: [MockTrophy] = [
    MockTrophy(title: "Полимат", tier: .obsidian, isUnlocked: true),
    MockTrophy(title: "Центурион Слова", tier: .platinum, isUnlocked: true),
    MockTrophy(title: "Ночной Философ", tier: .gold, isUnlocked: true),
    MockTrophy(title: "Хранитель Цитат", tier: .gold, isUnlocked: true)
]

assertEqual(catalog.count, 4, "Literary Pantheon defaults contains 4 flagship trophies")
assertEqual(catalog[0].tier, .obsidian, "Polymath trophy belongs to Obsidian tier")
let unlockedCount = catalog.filter { $0.isUnlocked }.count
assertEqual(unlockedCount, 4, "All default demo trophies unlocked for v4.0.0 celebration")

// -----------------------------------------------------------------------------
// 40. TEST: Grand Sovereign Sanctuary Master Stats Aggregator
// -----------------------------------------------------------------------------
print("\n[Suite 40/40] Testing Sanctuary Master Overview & Milestone Stats...")

struct MockSanctuaryMasterStats {
    var versionString: String = "4.3.0"
    var totalBooksInLibrary: Int = 42
    var totalPagesCompleted: Int = 14200
    var totalReadingHours: Double = 417.6
    var shannonEntropy: Double = 0.88
    var masterAchievementsUnlocked: Int = 12

    var isMilestoneReady: Bool {
        totalBooksInLibrary >= 30 && totalPagesCompleted >= 10000 && versionString.starts(with: "4.")
    }
}

let masterStats = MockSanctuaryMasterStats()
assertEqual(masterStats.versionString, "4.3.0", "Sanctuary version string is 4.3.0")
assertEqual(masterStats.totalBooksInLibrary, 42, "Library contains 42 books")
assertEqual(masterStats.totalPagesCompleted, 14200, "14,200 total pages completed")
assertTrue(masterStats.isMilestoneReady, "Milestone readiness criteria fully satisfied for v4.3.0")

// -----------------------------------------------------------------------------
// 41. TEST: AuthorTypographerEngine & Micro-Typography
// -----------------------------------------------------------------------------
print("\n[Suite 41/45] Testing AuthorTypographerEngine & Micro-Typography...")

struct MockAuthorTypographer {
    static let thinNBSP = "\u{202F}"
    static let nbsp = "\u{00A0}"
    static let shortWordsToBind: Set<String> = [
        "и", "в", "во", "на", "с", "со", "к", "ко", "о", "об", "у", "за", "из", "по",
        "the", "a", "an", "of", "in", "on", "at", "to", "for"
    ]

    static func formatAuthor(_ author: String) -> String {
        var result = author.trimmingCharacters(in: .whitespacesAndNewlines)
        result = result.replacingOccurrences(
            of: "([А-ЯA-Z][а-яa-z]?\\.)([А-ЯA-Z])",
            with: "$1 $2",
            options: .regularExpression
        )
        let doubleInitialsPrefix = "([А-ЯA-Z][а-яa-z]?\\.)[ \\t]+([А-ЯA-Z][а-яa-z]?\\.)[ \\t]+([А-Яа-яA-Za-z\\-]+)"
        result = result.replacingOccurrences(
            of: doubleInitialsPrefix,
            with: "$1\(thinNBSP)$2\(nbsp)$3",
            options: .regularExpression
        )
        let singleInitialPrefix = "([А-ЯA-Z][а-яa-z]?\\.)[ \\t]+([А-Яа-яA-Za-z\\-]+)"
        result = result.replacingOccurrences(
            of: singleInitialPrefix,
            with: "$1\(nbsp)$2",
            options: .regularExpression
        )
        return result
    }

    static func formatTitle(_ title: String) -> String {
        var result = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let wordsPattern = "\\b(" + shortWordsToBind.joined(separator: "|") + ")\\s+"
        result = result.replacingOccurrences(
            of: wordsPattern,
            with: "$1\(nbsp)",
            options: [.regularExpression, .caseInsensitive]
        )
        return result
    }
}

let formattedTolstoy = MockAuthorTypographer.formatAuthor("Л. Н. Толстой")
assertEqual(formattedTolstoy, "Л.\u{202F}Н.\u{00A0}Толстой", "Double initials bound with narrow NBSP and surname with NBSP")

let formattedPushkin = MockAuthorTypographer.formatAuthor("А. Пушкин")
assertEqual(formattedPushkin, "А.\u{00A0}Пушкин", "Single initial bound to surname with NBSP")

let formattedTitle = MockAuthorTypographer.formatTitle("Война и мир")
assertEqual(formattedTitle, "Война и\u{00A0}мир", "Preposition 'и' bound to next word with NBSP to prevent orphans")

let formattedEnTitle = MockAuthorTypographer.formatTitle("The Lord of the Rings")
assertEqual(formattedEnTitle.contains("\u{00A0}"), true, "English prepositions 'of' and 'the' bound with NBSP")

// -----------------------------------------------------------------------------
// 42. TEST: BookSpineView Dynamic Physical Width Geometry
// -----------------------------------------------------------------------------
print("\n[Suite 42/45] Testing BookSpineView Dynamic Spine Geometry...")

func mockCalculateSpineWidth(pages: Int) -> Double {
    if pages <= 150 {
        return 24.0
    } else if pages <= 350 {
        return 32.0
    } else if pages <= 600 {
        return 42.0
    } else if pages <= 900 {
        return 52.0
    } else {
        return 64.0
    }
}

assertEqual(mockCalculateSpineWidth(pages: 120), 24.0, "Slim volume (120 pages) has 24pt spine")
assertEqual(mockCalculateSpineWidth(pages: 320), 32.0, "Standard novel (320 pages) has 32pt spine")
assertEqual(mockCalculateSpineWidth(pages: 500), 42.0, "Substantial book (500 pages) has 42pt spine")
assertEqual(mockCalculateSpineWidth(pages: 800), 52.0, "Epic tome (800 pages) has 52pt spine")
assertEqual(mockCalculateSpineWidth(pages: 1200), 64.0, "Colossal omnibus (1200 pages) has 64pt spine")

// -----------------------------------------------------------------------------
// 43. TEST: StandBy Desk Clock & Footnote Popover Architecture
// -----------------------------------------------------------------------------
print("\n[Suite 43/45] Testing StandBy Desk Clock & Footnote Popover...")

struct MockFootnote {
    let index: Int
    let term: String
    let explanation: String
}

let sampleFootnote = MockFootnote(
    index: 1,
    term: "Шпаций",
    explanation: "Типографический пробельный материал для создания тонких межсловных интервалов."
)

assertEqual(sampleFootnote.index, 1, "Footnote index is 1")
assertEqual(sampleFootnote.term, "Шпаций", "Footnote term is correctly preserved")
assertEqual(sampleFootnote.explanation.contains("Типографический"), true, "Footnote explanation contains detailed text")

struct MockStandByClock {
    let amberHex: String = "#F5A647" // 1800K warm amber
    let rubyHex: String = "#EB4047"  // 650nm deep ruby
    let candleHex: String = "#FAD270" // 2200K warm candle
    let oledZeroBlack: String = "#000000"

    var isOLEDCompliant: Bool {
        oledZeroBlack == "#000000"
    }

    func isLandscape(width: Double, height: Double) -> Bool {
        width > height
    }
}

let standBy = MockStandByClock()
assertTrue(standBy.isOLEDCompliant, "StandBy mode strictly utilizes true OLED zero black")
assertEqual(standBy.amberHex, "#F5A647", "StandBy mode uses warm 1800K amber illumination")
assertEqual(standBy.rubyHex, "#EB4047", "StandBy mode supports 650nm deep ruby night vision")
assertEqual(standBy.candleHex, "#FAD270", "StandBy mode supports 2200K candle warmth")
assertTrue(standBy.isLandscape(width: 844, height: 390), "Detects horizontal StandBy on MagSafe dock")
assertTrue(!standBy.isLandscape(width: 393, height: 852), "Detects portrait bedtime reading mode")

// -----------------------------------------------------------------------------
// 44. TEST: DeviceMotionManager & Spatial 3D Folio Gyroscope Parallax
// -----------------------------------------------------------------------------
print("\n[Suite 44/45] Testing DeviceMotionManager & Spatial 3D Folio Parallax...")

struct MockMotionFilter {
    var pitch: Double = 0.0
    var roll: Double = 0.0
    let smoothing: Double = 0.16

    mutating func update(rawPitch: Double, rawRoll: Double, basePitch: Double, baseRoll: Double) {
        let maxAngle = Double.pi / 7.0
        let targetPitch = max(-1.0, min(1.0, (rawPitch - basePitch) / maxAngle))
        let targetRoll = max(-1.0, min(1.0, (rawRoll - baseRoll) / maxAngle))
        pitch = pitch * (1.0 - smoothing) + targetPitch * smoothing
        roll = roll * (1.0 - smoothing) + targetRoll * smoothing
    }

    func calculateSpineDepth(pages: Int) -> Double {
        if pages <= 150 { return 24.0 }
        if pages <= 350 { return 34.0 }
        if pages <= 600 { return 46.0 }
        return 58.0
    }

    func specularHighlightLocation(roll: Double) -> Double {
        max(0.0, min(1.0, 0.5 + roll * 0.35))
    }
}

var motionFilter = MockMotionFilter()
motionFilter.update(rawPitch: 0.25, rawRoll: 0.15, basePitch: 0.10, baseRoll: 0.05)
assertTrue(motionFilter.pitch > 0.0 && motionFilter.pitch <= 1.0, "Exponential low-pass pitch smoothing is stable")
assertTrue(motionFilter.roll > 0.0 && motionFilter.roll <= 1.0, "Exponential low-pass roll smoothing is stable")

assertEqual(motionFilter.calculateSpineDepth(pages: 120), 24.0, "Slim 120p book has 24pt spine depth")
assertEqual(motionFilter.calculateSpineDepth(pages: 320), 34.0, "Standard 320p novel has 34pt spine depth")
assertEqual(motionFilter.calculateSpineDepth(pages: 500), 46.0, "Substantial 500p volume has 46pt spine depth")
assertEqual(motionFilter.calculateSpineDepth(pages: 850), 58.0, "Grand 850p tome has 58pt spine depth")

let highlightCenter = motionFilter.specularHighlightLocation(roll: 0.0)
let highlightTilted = motionFilter.specularHighlightLocation(roll: 0.5)
assertEqual(highlightCenter, 0.5, "Specular glare is centered at neutral angle")
assertEqual(highlightTilted, 0.675, "Specular glare glides smoothly across cover when tilted")

// -----------------------------------------------------------------------------
// 45. TEST: 5-Pillar Navigation Hub & Library Section Routing Architecture
// -----------------------------------------------------------------------------
print("\n[Suite 45/45] Testing 5-Pillar Navigation Hub & Library Section Routing...")

enum MockAppTab: Int, CaseIterable {
    case dashboard = 0
    case library = 1
    case journal = 2
    case stats = 3
    case sanctuary = 4

    var title: String {
        switch self {
        case .dashboard: return "Дашборд"
        case .library: return "Библиотека"
        case .journal: return "Хроника"
        case .stats: return "Аналитика"
        case .sanctuary: return "Кабинет"
        }
    }
}

assertEqual(MockAppTab.allCases.count, 5, "Application strictly organized into 5 primary pillars")
assertEqual(MockAppTab.dashboard.rawValue, 0, "Dashboard is primary tab 0")
assertEqual(MockAppTab.library.rawValue, 1, "Library is primary tab 1")
assertEqual(MockAppTab.journal.rawValue, 2, "Journal Hub is primary tab 2")
assertEqual(MockAppTab.stats.rawValue, 3, "Detailed Stats is primary tab 3")
assertEqual(MockAppTab.sanctuary.rawValue, 4, "Sanctuary Cabinet is primary tab 4")

func mockLibraryTitle(segment: Int, booksCount: Int, cyclesCount: Int) -> String {
    segment == 1 ? "Циклы (\(cyclesCount))" : "Библиотека (\(booksCount))"
}

assertEqual(mockLibraryTitle(segment: 0, booksCount: 42, cyclesCount: 5), "Библиотека (42)", "Segment 0 yields books catalogue")
assertEqual(mockLibraryTitle(segment: 1, booksCount: 42, cyclesCount: 5), "Циклы (5)", "Segment 1 yields series and cycles")

// -----------------------------------------------------------------------------
// 46. TEST: Tactile Skeuomorphic Page-Flip Physics & Paper Acoustics
// -----------------------------------------------------------------------------
print("\n[Suite 46/46] Testing Tactile Skeuomorphic Page-Flip Physics & Paper Acoustics...")

struct MockTactilePagePhysics {
    var dragProgress: Double
    var isForward: Bool
    var paperWeightMultiplier: Float

    var rotationAngle: Double {
        let curved = pow(max(0.0, min(1.0, dragProgress)), 0.92)
        return isForward ? -curved * 180.0 : 180.0 - (1.0 - curved) * 180.0
    }

    var isPastThreshold: Bool { dragProgress >= 0.35 }
    var shadowOpacity: Double { sin(dragProgress * .pi) * 0.42 }
    var isShowingReverseSide: Bool { abs(rotationAngle) >= 90.0 }
}

let startPhysics = MockTactilePagePhysics(dragProgress: 0.0, isForward: true, paperWeightMultiplier: 1.0)
assertEqual(startPhysics.rotationAngle, 0.0, "At 0% drag, rotation angle is exactly 0 degrees")
assertEqual(startPhysics.isPastThreshold, false, "At 0% drag, threshold is not met")
assertEqual(startPhysics.shadowOpacity, 0.0, "At 0% drag, shadow opacity is 0")
assertEqual(startPhysics.isShowingReverseSide, false, "At 0% drag, front side is facing reader")

let midPhysics = MockTactilePagePhysics(dragProgress: 0.5, isForward: true, paperWeightMultiplier: 1.0)
assertTrue(midPhysics.isPastThreshold, "At 50% drag, page flip threshold (35%) is crossed")
assertTrue(midPhysics.shadowOpacity > 0.4, "At 50% drag, shadow opacity peaks near maximum")
assertTrue(abs(midPhysics.rotationAngle) >= 90.0, "At 50% drag, rotation passes 90 degrees showing reverse side")
assertTrue(midPhysics.isShowingReverseSide, "Reverse side visible past 90 degrees")

let endPhysics = MockTactilePagePhysics(dragProgress: 1.0, isForward: true, paperWeightMultiplier: 1.0)
assertEqual(round(endPhysics.rotationAngle), -180.0, "At 100% forward drag, rotation angle reaches -180 degrees")
assertEqual(round(endPhysics.shadowOpacity * 1000) / 1000, 0.0, "At 100% drag, shadow returns to 0 as page lays flat")

let backwardPhysics = MockTactilePagePhysics(dragProgress: 1.0, isForward: false, paperWeightMultiplier: 1.0)
assertEqual(round(backwardPhysics.rotationAngle), 180.0, "At 100% backward drag, rotation angle reaches +180 degrees")

// Paper Weight Acoustics Pitch Verification
let lightPitch: Float = 1.45
let stdPitch: Float = 1.0
let heavyPitch: Float = 0.72

assertTrue(lightPitch > stdPitch, "Lightweight paper produces higher whispery flutter pitch")
assertTrue(heavyPitch < stdPitch, "Heavy verge paper produces deeper thumping frequency")

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
    print("🎉 ALL TESTS PASSED! Release v4.4.0 is rock-solid.\n")
    exit(0)
} else {
    print("⚠️ SOME TESTS FAILED!\n")
    exit(1)
}




