import XCTest
@testable import initiative

final class ListSectionsTests: XCTestCase {

    // MARK: - Search

    func testEmptyQueryMatchesEverything() {
        XCTAssertTrue(ListSections.matches(query: "", in: ["Goblin"]))
        XCTAssertTrue(ListSections.matches(query: "   ", in: ["Goblin"]))
    }

    func testMatchesSubstring() {
        XCTAssertTrue(ListSections.matches(query: "obl", in: ["Goblin"]))
        XCTAssertFalse(ListSections.matches(query: "orc", in: ["Goblin"]))
    }

    /// A search bar that only matched exact case would be useless — nobody types
    /// "Wyrm" with the capital.
    func testMatchingIsCaseInsensitive() {
        XCTAssertTrue(ListSections.matches(query: "goblin chief", in: ["Goblin Chief"]))
        XCTAssertTrue(ListSections.matches(query: "GOBLIN", in: ["Goblin"]))
    }

    func testMatchingIgnoresDiacritics() {
        XCTAssertTrue(ListSections.matches(query: "revenant", in: ["Révenant"]))
    }

    /// Terms are ANDed, so narrowing works: "giant spider" shouldn't return every
    /// creature with "giant" in the name.
    func testAllTermsMustMatch() {
        XCTAssertTrue(ListSections.matches(query: "giant spider", in: ["Giant Spider"]))
        XCTAssertFalse(ListSections.matches(query: "giant spider", in: ["Giant Rat"]))
    }

    /// …but they may match *different* fields, which is what makes searching an
    /// encounter by the creatures inside it work.
    func testTermsMayMatchDifferentFields() {
        let bridgeTroll = ["Bridge Troll", "Troll", "Boar"]
        XCTAssertTrue(ListSections.matches(query: "troll boar", in: bridgeTroll))
        XCTAssertTrue(ListSections.matches(query: "boar", in: bridgeTroll))
        XCTAssertFalse(ListSections.matches(query: "troll goblin", in: bridgeTroll))
    }

    func testExtraWhitespaceInTheQueryIsIgnored() {
        XCTAssertTrue(ListSections.matches(query: "  giant   spider  ", in: ["Giant Spider"]))
    }

    // MARK: - Search (OR)

    func testMatchesAnyEmptyQueryMatchesEverything() {
        XCTAssertTrue(ListSections.matchesAny(query: "", in: ["Goblin"]))
    }

    /// Encounter search ORs terms — typing "goblin troll" should surface an
    /// encounter containing either, not require both to appear.
    func testMatchesAnySucceedsWhenOnlyOneTermMatches() {
        XCTAssertTrue(ListSections.matchesAny(query: "goblin troll", in: ["Bridge Troll", "Troll", "Boar"]))
    }

    func testMatchesAnyFailsWhenNoTermMatches() {
        XCTAssertFalse(ListSections.matchesAny(query: "goblin ogre", in: ["Bridge Troll", "Troll", "Boar"]))
    }

    // MARK: - Origin split

    func testSplitPutsUserContentFirstAndPreservesOrder() {
        let items = ["a", "B", "c", "D"]
        let groups = ListSections.split(items) { $0 == $0.uppercased() }

        XCTAssertEqual(groups.mine, ["a", "c"])
        XCTAssertEqual(groups.builtIn, ["B", "D"])
    }

    func testSplitHandlesEitherGroupBeingEmpty() {
        XCTAssertEqual(ListSections.split([1, 2, 3]) { _ in false }.builtIn, [])
        XCTAssertEqual(ListSections.split([1, 2, 3]) { _ in true }.mine, [])
        XCTAssertEqual(ListSections.split([Int]()) { _ in true }.mine, [])
    }

    // MARK: - What counts as the user's own

    func testAPresetNamedAfterADefaultIsBuiltIn() {
        XCTAssertTrue(CreaturePreset(name: "Goblin").isBuiltIn)
        XCTAssertTrue(CreaturePreset(name: "goblin").isBuiltIn, "matching should not depend on case")
    }

    func testAPresetTheUserNamedIsTheirs() {
        XCTAssertFalse(CreaturePreset(name: "Hexed Duke").isBuiltIn)
    }

    /// Origin is decided by name, so an edited default stays in the Included
    /// section — the point of the split is provenance, not whether it's been
    /// touched. Renaming it is what makes it yours.
    func testAnEditedDefaultIsStillBuiltInUntilRenamed() {
        XCTAssertTrue(CreaturePreset(name: "Goblin", maxHP: 999, armorClass: 99).isBuiltIn)
        XCTAssertFalse(CreaturePreset(name: "Goblin, But Worse", maxHP: 999).isBuiltIn)
    }

    func testEncounterOriginFollowsTheSameRule() {
        XCTAssertTrue(Encounter(name: "Goblin Ambush").isBuiltIn)
        XCTAssertFalse(Encounter(name: "Session 4 Finale").isBuiltIn)
    }

    // MARK: - Searchable fields

    func testAnEncounterIsSearchableByTheCreaturesInIt() {
        let encounter = Encounter(name: "Session 4 Finale", entries: [
            EncounterEntry(name: "Wight"),
            EncounterEntry(name: "Ghoul", count: 2),
        ])

        XCTAssertTrue(ListSections.matches(query: "wight", in: encounter.searchableText))
        XCTAssertTrue(ListSections.matches(query: "finale", in: encounter.searchableText))
        XCTAssertFalse(ListSections.matches(query: "dragon", in: encounter.searchableText))
    }

    /// The whole default library should be reachable by search — a spot check
    /// that `searchableText` is actually wired to real data rather than empty.
    func testEveryDefaultEncounterIsFoundByItsOwnName() {
        for template in DefaultContent.encounters {
            let encounter = DefaultContent.encounter(from: template)
            XCTAssertTrue(
                ListSections.matches(query: template.name, in: encounter.searchableText),
                "\(template.name) can't be found by searching its own name"
            )
        }
    }
}
