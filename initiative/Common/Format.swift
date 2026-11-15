import Foundation

enum Format {
    /// A modifier with its sign: "+2", "-1", "+0".
    static func signed(_ n: Int) -> String {
        n >= 0 ? "+\(n)" : "\(n)"
    }
}
