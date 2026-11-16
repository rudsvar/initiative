import Foundation

/// Challenge ratings and the experience each is worth. The ratings are a fixed
/// set, so they are picked from a list rather than typed, and the XP of a creature
/// the owner made comes from here.
enum ChallengeRating {
    /// In ascending order, as printed.
    static let all: [String] = ["0", "1/8", "1/4", "1/2"] + (1...30).map(String.init)

    private static let xpTable: [String: Int] = [
        "0": 10, "1/8": 25, "1/4": 50, "1/2": 100,
        "1": 200, "2": 450, "3": 700, "4": 1100, "5": 1800, "6": 2300, "7": 2900,
        "8": 3900, "9": 5000, "10": 5900, "11": 7200, "12": 8400, "13": 10000,
        "14": 11500, "15": 13000, "16": 15000, "17": 18000, "18": 20000, "19": 22000,
        "20": 25000, "21": 33000, "22": 41000, "23": 50000, "24": 62000, "25": 75000,
        "26": 90000, "27": 105000, "28": 120000, "29": 135000, "30": 155000,
    ]

    static func xp(for rating: String) -> Int? { xpTable[rating] }
}
