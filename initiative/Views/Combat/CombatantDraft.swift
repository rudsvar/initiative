import Foundation

/// What the add-a-creature form holds, and how picking or typing a known name
/// fills it in. Shared by Add Combatant and an encounter's Add Creature, so the
/// two forms cannot drift apart (see `CombatantDraftFields`).
struct CombatantDraft: Equatable {
    var name = ""
    var hpText = ""
    var acText = ""
    var countText = ""
    /// The matched entry's initiative bonus. Not a field on the form: it is
    /// applied silently to random rolls.
    var initiativeBonus: Int?
    /// Whether the creature is one of the party. Defaults to no: most of what a
    /// DM adds mid-combat is something the party is fighting.
    var isPlayer = false
    /// What was picked from a Choose list, while the name still is that one.
    var chosen: CreaturePreset?

    var trimmedName: String { name.trimmingCharacters(in: .whitespaces) }
    var isValid: Bool { !trimmedName.isEmpty }
    var maxHP: Int? { Int(hpText) }
    var armorClass: Int? { Int(acText) }
    var count: Int { max(1, Int(countText) ?? 1) }

    /// Picked from a list: the form takes all of the entry's numbers and its kind.
    mutating func choose(_ preset: CreaturePreset) {
        chosen = preset
        name = preset.name
        hpText = preset.maxHP.map(String.init) ?? ""
        acText = preset.armorClass.map(String.init) ?? ""
        initiativeBonus = preset.initiativeBonus
        isPlayer = preset.isPlayer
    }

    /// The name was edited; `preset` is the saved entry with that name, if any.
    /// A known name fills only the fields still empty, so nothing typed is lost.
    mutating func nameChanged(matching preset: CreaturePreset?) {
        if chosen?.name != name { chosen = nil }
        guard let preset else {
            initiativeBonus = nil
            isPlayer = false
            return
        }
        if hpText.isEmpty, let maxHP = preset.maxHP { hpText = String(maxHP) }
        if acText.isEmpty, let armorClass = preset.armorClass { acText = String(armorClass) }
        initiativeBonus = preset.initiativeBonus
        isPlayer = preset.isPlayer
    }
}
