import SwiftUI

/// Generic approximate-status bands shown in player view (the DM's screen while
/// players can see it) instead of exact numbers. Deliberately generic wording —
/// not ruleset-specific terms like "Bloodied". Shared by the combatant list and
/// the detail screen so both read the same bands.
enum StatusBand {
    /// Bands are exclusive at the top and inclusive at the bottom: >50% Healthy,
    /// >25% Wounded, the rest Critical, and 0 or less Dead regardless of max.
    static func health(current: Int, max: Int) -> (label: String, color: Color) {
        if current <= 0 { return ("Dead", Theme.statusNeutral) }
        // A non-positive max would make the fraction meaningless (or NaN at
        // zero), so treat "has HP left but no known ceiling" as simply alive.
        guard max > 0 else { return ("Healthy", Theme.statusGood) }
        let fraction = Double(current) / Double(max)
        if fraction > 0.5 { return ("Healthy", Theme.statusGood) }
        if fraction > 0.25 { return ("Wounded", Theme.statusWarn) }
        return ("Critical", Theme.statusBad)
    }

    /// A plain band for how hard the creature is to hit, instead of a bare number.
    /// Named by AC level, not by the kind of armour worn. Deliberately no colour:
    /// AC is neither good nor bad the way HP is, so no band suggests a verdict.
    static func armorClass(_ ac: Int) -> String {
        if ac >= 17 { return "High AC" }
        if ac >= 13 { return "Medium AC" }
        return "Low AC"
    }
}
