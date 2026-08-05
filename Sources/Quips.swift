import Foundation

/// What a crab can say. Every line is written in the voice of a made man
/// reporting to his boss — you.
enum QuipKind {
    case done          // the session finished a turn
    case working       // mid-job chatter
    case waiting       // needs your input / permission
    case trouble       // rate limit, API error
    case idle          // ambient mumbling
    case sleeping
    case beer
    case toast         // two crabs clinking
    case greeting      // two crabs passing each other
    case compacting
    case compacted
}

enum Lang: String, CaseIterable {
    case en, sk, cs

    var displayName: String {
        switch self {
        case .en: return "English"
        case .sk: return "Slovenčina"
        case .cs: return "Čeština"
        }
    }
}

enum Quips {
    private static let key = "ClaudmeLanguage"

    /// Chosen in the menubar; falls back to the system language, then English.
    static var language: Lang = {
        if let saved = UserDefaults.standard.string(forKey: key), let l = Lang(rawValue: saved) {
            return l
        }
        for code in Locale.preferredLanguages {
            let base = code.split(separator: "-").first.map(String.init) ?? code
            if let l = Lang(rawValue: base) { return l }
        }
        return .en
    }()

    static func setLanguage(_ l: Lang) {
        language = l
        UserDefaults.standard.set(l.rawValue, forKey: key)
    }

    static func random(_ kind: QuipKind) -> String {
        (table[language]?[kind] ?? table[.en]![kind] ?? ["…"]).randomElement() ?? "…"
    }

    // MARK: - The lines

    private static let table: [Lang: [QuipKind: [String]]] = [
        .en: [
            .done: ["It's done, boss.", "Taken care of.", "Clean job.", "Handled.",
                    "No witnesses.", "That's that.", "Job's finished.", "Like we never touched it."],
            .working: ["On it.", "Working.", "Doing the rounds.", "Almost there.", "…"],
            .waiting: ["Boss? A word.", "Waiting on you.", "Say the word.",
                       "Need your blessing.", "I ain't moving 'til you say."],
            .trouble: ["We got a problem.", "Heat's on.", "I got pinched.",
                       "Bad night, boss.", "They cut me off."],
            .idle: ["Quiet night.", "Nothing doing.", "Slow business.", "☕",
                    "Waiting on work.", "🦀"],
            .sleeping: ["z Z"],
            .beer: ["Ahh~", "That's the stuff.", "Salute."],
            .toast: ["🍻 To the family.", "🍻 Salute.", "🍻"],
            .greeting: ["👋", "Eyy.", "Paisan."],
            .compacting: ["Burning the books…", "🗜️", "Cleaning house…"],
            .compacted: ["Books are clean.", "grg 😮‍💨", "Nothing left to find."],
        ],
        .sk: [
            .done: ["Hotovo, šéfe.", "Vybavené.", "Čistá robota.", "Postarané.",
                    "Žiadni svedkovia.", "A je to.", "Šlus.", "Ani stopa po nás."],
            .working: ["Makám na tom.", "Robím.", "Obchádzam terén.", "Už to skoro je.", "…"],
            .waiting: ["Šéfe? Na slovíčko.", "Čakám na teba.", "Povedz slovo.",
                       "Potrebujem tvoje požehnanie.", "Nepohnem sa, kým nepovieš."],
            .trouble: ["Máme problém.", "Je horúco.", "Chytili ma.",
                       "Zlá noc, šéfe.", "Odstrihli ma."],
            .idle: ["Ticho ako v hrobe.", "Nič sa nedeje.", "Slabé kšefty.", "☕",
                    "Čakám na robotu.", "🦀"],
            .sleeping: ["z Z"],
            .beer: ["Ahh~", "To je ono.", "Na zdravie."],
            .toast: ["🍻 Na rodinu.", "🍻 Na zdravie.", "🍻"],
            .greeting: ["👋", "Nazdar.", "Braček."],
            .compacting: ["Pálim účtovníctvo…", "🗜️", "Upratujem…"],
            .compacted: ["Knihy sú čisté.", "grg 😮‍💨", "Niet čo nájsť."],
        ],
        .cs: [
            .done: ["Hotovo, šéfe.", "Vyřízeno.", "Čistá práce.", "Postaráno.",
                    "Žádní svědci.", "A je to.", "Šlus.", "Ani stopa po nás."],
            .working: ["Makám na tom.", "Dělám.", "Obcházím terén.", "Už to skoro je.", "…"],
            .waiting: ["Šéfe? Na slovíčko.", "Čekám na tebe.", "Řekni slovo.",
                       "Potřebuju tvoje požehnání.", "Nehnu se, dokud neřekneš."],
            .trouble: ["Máme problém.", "Je horko.", "Sebrali mě.",
                       "Špatná noc, šéfe.", "Odstřihli mě."],
            .idle: ["Ticho po pěšině.", "Nic se neděje.", "Slabý kšefty.", "☕",
                    "Čekám na práci.", "🦀"],
            .sleeping: ["z Z"],
            .beer: ["Ahh~", "To je ono.", "Na zdraví."],
            .toast: ["🍻 Na rodinu.", "🍻 Na zdraví.", "🍻"],
            .greeting: ["👋", "Nazdar.", "Brácho."],
            .compacting: ["Pálím účetnictví…", "🗜️", "Uklízím…"],
            .compacted: ["Knihy jsou čisté.", "grg 😮‍💨", "Není co najít."],
        ],
    ]
}
