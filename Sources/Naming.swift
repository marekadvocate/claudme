import Foundation

/// Every session is a made man in your family. Its name is stable (hashed from the
/// session name), its era decides the given name and later the skin, its surname is
/// the model it runs, and its rank is earned by staying alive.
enum Era: String, CaseIterable {
    case roman, medieval, renaissance, prohibition, yakuza, syndicate

    var label: String {
        switch self {
        case .roman: return "Roman"
        case .medieval: return "Medieval"
        case .renaissance: return "Renaissance"
        case .prohibition: return "Prohibition"
        case .yakuza: return "Yakuza"
        case .syndicate: return "Syndicate"
        }
    }

    var givenNames: [String] {
        switch self {
        case .roman:
            return ["Marcus", "Gaius", "Lucius", "Titus", "Cassius", "Aulus",
                    "Decimus", "Livia", "Octavia", "Vitellia"]
        case .medieval:
            return ["Svatopluk", "Rastislav", "Vratislav", "Boleslav", "Kunigunda",
                    "Hedviga", "Ottokar", "Casimir", "Bela", "Vladislav"]
        case .renaissance:
            return ["Lorenzo", "Cesare", "Cosimo", "Ludovico", "Bianca",
                    "Isabella", "Piero", "Sforza", "Vittoria", "Alessandro"]
        case .prohibition:
            return ["Vito", "Salvatore", "Rocco", "Carmine", "Enzo",
                    "Angelo", "Nunzio", "Vincenza", "Gaetano", "Sonny"]
        case .yakuza:
            return ["Kenji", "Goro", "Tetsuo", "Shinji", "Ryu",
                    "Katsu", "Hideo", "Masa", "Jiro", "Akira"]
        case .syndicate:
            return ["Nyx", "Vex", "Cass", "Rook", "Zero",
                    "Silas", "Wren", "Kade", "Mira", "Onyx"]
        }
    }
}

/// Earned by staying alive — your oldest session runs the family.
enum Rank: Int {
    case picciotto = 0, soldato, capo, don

    var title: String {
        switch self {
        case .picciotto: return "Picciotto"
        case .soldato: return "Soldato"
        case .capo: return "Capo"
        case .don: return "Don"
        }
    }

    /// A crab's standing after this long in the family.
    static func forAge(seconds: Double) -> Rank {
        switch seconds {
        case ..<600: return .picciotto      // under 10 min — still proving himself
        case ..<3600: return .soldato       // under an hour
        case ..<14400: return .capo         // under four hours
        default: return .don
        }
    }
}

struct MadeName {
    let rank: Rank
    let given: String
    let surname: String
    let era: Era

    /// "Don Vito Opus"
    var full: String { "\(rank.title) \(given) \(surname)" }
    /// "Vito Opus" — for tight spaces
    var short: String { "\(given) \(surname)" }
}

enum Naming {
    /// Stable 64-bit FNV-1a so a session keeps its identity across restarts.
    static func hash(_ s: String) -> UInt64 {
        var h: UInt64 = 1469598103934665603
        for b in s.utf8 { h = (h ^ UInt64(b)) &* 1099511628211 }
        return h
    }

    static func era(for sessionName: String) -> Era {
        let all = Era.allCases
        return all[Int(hash(sessionName) % UInt64(all.count))]
    }

    /// `variant` shifts the given name so two live crabs never share a full name.
    static func name(sessionName: String,
                     model: ModelKind,
                     ageSeconds: Double,
                     variant: Int = 0) -> MadeName {
        let e = era(for: sessionName)
        let pool = e.givenNames
        let idx = (Int((hash(sessionName) >> 8) % UInt64(pool.count)) + variant) % pool.count
        return MadeName(rank: Rank.forAge(seconds: ageSeconds),
                        given: pool[idx],
                        surname: model.familyName,
                        era: e)
    }
}
