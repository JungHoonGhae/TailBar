import Foundation

enum AliasStore {
    private static let defaults = UserDefaults.standard

    static func alias(forPort port: Int) -> String? {
        defaults.string(forKey: "alias.port.\(port)")
    }

    static func setAlias(_ alias: String?, forPort port: Int) {
        if let alias, !alias.isEmpty {
            defaults.set(alias, forKey: "alias.port.\(port)")
        } else {
            defaults.removeObject(forKey: "alias.port.\(port)")
        }
    }

    static func alias(forNode hostname: String) -> String? {
        defaults.string(forKey: "alias.node.\(hostname)")
    }

    static func setAlias(_ alias: String?, forNode hostname: String) {
        if let alias, !alias.isEmpty {
            defaults.set(alias, forKey: "alias.node.\(hostname)")
        } else {
            defaults.removeObject(forKey: "alias.node.\(hostname)")
        }
    }
}
