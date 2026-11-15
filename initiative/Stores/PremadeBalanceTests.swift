import XCTest
@testable import initiative

/// Expected-damage check for every premade encounter, as the repo rules ask.
///
/// Assumptions, stated so the numbers can be argued with:
/// - Party: 4 characters, 30 HP each, AC 16, +5 to attack, 7.5 average damage per hit.
/// - A monster makes its first attack that has an attack roll. Multiattack and
///   spellcasting are ignored, so a monster deals one attack per round.
/// - Hit chance is the chance that d20 + bonus reaches the target's AC, kept
///   between 5% and 95%. Expected values only, no dice.
/// - Each round the monsters attack first, each hitting the first living character.
///   Then each character hits the first living monster.
///
/// The report is printed to the test log. The guard only catches a fight the party
/// cannot survive in expectation by a wide margin. Balance is judged from the
/// report, not from this assertion.
final class PremadeBalanceTests: XCTestCase {

    private struct Attack { let bonus: Int; let average: Double }

    private static let partyHP: Double = 120
    private static let partySize = 4
    private static let partyAC = 16
    private static let partyBonus = 5
    private static let partyDamage: Double = 7.5

    private func blocks() throws -> [String: StatBlock] {
        let stores = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        let url = stores.deletingLastPathComponent().appendingPathComponent("Data/srd-creatures.json")
        return Dictionary(try SRDCatalog.load(from: url).map { ($0.name, $0) }, uniquingKeysWith: { a, _ in a })
    }

    private func firstAttack(of block: StatBlock?) -> Attack? {
        guard let block else { return nil }
        for entry in block.actions {
            guard let bonus = Self.capture(#"Attack Roll: \+?(\d+)"#, in: entry.text),
                  let average = Self.capture(#"Hit: (\d+) \("#, in: entry.text) else { continue }
            return Attack(bonus: Int(bonus) ?? 0, average: Double(average) ?? 0)
        }
        return nil
    }

    private static func capture(_ pattern: String, in text: String) -> String? {
        guard let re = try? NSRegularExpression(pattern: pattern),
              let m = re.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let r = Range(m.range(at: 1), in: text) else { return nil }
        return String(text[r])
    }

    private static func hitChance(bonus: Int, ac: Int) -> Double {
        min(0.95, max(0.05, Double(21 + bonus - ac) / 20))
    }

    private struct Monster { var hp: Double; let ac: Int; let attack: Attack? }

    private func simulate(_ lineup: [DefaultContent.Lineup], blocks: [String: StatBlock]) -> (taken: Double, rounds: Int) {
        var monsters: [Monster] = []
        for line in lineup {
            guard let creature = DefaultContent.creature(named: line.creature) else { continue }
            let attack = firstAttack(of: blocks[creature.name])
            for _ in 0..<line.count {
                monsters.append(Monster(hp: Double(creature.maxHP), ac: creature.armorClass, attack: attack))
            }
        }
        var party = Array(repeating: Self.partyHP / Double(Self.partySize), count: Self.partySize)
        var taken = 0.0
        var rounds = 0
        while monsters.contains(where: { $0.hp > 0 }) && party.contains(where: { $0 > 0 }) && rounds < 50 {
            rounds += 1
            for m in monsters where m.hp > 0 {
                guard let atk = m.attack, let t = party.firstIndex(where: { $0 > 0 }) else { continue }
                let dealt = min(Self.hitChance(bonus: atk.bonus, ac: Self.partyAC) * atk.average, party[t])
                party[t] -= dealt
                taken += dealt
            }
            for _ in party.indices where party.contains(where: { $0 > 0 }) {
                guard let t = monsters.firstIndex(where: { $0.hp > 0 }) else { break }
                monsters[t].hp -= Self.hitChance(bonus: Self.partyBonus, ac: monsters[t].ac) * Self.partyDamage
            }
        }
        return (taken, rounds)
    }

    func testPremadeEncountersReport() throws {
        let blocks = try blocks()
        var report: [String] = []
        for template in DefaultContent.encounters {
            let r = simulate(template.lineup, blocks: blocks)
            let pct = r.taken / Self.partyHP * 100
            report.append(String(format: "%-24@ %5.1f of %3.0f HP (%3.0f%%), %2d rounds",
                                 template.name as NSString, r.taken, Self.partyHP, pct, r.rounds))
            XCTAssertLessThan(pct, 150, "\(template.name) is a sure wipe for the assumed party")
        }
        print("PREMADE BALANCE\n" + report.joined(separator: "\n"))
    }
}
