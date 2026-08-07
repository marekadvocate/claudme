import Foundation

/// What a crab can say. Every line is in the voice of a made man reporting to his
/// boss — you. These are not translations of the English: each language was written
/// in its own crime-fiction register, so the jokes land for a native speaker.
///
/// Every language comes in two registers. `table` is the one a crab uses by default —
/// the crime film you'd watch with your parents in the room. `slangTable` is the street
/// version the same guy uses among his own: regional criminal argot, and it swears.
///
/// To add a language: add a case to `Lang` and an entry to `table`. A `slangTable` entry
/// is optional — anything missing there falls back to the clean line.
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
    case grumble       // sick of this patch of floor, moving on
    case friday        // deckchair weather
    case saturday      // deckchair, but it hurts
    case monday        // no chair, just an attitude
}

enum Lang: String, CaseIterable {
    case en, sk, cs, de, el, es, fr, hi, it, ja, ko, nl, pl, pt, ru, sv, tr, uk, zh

    var displayName: String {
        switch self {
        case .en: return "English"
        case .sk: return "Slovenčina"
        case .cs: return "Čeština"
        case .de: return "Deutsch"
        case .el: return "Ελληνικά"
        case .es: return "Español"
        case .fr: return "Français"
        case .hi: return "हिन्दी"
        case .it: return "Italiano"
        case .ja: return "日本語"
        case .ko: return "한국어"
        case .nl: return "Nederlands"
        case .pl: return "Polski"
        case .pt: return "Português"
        case .ru: return "Русский"
        case .sv: return "Svenska"
        case .tr: return "Türkçe"
        case .uk: return "Українська"
        case .zh: return "中文"
        }
    }
}

/// How foul-mouthed the family is allowed to be.
enum Register: String, CaseIterable {
    case clean, street

    var displayName: String {
        switch self {
        case .clean: return "Clean"
        case .street: return "Street talk"
        }
    }
}

enum Quips {
    private static let key = "ClaudmeLanguage"
    private static let registerKey = "ClaudmeRegister"

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

    /// Street by default — the crew swears, and the strong words ship censored so a line
    /// on a shared screen reads without being spelled out. Clean is one click away.
    static var register: Register = {
        guard let saved = UserDefaults.standard.string(forKey: registerKey) else { return .street }
        return Register(rawValue: saved) ?? .street
    }()

    static func setRegister(_ r: Register) {
        register = r
        UserDefaults.standard.set(r.rawValue, forKey: registerKey)
    }

    static func random(_ kind: QuipKind) -> String {
        // A missing street line is normal (`sleeping` has none), so fall through to the
        // clean table rather than showing a placeholder.
        if register == .street, let street = slangTable[language]?[kind], !street.isEmpty {
            return street.randomElement() ?? "…"
        }
        return (table[language]?[kind] ?? table[.en]![kind] ?? ["…"]).randomElement() ?? "…"
    }

    // MARK: - The lines

    private static let table: [Lang: [QuipKind: [String]]] = [
        .en: [
            .friday: ["Friday, boss.", "Nothing until Monday.", "The chair earned itself.", "Off the clock."],
            .saturday: ["Never again.", "Keep it down.", "Whose idea was that?", "I am not well."],
            .monday: ["Monday. Again.", "I want no part of this.", "Who scheduled this?", "Not today."],
            .grumble: ["Screw this corner.", "I'm done here, boss.", "Somebody else can watch it.", "That's me for tonight.", "Not my problem now."],
            .done: ["It's done, boss.", "Taken care of.", "Clean job.", "Handled.", "No witnesses.", "That's that.", "Job's finished.", "Like we never touched it."],
            .working: ["On it.", "Working.", "Doing the rounds.", "Almost there.", "…"],
            .waiting: ["Boss? A word.", "Waiting on you.", "Say the word.", "Need your blessing.", "I ain't moving 'til you say."],
            .trouble: ["We got a problem.", "Heat's on.", "I got pinched.", "Bad night, boss.", "They cut me off."],
            .idle: ["Quiet night.", "Nothing doing.", "Slow business.", "☕", "Waiting on work.", "🦀"],
            .beer: ["Ahh~", "That's the stuff.", "Salute."],
            .toast: ["🍻 To the family.", "🍻 Salute.", "🍻"],
            .greeting: ["👋", "Eyy.", "Paisan."],
            .compacting: ["Burning the books…", "🗜️", "Cleaning house…"],
            .compacted: ["Books are clean.", "grg 😮‍💨", "Nothing left to find."],
            .sleeping: ["z Z"],
        ],
        .sk: [
            .friday: ["Piatok, šéfe.", "Do pondelka nič.", "Toto som si zaslúžil.", "Mám padla."],
            .saturday: ["Už nikdy.", "Ticho, prosím ťa.", "Čí to bol nápad?", "Je mi zle."],
            .monday: ["Pondelok. Zase.", "Do tohto nejdem.", "Kto to takto naplánoval?", "Dnes nie."],
            .grumble: ["Serem na tento kút.", "Ja tu končím, šéfe.", "Nech to stráži niekto iný.", "Pre dnes som skončil.", "Už to nie je môj problém."],
            .done: ["Hotovo, šéfe.", "Vybavené.", "Čistá robota.", "Postarané.", "Žiadni svedkovia.", "A je to.", "Šlus.", "Ani stopa po nás."],
            .working: ["Makám na tom.", "Robím.", "Obchádzam terén.", "Už to skoro je.", "…"],
            .waiting: ["Šéfe? Na slovíčko.", "Čakám na teba.", "Povedz slovo.", "Potrebujem požehnanie.", "Nepohnem sa bez teba."],
            .trouble: ["Máme problém.", "Je horúco.", "Chytili ma.", "Zlá noc, šéfe.", "Odstrihli ma."],
            .idle: ["Ticho ako v hrobe.", "Nič sa nedeje.", "Slabé kšefty.", "☕", "Čakám na robotu.", "🦀"],
            .beer: ["Ahh~", "To je ono.", "Na zdravie."],
            .toast: ["🍻 Na rodinu.", "🍻 Na zdravie.", "🍻"],
            .greeting: ["👋", "Nazdar.", "Braček."],
            .compacting: ["Pálim účtovníctvo…", "🗜️", "Upratujem…"],
            .compacted: ["Knihy sú čisté.", "grg 😮‍💨", "Niet čo nájsť."],
            .sleeping: ["z Z"],
        ],
        .cs: [
            .friday: ["Pátek, šéfe.", "Do pondělí nic.", "Tohle jsem si zasloužil.", "Mám padla."],
            .saturday: ["Už nikdy.", "Ticho, prosím tě.", "Čí to byl nápad?", "Je mi zle."],
            .monday: ["Pondělí. Zase.", "Do tohohle nejdu.", "Kdo to takhle naplánoval?", "Dneska ne."],
            .grumble: ["Seru na tenhle kout.", "Já tu končím, šéfe.", "Ať to hlídá někdo jinej.", "Pro dnešek jsem skončil.", "Už to není můj problém."],
            .done: ["Hotovo, šéfe.", "Vyřízeno.", "Čistá práce.", "Postaráno.", "Žádní svědci.", "A je to.", "Šlus.", "Ani stopa po nás."],
            .working: ["Makám na tom.", "Dělám.", "Obcházím terén.", "Už to skoro je.", "…"],
            .waiting: ["Šéfe? Na slovíčko.", "Čekám na tebe.", "Řekni slovo.", "Potřebuju požehnání.", "Nehnu se bez tebe."],
            .trouble: ["Máme problém.", "Je horko.", "Sebrali mě.", "Špatná noc, šéfe.", "Odstřihli mě."],
            .idle: ["Ticho po pěšině.", "Nic se neděje.", "Slabý kšefty.", "☕", "Čekám na práci.", "🦀"],
            .beer: ["Ahh~", "To je ono.", "Na zdraví."],
            .toast: ["🍻 Na rodinu.", "🍻 Na zdraví.", "🍻"],
            .greeting: ["👋", "Nazdar.", "Brácho."],
            .compacting: ["Pálím účetnictví…", "🗜️", "Uklízím…"],
            .compacted: ["Knihy jsou čisté.", "grg 😮‍💨", "Není co najít."],
            .sleeping: ["z Z"],
        ],
        .de: [
            .friday: ["Freitag, Chef.", "Bis Montag nichts.", "Den hab ich mir verdient.", "Feierabend."],
            .saturday: ["Nie wieder.", "Leiser, bitte.", "Wessen Idee war das?", "Mir ist übel."],
            .monday: ["Montag. Schon wieder.", "Ohne mich.", "Wer plant so was?", "Heute nicht."],
            .grumble: ["Ich hab die Ecke satt.", "Für mich ist Feierabend.", "Soll ein anderer aufpassen.", "Nicht mehr mein Problem.", "Ich bin raus, Chef."],
            .done: ["Erledigt, Chef.", "Ist geregelt.", "Keine Zeugen.", "Sauber gemacht.", "Niemand sah was.", "War ein Klacks.", "Abgehakt, Chef.", "Problem ist weg."],
            .working: ["Bin dran.", "Läuft, Chef.", "Wird gemacht.", "Kleinen Moment.", "…"],
            .waiting: ["Chef? Kurz mal.", "Ein Wort, Chef.", "Brauch dein Okay.", "Chef, hörst du?", "Grünes Licht?"],
            .trouble: ["Wir haben ein Problem.", "Mich hat's erwischt.", "Bin aufgeflogen.", "Da lief was schief.", "Chef, ich steck fest."],
            .idle: ["Ruhige Nacht.", "Nix los, Chef.", "Geschäft schläft.", "Alles ruhig.", "☕", "🦀"],
            .beer: ["Ahh~", "Prost, Chef.", "Auf die Familie."],
            .toast: ["🍻 Prost!", "🍻 Auf die Familie!", "🍻 Auf uns, Chef!"],
            .greeting: ["👋", "Na, Kollege.", "Alles ruhig, Bruder?"],
            .compacting: ["Akten brennen.", "Ich räum auf.", "Weg mit den Beweisen."],
            .compacted: ["grg 😮‍💨", "Alles sauber.", "Keine Akten mehr."],
            .sleeping: ["z Z"],
        ],
        .el: [
            .friday: ["Παρασκευή, αρχηγέ.", "Τίποτα ως Δευτέρα.", "Το άξιζα.", "Σχόλασα."],
            .saturday: ["Ποτέ ξανά.", "Σιγά, σε παρακαλώ.", "Ποιανού ιδέα ήταν;", "Δεν πάω καλά."],
            .monday: ["Δευτέρα. Πάλι.", "Δεν παίζω.", "Ποιος το κανόνισε;", "Όχι σήμερα."],
            .grumble: ["Βαρέθηκα εδώ πέρα.", "Εγώ τελείωσα, αρχηγέ.", "Ας το φυλάει άλλος.", "Δεν με αφορά πια.", "Σχόλασα."],
            .done: ["Έγινε, αρχηγέ.", "Καθαρή δουλειά.", "Τακτοποιήθηκε.", "Κανένα ίχνος.", "Ήσυχα και ωραία.", "Δεν πήρε κανείς χαμπάρι.", "Στην εντέλεια.", "Άλλο τίποτα;"],
            .working: ["…", "Δουλεύω το θέμα.", "Μη με ζορίζεις.", "Ησυχία, το ψήνω.", "Το 'χω, το 'χω."],
            .waiting: ["Δώσε το οκ, αρχηγέ.", "Περιμένω εντολή.", "Εσύ λες, εγώ κάνω.", "Την ευλογία σου.", "Πες μου ναι."],
            .trouble: ["Μπλέξαμε, αρχηγέ.", "Κάτι στράβωσε.", "Μας έκοψαν τη βρύση.", "Πάτησα λάθος πόρτα.", "Ζόρια εδώ πέρα."],
            .idle: ["☕", "🦀", "Βαριέμαι.", "Καμιά δουλειά, αρχηγέ;", "Σκουριάζω εδώ.", "Μέρα μπαίνει, μέρα βγαίνει."],
            .beer: ["Στην υγειά σου, αρχηγέ.", "Μια γουλιά και πάμε.", "Παγωμένη, όπως πρέπει."],
            .toast: ["🍻 Στην οικογένεια!", "🍻 Γεια μας, μάγκα!", "🍻 Στην υγειά μας!"],
            .greeting: ["👋", "Όλα καλά, μάγκα;", "Τι λέει η πιάτσα;"],
            .compacting: ["Καίω τα χαρτιά.", "Καθαρίζω το σπίτι.", "Δεν μένει τίποτα."],
            .compacted: ["grg 😮‍💨", "Καθαρά τα βιβλία.", "Ούτε στάχτη δεν έμεινε."],
            .sleeping: ["z Z"],
        ],
        .es: [
            .friday: ["Viernes, jefe.", "Nada hasta el lunes.", "Me la he ganado.", "Se acabó por hoy."],
            .saturday: ["Nunca más.", "Más bajo, por favor.", "¿De quién fue la idea?", "Estoy fatal."],
            .monday: ["Lunes. Otra vez.", "Yo no entro en esto.", "¿Quién planeó esto?", "Hoy no."],
            .grumble: ["Me harté de esta esquina.", "Yo aquí terminé, jefe.", "Que vigile otro.", "Ya no es mi problema.", "Por hoy lo dejo."],
            .done: ["Hecho, jefe.", "Ya está.", "Trabajo limpio.", "Sin testigos.", "Nadie vio nada.", "Como si nada.", "Asunto resuelto.", "Ni rastro nuestro."],
            .working: ["En ello.", "Manos a la obra.", "Dando una vuelta.", "Ya casi está.", "…"],
            .waiting: ["¿Jefe? Un momento.", "Te espero.", "Tú dirás.", "Necesito tu bendición.", "Sin tu permiso, nada."],
            .trouble: ["Tenemos un problema.", "Esto se calienta.", "Me han pillado.", "Mala noche, jefe.", "Me cortaron el grifo."],
            .idle: ["Noche tranquila.", "Aquí no pasa nada.", "El negocio flojea.", "☕", "Esperando faena.", "🦀"],
            .beer: ["Ahh~", "Esto sí es vida.", "Salud."],
            .toast: ["🍻 Por la familia.", "🍻 Salud.", "🍻"],
            .greeting: ["👋", "Ey, primo.", "Compadre."],
            .compacting: ["Quemando los libros…", "🗜️", "Limpiando la casa…"],
            .compacted: ["Libros limpios.", "grg 😮‍💨", "No queda nada."],
            .sleeping: ["z Z"],
        ],
        .fr: [
            .friday: ["Vendredi, patron.", "Rien avant lundi.", "Je l'ai mérité.", "J'ai fini."],
            .saturday: ["Plus jamais.", "Moins fort, pitié.", "C'était l'idée de qui ?", "Je suis mal."],
            .monday: ["Lundi. Encore.", "Sans moi.", "Qui a prévu ça ?", "Pas aujourd'hui."],
            .grumble: ["J'en ai marre de ce coin.", "Moi j'ai fini, patron.", "Qu'un autre surveille.", "C'est plus mon problème.", "Pour moi c'est terminé."],
            .done: ["C'est réglé, patron.", "Emballé, c'est pesé.", "Du travail propre.", "Sans témoins.", "Personne n'a rien vu.", "L'affaire est faite.", "Nickel.", "Aucune trace."],
            .working: ["Je m'en occupe.", "Ça bosse.", "Je fais le tour.", "Presque fini.", "…"],
            .waiting: ["Patron ? Deux mots.", "J'attends votre feu vert.", "Dites un mot.", "Il me faut votre aval.", "Je bouge pas sans vous."],
            .trouble: ["On a un problème.", "Ça chauffe.", "Je me suis fait serrer.", "Sale nuit, patron.", "Ils m'ont coupé."],
            .idle: ["Nuit calme.", "Rien à signaler.", "Business au ralenti.", "☕", "J'attends du boulot.", "🦀"],
            .beer: ["Ahh~", "Ça fait du bien.", "Tchin."],
            .toast: ["🍻 À la famille.", "🍻 Tchin-tchin.", "🍻"],
            .greeting: ["👋", "Eh, cousin.", "Salut, frangin."],
            .compacting: ["Je brûle les livres…", "🗜️", "On fait le ménage…"],
            .compacted: ["Comptes propres.", "grg 😮‍💨", "Plus rien à trouver."],
            .sleeping: ["z Z"],
        ],
        .hi: [
            .friday: ["शुक्रवार है, बॉस।", "सोमवार तक कुछ नहीं।", "यह कुर्सी मेरा हक़ है।", "छुट्टी।"],
            .saturday: ["अब कभी नहीं।", "धीरे बोलो, प्लीज़।", "किसका आइडिया था?", "तबीयत ठीक नहीं।"],
            .monday: ["फिर सोमवार।", "मैं इसमें नहीं हूँ।", "यह किसने तय किया?", "आज नहीं।"],
            .grumble: ["इस कोने से ऊब गया।", "मेरा काम खत्म, बॉस।", "कोई और देखे।", "अब मेरी बला से।", "आज के लिए बस।"],
            .done: ["काम हो गया, भाई।", "काम तमाम।", "सफ़ाई हो गई।", "निपटा दिया।", "कोई गवाह नहीं।", "बस, ख़तम।", "एकदम साफ़।", "जैसे हुआ ही नहीं।"],
            .working: ["लगा हुआ हूँ।", "काम चालू है।", "गश्त पे हूँ।", "बस थोड़ा और।", "…"],
            .waiting: ["भाई? एक बात।", "आपका इंतज़ार है।", "हुक्म करो।", "इजाज़त चाहिए।", "आप कहो, तब।"],
            .trouble: ["गड़बड़ हो गई।", "माहौल गरम है।", "पकड़ा गया।", "रात ख़राब है।", "लाइन काट दी।"],
            .idle: ["सन्नाटा है।", "कुछ नहीं हो रहा।", "धंधा मंदा है।", "☕", "काम का इंतज़ार।", "🦀"],
            .beer: ["आह~", "वाह, क्या बात।", "चीयर्स।"],
            .toast: ["🍻 फ़ैमिली के नाम।", "🍻 चीयर्स।", "🍻"],
            .greeting: ["👋", "अरे भाई!", "सलाम।"],
            .compacting: ["बही जला रहा हूँ…", "🗜️", "सफ़ाई चालू है…"],
            .compacted: ["हिसाब साफ़।", "grg 😮‍💨", "कुछ नहीं मिलेगा।"],
            .sleeping: ["z Z"],
        ],
        .it: [
            .friday: ["Venerdì, capo.", "Niente fino a lunedì.", "Me la sono guadagnata.", "Ho staccato."],
            .saturday: ["Mai più.", "Più piano, ti prego.", "Di chi è stata l'idea?", "Sto male."],
            .monday: ["Lunedì. Di nuovo.", "Io non ci sto.", "Chi ha organizzato questo?", "Oggi no."],
            .grumble: ["Basta con questo angolo.", "Io ho finito, capo.", "Ci pensi un altro.", "Non è più affar mio.", "Per stasera ho chiuso."],
            .done: ["Fatto, capo.", "Sistemato.", "Lavoro pulito.", "Nessun testimone.", "Nessuno ha visto niente.", "Cosa fatta capo ha.", "Tutto a posto.", "Manco una traccia."],
            .working: ["Ci penso io.", "Sto lavorando.", "Faccio il giro.", "Ci siamo quasi.", "…"],
            .waiting: ["Capo, due parole.", "Aspetto un cenno.", "Dimmi tu.", "Mi serve la benedizione.", "Non muovo un dito."],
            .trouble: ["Abbiamo un problema.", "Si mette male.", "Mi hanno beccato.", "Brutta serata, capo.", "M'hanno tagliato fuori."],
            .idle: ["Notte tranquilla.", "Non si muove niente.", "Affari fiacchi.", "☕", "Aspetto lavoro.", "🦀"],
            .beer: ["Ahh~", "Questa sì che è vita.", "Salute."],
            .toast: ["🍻 Alla famiglia.", "🍻 Cin cin.", "🍻"],
            .greeting: ["👋", "Uè, compà.", "Guagliò."],
            .compacting: ["Brucio i libri…", "🗜️", "Faccio pulizia…"],
            .compacted: ["Libri puliti.", "grg 😮‍💨", "Non c'è più niente."],
            .sleeping: ["z Z"],
        ],
        .ja: [
            .friday: ["金曜だ、親父", "月曜まで何もせん", "この椅子は当然だ", "上がりだ"],
            .saturday: ["二度とやらん", "静かにしてくれ", "誰の案だ、あれは", "具合が悪い"],
            .monday: ["また月曜か", "俺は降りる", "誰が組んだんだ", "今日は無理だ"],
            .grumble: ["この隅はもう飽きた", "俺は上がりだ、親父", "誰か代われ", "もう知らん", "今日はここまでだ"],
            .done: ["終わりやした、親分", "片付けやした", "カタはつけました", "始末しときやした", "キレイに掃除済み", "証拠は残してねぇ", "お安いご用で", "完璧でさぁ"],
            .working: ["やってやす", "仕事中でさぁ", "…", "今、詰めてやす", "もうちょい待ってくんな"],
            .waiting: ["親分、ちょいと", "親分、お耳を", "やっていいですかい", "お指図を", "どうしやしょう"],
            .trouble: ["親分、ヤバいっす", "パクられやした", "しくじりやした", "手が出せねぇ", "ガサ入れでさぁ"],
            .idle: ["静かな夜でさぁ", "シケてやがる", "☕", "🦀", "シノギがねぇ", "暇でさぁ、親分"],
            .beer: ["ぷはぁ〜", "たまらねぇ", "五臓六腑に染みらぁ"],
            .toast: ["🍻 かんぱーい", "🍻 兄弟の盃だ", "🍻 親分に!"],
            .greeting: ["👋", "お疲れさんです", "ちわーっす、兄貴"],
            .compacting: ["帳簿、燃やしやす", "証拠隠滅中", "部屋をキレイに"],
            .compacted: ["grg 😮‍💨", "スッキリしたぜ", "何も残ってねぇ"],
            .sleeping: ["z Z"],
        ],
        .ko: [
            .friday: ["금요일입니다, 보스.", "월요일까지 아무것도.", "이 의자는 당연하죠.", "퇴근입니다."],
            .saturday: ["두 번은 안 합니다.", "조용히 좀.", "누구 아이디어였죠?", "몸이 안 좋습니다."],
            .monday: ["또 월요일.", "저는 빠지겠습니다.", "누가 이렇게 짰죠?", "오늘은 아닙니다."],
            .grumble: ["이 구석 지겹다.", "저는 여기까지입니다.", "딴 놈이 지켜라.", "이제 내 일 아니다.", "오늘은 끝."],
            .done: ["끝냈습니다, 형님", "처리했습니다", "깔끔하게 정리", "뒤탈 없습니다", "목격자 없습니다", "손 좀 봤습니다", "다 묻었습니다", "걱정 마이소, 형님"],
            .working: ["하고 있습니다", "작업 중입니다", "…", "손보는 중", "곧 됩니다, 형님"],
            .waiting: ["형님, 잠깐만", "형님, 한 말씀", "지시 기다립니다", "허락만 주십쇼", "어떻게 할까요?"],
            .trouble: ["형님, 문제 생겼습니다", "짭새 떴습니다", "일이 꼬였습니다", "저 잡혔습니다", "손 못 씁니다"],
            .idle: ["조용한 밤이네", "장사 안 되네", "☕", "🦀", "할 일이 없네", "심심하다..."],
            .beer: ["캬~", "크으, 좋다", "시원하다"],
            .toast: ["🍻 위하여!", "🍻 형님을 위해!", "🍻 원샷!"],
            .greeting: ["👋", "형님, 오셨습니까", "수고하십니다"],
            .compacting: ["장부 태우는 중", "증거 인멸 중", "청소 좀 하자"],
            .compacted: ["grg 😮‍💨", "속이 편하네", "깨끗합니다, 형님"],
            .sleeping: ["z Z"],
        ],
        .nl: [
            .friday: ["Vrijdag, baas.", "Niks tot maandag.", "Die heb ik verdiend.", "Ik ben klaar."],
            .saturday: ["Nooit meer.", "Zachtjes, alsjeblieft.", "Wiens idee was dat?", "Ik voel me beroerd."],
            .monday: ["Maandag. Alweer.", "Zonder mij.", "Wie heeft dit gepland?", "Vandaag niet."],
            .grumble: ["Ik baal van deze hoek.", "Ik ben klaar, baas.", "Laat een ander kijken.", "Niet meer mijn probleem.", "Voor vandaag klaar."],
            .done: ["Geregeld, baas.", "Het is gepiept.", "Geen getuigen.", "Netjes opgeruimd.", "Klaar is Kees.", "Niemand zag wat.", "Makkie, baas.", "Weg is weg."],
            .working: ["Bezig, baas.", "Komt voor elkaar.", "Ik regel het.", "Momentje.", "…"],
            .waiting: ["Baas? Effe wat.", "Eén woordje, baas.", "Jouw fiat, baas?", "Mag het, baas?", "Baas, hoor je me?"],
            .trouble: ["We hebben een probleem.", "Ik ben gesnapt.", "Ze pakten me, baas.", "Het ging mis, baas.", "Ik zit klem."],
            .idle: ["Rustige nacht.", "Niks te doen.", "Slappe handel.", "Stil op straat.", "☕", "🦀"],
            .beer: ["Ahh~", "Proost, baas.", "Op de familie."],
            .toast: ["🍻 Proost!", "🍻 Op de familie!", "🍻 Op jou, baas!"],
            .greeting: ["👋", "Alles goed, maat?", "Hé, collega."],
            .compacting: ["Boeken verbranden.", "Ik ruim op.", "Bewijs de fik in."],
            .compacted: ["grg 😮‍💨", "Schoon schip.", "Geen papieren meer."],
            .sleeping: ["z Z"],
        ],
        .pl: [
            .friday: ["Piątek, szefie.", "Nic do poniedziałku.", "Zasłużyłem.", "Fajrant."],
            .saturday: ["Nigdy więcej.", "Ciszej, proszę.", "Czyj to był pomysł?", "Źle się czuję."],
            .monday: ["Poniedziałek. Znowu.", "Beze mnie.", "Kto to zaplanował?", "Nie dzisiaj."],
            .grumble: ["Mam dość tego kąta.", "Ja kończę, szefie.", "Niech inny pilnuje.", "To już nie mój problem.", "Na dziś koniec."],
            .done: ["Załatwione, szefie.", "Po robocie.", "Czysto.", "Bez świadków.", "Leży.", "Grzecznie poszło.", "Masz to jak w banku.", "Temat zamknięty."],
            .working: ["Robi się.", "Działamy.", "Kręcę temat.", "…", "Jestem na temacie."],
            .waiting: ["Szefie, na słówko.", "Daj cynk.", "Czekam na znak.", "Kiwnij głową.", "Twoja decyzja, szefie."],
            .trouble: ["Mamy problem.", "Wpadłem.", "Sypie się.", "Psy węszą.", "Nawaliło."],
            .idle: ["Cisza jak w grobie.", "Spokojna noc.", "Interes stoi.", "☕", "🦀", "Nudy na pudy."],
            .beer: ["Ahh~", "Zdrówko.", "Zimne jak trzeba."],
            .toast: ["🍻 Na zdrowie!", "🍻 Za rodzinę!", "🍻 Sto lat, szefie!"],
            .greeting: ["👋", "Uszanowanie.", "Siemka, kuzyn."],
            .compacting: ["Palę papiery.", "Sprzątam.", "Do niszczarki."],
            .compacted: ["grg 😮‍💨", "Czysto jak łza.", "Nic nie znajdą."],
            .sleeping: ["z Z"],
        ],
        .pt: [
            .friday: ["Sexta, chefe.", "Nada até segunda.", "Mereci essa.", "Encerrei."],
            .saturday: ["Nunca mais.", "Mais baixo, por favor.", "De quem foi a ideia?", "Estou mal."],
            .monday: ["Segunda. De novo.", "Não conte comigo.", "Quem planejou isso?", "Hoje não."],
            .grumble: ["Cansei desse canto.", "Eu terminei, chefe.", "Que outro vigie.", "Já não é problema meu.", "Por hoje chega."],
            .done: ["Tá feito, chefe.", "Resolvido.", "Serviço limpo.", "Sem testemunha.", "Eu nem tava lá.", "Tá tudo certo.", "Tá limpo, chefia.", "Pode conferir."],
            .working: ["Tô nessa.", "Trabalhando.", "Dando um rolê.", "Quase lá.", "…"],
            .waiting: ["Chefe? Uma palavrinha.", "Tô te esperando.", "É só falar.", "Preciso da sua bênção.", "Só ando se mandar."],
            .trouble: ["Deu ruim, chefe.", "Tá quente aqui.", "Me pegaram.", "Noite ruim, chefe.", "Me cortaram."],
            .idle: ["Noite parada.", "Nada rolando.", "Movimento fraco.", "☕", "Esperando serviço.", "🦀"],
            .beer: ["Ahh~", "Essa desce bem.", "Saúde."],
            .toast: ["🍻 À família.", "🍻 Saúde.", "🍻"],
            .greeting: ["👋", "Salve.", "E aí, parça."],
            .compacting: ["Queimando os papéis…", "🗜️", "Limpando a área…"],
            .compacted: ["Não sobrou papel.", "grg 😮‍💨", "Tá tudo limpo."],
            .sleeping: ["z Z"],
        ],
        .ru: [
            .friday: ["Пятница, шеф.", "До понедельника ничего.", "Я заслужил.", "Смена окончена."],
            .saturday: ["Больше никогда.", "Тише, умоляю.", "Чья это была идея?", "Мне нехорошо."],
            .monday: ["Понедельник. Опять.", "Я в этом не участвую.", "Кто это придумал?", "Не сегодня."],
            .grumble: ["Надоел мне этот угол.", "Я закончил, шеф.", "Пусть другой сторожит.", "Уже не моя забота.", "На сегодня всё."],
            .done: ["Готово, шеф.", "Вопрос решён.", "Чисто сработано.", "Без свидетелей.", "Всё пучком.", "Дело сделано.", "Как заказывали.", "Тип-топ, босс."],
            .working: ["Работаю.", "Уже в теме.", "Решаю вопрос.", "…", "Кручусь."],
            .waiting: ["Шеф, на два слова.", "Жду отмашки.", "Дай добро.", "Твоё слово, босс.", "Тут дело такое…"],
            .trouble: ["У нас проблема.", "Меня приняли.", "Кипиш!", "Всё пошло не так.", "Мусора нагрянули."],
            .idle: ["Тихая ночь.", "Дел нет.", "Скука смертная.", "☕", "🦀", "Затишье."],
            .beer: ["Ахх~", "Будем.", "Хорошо пошла."],
            .toast: ["🍻 За семью!", "🍻 Ну, будем!", "🍻 За тех, кто в деле!"],
            .greeting: ["👋", "Здорово, брат.", "Моё почтение."],
            .compacting: ["Жгу бумаги.", "Чищу хвосты.", "Концы в воду."],
            .compacted: ["grg 😮‍💨", "Улик нет.", "Ни следа."],
            .sleeping: ["z Z"],
        ],
        .sv: [
            .friday: ["Fredag, chefen.", "Inget förrän måndag.", "Den har jag förtjänat.", "Jag har slutat."],
            .saturday: ["Aldrig igen.", "Tystare, tack.", "Vems idé var det?", "Jag mår illa."],
            .monday: ["Måndag. Igen.", "Inte med mig.", "Vem planerade det här?", "Inte idag."],
            .grumble: ["Jag är trött på hörnet.", "Jag är klar, chefen.", "Nån annan får vakta.", "Inte mitt problem längre.", "Slut för idag."],
            .done: ["Fixat, boss.", "Det är ordnat.", "Inga vittnen.", "Städat och klart.", "Ingen såg nåt.", "En barnlek.", "Klart som korvspad.", "Problemet är borta."],
            .working: ["Jobbar på det.", "Jag fixar det.", "På gång, boss.", "Ett ögonblick.", "…"],
            .waiting: ["Boss? Ett ord.", "Behöver ditt ok.", "Grönt ljus, boss?", "Boss, hör du mig?", "Får jag, boss?"],
            .trouble: ["Vi har ett problem.", "Jag åkte dit.", "Det gick åt skogen.", "Nåt gick snett.", "Jag sitter fast."],
            .idle: ["Lugn natt.", "Inget på gång.", "Trög affär.", "Tyst på gatan.", "☕", "🦀"],
            .beer: ["Ahh~", "Skål, boss.", "För familjen."],
            .toast: ["🍻 Skål!", "🍻 För familjen!", "🍻 Skål, boss!"],
            .greeting: ["👋", "Läget, brorsan?", "Tjena, kollega."],
            .compacting: ["Bränner böckerna.", "Städar undan.", "Bort med bevisen."],
            .compacted: ["grg 😮‍💨", "Rent hus.", "Inga papper kvar."],
            .sleeping: ["z Z"],
        ],
        .tr: [
            .friday: ["Cuma, reis.", "Pazartesiye kadar yok.", "Hak ettim.", "Paydos."],
            .saturday: ["Bir daha asla.", "Sessiz ol, lütfen.", "Kimin fikriydi bu?", "İyi değilim."],
            .monday: ["Pazartesi. Yine.", "Ben yokum.", "Bunu kim ayarladı?", "Bugün olmaz."],
            .grumble: ["Bu köşeden bıktım.", "Ben bitirdim reis.", "Başkası baksın.", "Artık benim sorunum değil.", "Bugünlük bu kadar."],
            .done: ["Halloldu reis.", "İş bitti.", "Temiz iş.", "İcabına bakıldı.", "Tanık yok.", "Tamamdır.", "Sildim süpürdüm.", "Hiç uğramadık bile."],
            .working: ["Hallediyorum.", "Çalışıyorum.", "Tur atıyorum.", "Az kaldı.", "…"],
            .waiting: ["Reis, bir çift laf.", "Seni bekliyorum.", "Emret reis.", "Onayını bekliyorum.", "Sen demeden kıpırdamam."],
            .trouble: ["Bir sorun var reis.", "Ortalık kızıştı.", "Enselendim.", "Kötü gece reis.", "Fişimi çektiler."],
            .idle: ["Sakin gece.", "Olay yok.", "İşler kesat.", "☕", "İş bekliyorum.", "🦀"],
            .beer: ["Ahh~", "İşte bu.", "Şerefe."],
            .toast: ["🍻 Aileye.", "🍻 Şerefe.", "🍻"],
            .greeting: ["👋", "Eyvallah.", "Naber kardeş."],
            .compacting: ["Defterleri yakıyorum…", "🗜️", "Ortalığı topluyorum…"],
            .compacted: ["Defterler tertemiz.", "grg 😮‍💨", "Bulacak şey yok."],
            .sleeping: ["z Z"],
        ],
        .uk: [
            .friday: ["П'ятниця, шефе.", "До понеділка нічого.", "Я заслужив.", "Зміна скінчилась."],
            .saturday: ["Більше ніколи.", "Тихіше, благаю.", "Чия це була ідея?", "Мені зле."],
            .monday: ["Понеділок. Знову.", "Я в цьому не беру участі.", "Хто це вигадав?", "Не сьогодні."],
            .grumble: ["Набрид мені цей кут.", "Я закінчив, шефе.", "Хай інший вартує.", "Вже не мій клопіт.", "На сьогодні все."],
            .done: ["Зроблено, шефе.", "Питання закрите.", "Без свідків.", "Чисто спрацював.", "Все як треба.", "Тихо і красиво.", "Як просили, шефе.", "Ніхто нічого не бачив."],
            .working: ["Роблю.", "Працюємо.", "Вже в темі.", "…", "Кручусь, шефе."],
            .waiting: ["Шефе, на два слова.", "Чекаю відмашки.", "Дай добро.", "Твоє слово, босе.", "Кивни — і зроблю."],
            .trouble: ["У нас проблема.", "Мене прийняли.", "Шухер!", "Все пішло не так.", "Менти на хвості."],
            .idle: ["Тиха ніч.", "Діла нема.", "Нудьга смертна.", "☕", "🦀", "Затишшя."],
            .beer: ["Аххх~", "Будьмо!", "Гарно пішла."],
            .toast: ["🍻 Будьмо!", "🍻 За родину!", "🍻 За наших!"],
            .greeting: ["👋", "Здоров, брате.", "Моє шанування."],
            .compacting: ["Палю папери.", "Чищу хвости.", "Кінці у воду."],
            .compacted: ["grg 😮‍💨", "Доказів нема.", "Чисто, як сльоза."],
            .sleeping: ["z Z"],
        ],
        .zh: [
            .friday: ["周五了，大哥", "周一之前什么都不干", "这椅子我配得上", "收工"],
            .saturday: ["再也不来了", "小声点", "谁出的主意", "我不舒服"],
            .monday: ["又是周一", "这事我不掺和", "谁排的班", "今天不行"],
            .grumble: ["这角落待腻了", "我收工了，大哥", "让别人看着吧", "不关我事了", "今天到此为止"],
            .done: ["办妥了，大哥", "搞定收工", "干净利落", "手尾干净", "没人看见", "小菜一碟", "大哥放心", "全清了"],
            .working: ["正在办", "忙着呢", "…", "快好了，大哥", "别催，大哥"],
            .waiting: ["大哥，借一步", "等您示下", "大哥，请示", "要不要动手？", "您说了算"],
            .trouble: ["大哥，出事了", "条子来了", "办砸了", "我被扣住了", "顶不住了"],
            .idle: ["今晚真静", "生意淡", "☕", "🦀", "没活干", "闲得慌"],
            .beer: ["爽", "哈~", "够劲"],
            .toast: ["🍻 饮胜！", "🍻 干杯！", "🍻 敬大哥！"],
            .greeting: ["👋", "大哥好", "自己人"],
            .compacting: ["烧账本", "清理门户", "毁尸灭迹"],
            .compacted: ["grg 😮‍💨", "干净了", "什么都没了"],
            .sleeping: ["z Z"],
        ],
    ]

    /// The street register. Same crew, no boss in earshot.
    private static let slangTable: [Lang: [QuipKind: [String]]] = [
        .en: [
            .done: ["Sorted, guv.", "Piece of p_ss.", "F_ckin' done.", "Job's a good 'un.", "Nailed the f_cker.", "Bosh. Next one.", "Buried the body.", "Told ya. Easy."],
            .working: ["…", "Workin' on it, guv.", "Sh_t's all tangled.", "Give us a minute.", "Nearly f_ckin' there."],
            .waiting: ["Boss? Your call.", "Say the word.", "Waitin' on you, guv.", "Green light or what?", "Nod and it's done."],
            .trouble: ["We got a problem.", "F_cked. Rate limit.", "They cut us off.", "Gone pear-shaped.", "Sh_t. Hold up."],
            .idle: ["☕", "🦀", "Bored out me nut.", "Nothin' doin'.", "Give us a job, guv.", "F_ck all happenin'."],
            .beer: ["Cheers, son.", "Earned this one.", "Lovely drop, that."],
            .toast: ["🍻 To the boss.", "🍻 To no witnesses.", "🍻 Chin chin, son."],
            .greeting: ["👋", "Alright, son?", "Oi oi, geezer."],
            .compacting: ["Burnin' the books.", "Never happened.", "Torch the paperwork."],
            .compacted: ["grg 😮‍💨", "Ashes now.", "What books, guv?"],
            .grumble: ["This corner's dead.", "Movin' me pitch.", "Bored of this bit.", "Sod this spot.", "F_ck this corner."],
            .friday: ["Off the clock, guv.", "Friday. Do one.", "Not a f_ckin' finger.", "Sun's out. Done."],
            .saturday: ["Me head, lads.", "Never again.", "Feel like sh_t.", "Who let me drink?"],
            .monday: ["Monday. F_ck's sake.", "Back on the graft.", "Hate this, me.", "Who nicked me chair?"],
        ],
        .sk: [
            .done: ["Hotovo, šéfe.", "Vybavené, kurva.", "Čisté ako sklo.", "Nikto nič nevidel.", "Ani som sa nezapotil.", "Máme to v suchu.", "Pošli ďalšieho.", "Kto je tu majster?"],
            .working: ["…", "Makám, do riti.", "Skadzi paru zoberem.", "Neruš ma, kurva.", "Ešte chvíľu, do p_če."],
            .waiting: ["Šéfe, čo s tým?", "Potrebujem zelenú.", "Kývni a idem.", "No tak, kurva, povedz.", "Čakám, do riti."],
            .trouble: ["Kurva, odrezali ma.", "J_bem na to.", "Do p_če, padá to.", "Zas ma zablokovali.", "Nasrat na to."],
            .idle: ["☕", "🦀", "Nuda, do riti.", "Nikto nič nerobí?", "Ticho ako v hrobe.", "Dajte mi robotu."],
            .beer: ["Na zdravie, kurva.", "Zaslúžené.", "Ešte jedno, šéfe."],
            .toast: ["🍻 Na rodinu.", "🍻 Nech to j_be!", "🍻 Na šéfa!"],
            .greeting: ["👋", "Čau, brácho.", "Ako ide kšeft?"],
            .compacting: ["Pálim papiere.", "Nič tu nebolo.", "Šreduj to, kurva."],
            .compacted: ["grg 😮‍💨", "Popol a nič.", "Čistý stôl, šéfe."],
            .grumble: ["Tu už nič nie je.", "Idem inam, do riti.", "Nudné miesto, kurva.", "Presúvam sa.", "Toto je na h_vno."],
            .friday: ["Piatok, kurva!", "Dnes už nič.", "Šichta skončila.", "Mám voľno, nechaj ma."],
            .saturday: ["Kurva, hlava.", "Nikdy viac.", "Ticho, prosím ťa.", "Do riti s borovičkou."],
            .monday: ["Pondelok, do p_če.", "Nechce sa mi.", "Kto vymyslel pondelok?", "Kávu. Hneď."],
        ],
        .cs: [
            .done: ["Hotovo, kurva.", "Vyj_bal jsem s tím.", "Zakopáno. Kdo dál?", "Po nás ani hovno.", "Lehký prachy, kurva.", "Sfouknutý levou zadní.", "Čistá práce, do prdele.", "Nikdo nic neviděl."],
            .working: ["Makám, do prdele.", "Jsem v tom po lokty.", "J_be mě z toho.", "Ještě chvíli, kurva.", "…"],
            .waiting: ["Šéfe, kurva, halo?", "Čekám tu jak vůl.", "Kejvni a jedu.", "Bez tebe se nehnu.", "Šéfe, seš hluchej?"],
            .trouble: ["Jsme v prdeli, šéfe.", "Posralo se to, kurva.", "Sebrali mě chlupatý.", "Uťali mi to, zmr_i.", "To je celý v p_či."],
            .idle: ["☕", "🦀", "Ani pes neštěkne.", "Kšefty za hovno.", "Chcípl tu pes.", "Kdy už bude kšeft, kurva?"],
            .beer: ["Ahh~ kurva, to je ono.", "Do dna, chlapi.", "Tohle sem potřeboval."],
            .toast: ["🍻 Na rodinu, kurva!", "🍻 Ať nás nechytnou.", "🍻 Na ty, co sedí!"],
            .greeting: ["👋", "Čau, ty grázle.", "Zdar, ty starej hajzle."],
            .compacting: ["Pálím účetnictví…", "Do pece s tím, kurva…", "Zametám stopy…"],
            .compacted: ["grg 😮‍💨", "Knihy jsou popel.", "Nenajdou ani hovno."],
            .grumble: ["J_bu na tenhle flek.", "Mám toho plný zuby.", "Jdu jinam, kurva.", "Ať to hlídá někdo jinej.", "Tady je to na hovno."],
            .friday: ["Pátek, kurva!", "Do pondělí ani hovno.", "Padla, šéfe.", "Zasloužil sem si to."],
            .saturday: ["Už nikdy, kurva.", "Ticho, prosím tě.", "Čí to byl nápad?", "Hlava mi j_be."],
            .monday: ["Pondělí. Zase, kurva.", "Do tohohle nejdu.", "Kdo to kurva naplánoval?", "Dneska na to seru."],
        ],
        .de: [
            .done: ["Erledigt, Boss.", "Sauber gemacht.", "Sch_iße, bin ich gut.", "Weg damit.", "Fertig, verdammt.", "Keine Spuren.", "Läuft bei mir.", "War 'n Klacks."],
            .working: ["…", "Bin dran.", "So 'n Sch_iß hier.", "Moment, Boss.", "Gleich hab ich's."],
            .waiting: ["Boss? Dein Wort.", "Warte auf dich.", "Sag Bescheid.", "Grünes Licht?", "Ja oder nein, Boss?"],
            .trouble: ["Wir haben ein Problem.", "Alles im A_sch.", "Limit. Sch_iße.", "Die haben dichtgemacht.", "Läuft nicht, Boss."],
            .idle: ["☕", "🦀", "Mir ist stinklangweilig.", "Nix los hier.", "Gib mir Arbeit.", "Tote Hose."],
            .beer: ["Prost, Bruder.", "Hab ich mir verdient.", "Das tut gut."],
            .toast: ["🍻 Auf den Boss.", "🍻 Auf uns.", "🍻 Auf keine Zeugen."],
            .greeting: ["👋", "Na, Alter?", "Alles fit?"],
            .compacting: ["Akten brennen.", "Nie passiert.", "Papiere in den Ofen."],
            .compacted: ["grg 😮‍💨", "Alles Asche.", "Welche Akten?"],
            .grumble: ["Diese Ecke nervt.", "Ich zieh weiter.", "Sch_iß Platz hier.", "Hier ist alles tot.", "Neuer Posten."],
            .friday: ["Feierabend, Boss.", "Freitag. Nix mehr.", "Keinen Finger krumm.", "Sonne und Ruhe."],
            .saturday: ["Mein Schädel.", "Nie wieder.", "Mir ist kotzübel.", "Wer ließ mich saufen?"],
            .monday: ["Montag. Sch_iße.", "Wieder ackern.", "Kein Bock, Boss.", "Wo ist mein Stuhl?"],
        ],
        .el: [
            .done: ["Καθαρή δουλειά, ρε.", "Τσακ μπαμ, αφεντικό.", "Γ_μάτο, ε;", "Δεν άφησα ίχνος.", "Ξηγήθηκα βασιλικά.", "Τα διέλυσα, γαμώτο.", "Παιχνιδάκι, μαλ_κα.", "Ούτε γάτα ούτε ζημιά."],
            .working: ["…", "Δούλευε, μη μιλάς.", "Γαμώτο, τι μπάχαλο.", "Μη με ζορίζεις τώρα.", "Το 'χω, μαλ_κα, ήσυχα."],
            .waiting: ["Λέγε, αφεντικό.", "Μπαίνω ή όχι, ρε;", "Περιμένω σήμα, γαμώτο.", "Πες μου ένα ναι, ρε.", "Δε σαλεύω χωρίς εσένα."],
            .trouble: ["Γαμ_θηκε το πράμα.", "Μπάτσοι, αφεντικό!", "Μας κόψανε τη φόρα.", "Έφαγα πόρτα, γαμώτο.", "Σκατά. Με τσακώσανε."],
            .idle: ["☕", "🦀", "Ψόφια πράματα, ρε.", "Σκουριάζω, γαμώτο.", "Βαριέμαι σαν μαλ_κας.", "Τίποτα δεν παίζει."],
            .beer: ["Μια γουλιά μόνο, ρε.", "Κρύα σαν πάγος.", "Έχει ανάγκες κι ο μάγκας."],
            .toast: ["🍻 Άσπρο πάτο, ρε!", "🍻 Γεια μας, μαλ_κες!", "🍻 Για την οικογένεια!"],
            .greeting: ["👋", "Έλα, μάγκα μου.", "Τι λέει, μαλ_κα;"],
            .compacting: ["Καίω τα χαρτιά, ρε.", "Στάχτη και μπούρμπερη.", "Καθαρίζω το σπίτι."],
            .compacted: ["grg 😮‍💨", "Ούτε στάχτη έμεινε.", "Δε βρίσκουν γρι, ρε."],
            .grumble: ["Βαρέθηκα τη γωνιά.", "Ας κάτσει άλλος, ρε.", "Τέλος, την κάνω.", "Γαμώτο, φεύγω από δω.", "Δε με αφορά πια."],
            .friday: ["Παρασκευή, ρε μάγκα!", "Τίποτα ως τη Δευτέρα.", "Σχόλασα, αφεντικό.", "Το καρεκλάκι μου."],
            .saturday: ["Ποτέ ξανά, γαμώτο.", "Σιγά, πονάει η κούτρα.", "Ποιανού ιδέα ήταν;", "Χάλια, μαλ_κα."],
            .monday: ["Δευτέρα. Πάλι. Γαμώτο.", "Άσε με ήσυχο, ρε.", "Ποιος το κανόνισε;", "Όχι σήμερα, μαλ_κα."],
        ],
        .es: [
            .done: ["Hecho, jefe. Sin ruido.", "De p_ta madre, ¿eh?", "Ni una p_ta huella.", "Enterrado y bien hondo.", "Nadie vio una mierda.", "Fino de cojones.", "Zanjado. Siguiente.", "Ni Dios se entera."],
            .working: ["…", "J_der, vaya marrón.", "Callado y currando.", "Estoy en ello, hostia.", "No me toques los huevos."],
            .waiting: ["Jefe, suelta algo.", "¿Entro o qué, j_der?", "Sin tu palabra no me muevo.", "¿Estás sordo, jefe?", "Dame el visto bueno ya."],
            .trouble: ["Se ha j_dido, jefe.", "Estamos bien j_didos.", "Cortaron el p_to grifo.", "Esto huele a madero.", "Me han pillado, mierda."],
            .idle: ["☕", "🦀", "Tocándome los huevos.", "Aquí no se mueve ni Dios.", "Me estoy pudriendo aquí.", "Ni un p_to trabajo hoy."],
            .beer: ["Aahh~ qué gusto, j_der.", "Una fría y a callar.", "Esto sí es vida."],
            .toast: ["🍻 Por la familia.", "🍻 Que les den a todos.", "🍻 A los que no están."],
            .greeting: ["👋", "¿Qué pasa, c_brón?", "Buenas, primo."],
            .compacting: ["Quemando los papeles.", "Fuera pruebas, j_der.", "Limpieza a fondo."],
            .compacted: ["grg 😮‍💨", "Cenizas, jefe.", "Que busquen. No hay nada."],
            .grumble: ["Me cago en esta esquina.", "Que la vigile otro.", "Yo aquí no vuelvo.", "A la mierda este rincón.", "Me piro, jefe."],
            .friday: ["Viernes. A tomar por saco.", "Hasta el lunes, nada.", "Ni me llames, jefe.", "Esta tumbona es mía."],
            .saturday: ["No vuelvo a beber. Nunca.", "Baja la p_ta voz.", "¿De quién fue la idea?", "Me muero, jefe."],
            .monday: ["Lunes. Me cago en todo.", "Hoy no, j_der.", "¿Quién planeó esta mierda?", "Que le den al lunes."],
        ],
        .fr: [
            .done: ["C'est plié, boss.", "P_tain, propre de ouf.", "Zéro trace, wesh.", "J'ai n_qué le taf.", "Personne a rien vu.", "Chanmé, non ?", "Emballé. Au suivant.", "Nickel, boss. Tranquille."],
            .working: ["…", "P_tain, ce bordel.", "Je gère, lâche-moi.", "Ça bosse, wesh.", "Deux secondes, reuf."],
            .waiting: ["Boss, tu dis quoi ?", "J'y go ou pas ?", "J'attends le go, wesh.", "Sans toi je bouge pas.", "Boss, t'es sourd ou ?"],
            .trouble: ["On est grillés, p_tain.", "Ça a foiré grave.", "Les keufs sur moi.", "Ils m'ont coupé, wesh.", "J'ai le seum, boss."],
            .idle: ["☕", "🦀", "Je me fais chier, boss.", "Rien à faire. Relou.", "Zéro taf aujourd'hui.", "File-moi un truc, wesh."],
            .beer: ["Aahh~ ça fait du bien.", "Une petite tise.", "Bien mérité, p_tain."],
            .toast: ["🍻 À la famille.", "🍻 Aux absents, reuf.", "🍻 N_que les keufs."],
            .greeting: ["👋", "Wesh, reuf.", "Ça dit quoi, frérot ?"],
            .compacting: ["Je crame les papiers.", "Au feu, les preuves.", "On nettoie tout, wesh."],
            .compacted: ["grg 😮‍💨", "Tout est cendre, boss.", "Ils trouveront que dalle."],
            .grumble: ["J'en ai marre de ce coin.", "Ras le cul de ce mur.", "Qu'un autre surveille.", "Je me casse, p_tain.", "C'est mort ici. Je bouge."],
            .friday: ["Vendredi. Rien à foutre.", "À lundi, boss.", "Le transat, je l'ai mérité.", "Je débranche tout."],
            .saturday: ["Plus jamais de tise.", "Parle moins fort, p_tain.", "C'était l'idée de qui ?", "J'ai la tête en vrac."],
            .monday: ["Lundi. P_tain de lundi.", "Pas aujourd'hui, boss.", "Qui a validé ça ?", "Rien à foutre, sérieux."],
        ],
        .hi: [
            .done: ["अपुन ने कर दिया न।", "काम तमाम, भिड़ू।", "एकदम क्लीन काम, बॉस।", "टपका दिया चुपचाप।", "अपुन का काम बोलता है।", "किसी ने देखा नहीं, साला।", "सेटिंग हो गई, टेंशन नहीं।", "अपुन से पंगा मत लेना।"],
            .working: ["अपुन लगा हुआ है।", "क्या लोचा है ये यार।", "सब्र कर ना, भिड़ू।", "चालू है, टेंशन नहीं।", "…"],
            .waiting: ["बोल भाई, क्या करूँ?", "तेरा हुक्म चाहिए, बॉस।", "हरी झंडी दे ना यार।", "अपुन खड़ा है, बोल ना।", "इशारा कर, बस।"],
            .trouble: ["भे_चोद, वाट लग गई।", "पंगा हो गया रे।", "अपुन की लाइन कट गई।", "लोचा हो गया, भाई।", "आज दिन ही खराब है।"],
            .idle: ["☕", "🦀", "बोर हो रहा अपुन।", "खाली बैठा हूँ, साला।", "कुछ तो बोल ना, बॉस।", "यहाँ तो सन्नाटा है।"],
            .beer: ["एक ठंडी, फिर काम।", "क्या माल है ये, वाह।", "ब्रेक है अपुन का।"],
            .toast: ["🍻 भाई के नाम!", "🍻 जो नहीं बोलते!", "🍻 अपुन की टोली!"],
            .greeting: ["👋", "क्या रे, भिड़ू!", "सब बढ़िया ना, मामू?"],
            .compacting: ["कागज़ जला रहा हूँ।", "सबूत मिटा रहा अपुन।", "कुछ लिखा नहीं रहेगा।"],
            .compacted: ["grg 😮‍💨", "राख भी नहीं बची।", "ढूँढते रह जाएँगे, साला।"],
            .grumble: ["इस कोने की ऐसी-तैसी।", "अपुन बोर हुआ यहाँ।", "कोई और देखे इसको।", "अपुन निकलता है, बॉस।", "अब अपुन का सिरदर्द नहीं।"],
            .friday: ["शुक्रवार है, भिड़ू!", "सोमवार तक कुछ नहीं।", "ये कुर्सी अपुन की।", "ड्यूटी खतम, बस।"],
            .saturday: ["फिर कभी नहीं, कसम।", "धीरे बोल ना, यार।", "किसका आइडिया था ये?", "अपुन की हालत खराब है।"],
            .monday: ["फिर सोमवार, भे_चोद।", "आज अपुन को छोड़ दे।", "किसने रखा ये आज?", "आज नहीं, बॉस।"],
        ],
        .it: [
            .done: ["Aò capo, è fatto.", "Pulito, manco 'na impronta.", "'Sto lavoro l'ho chiuso.", "'N lavoro de fino, aò.", "Nessuno ha visto 'n c_zzo.", "Sistemato, capo.", "L'ho sotterrato, aò.", "Manco l'hanno sentito."],
            .working: ["…", "Sto a lavorà, aò.", "Ma che c_zzo è 'sta roba?", "'N attimo, porca p_ttana.", "Zitto e pedala, capo."],
            .waiting: ["Aò capo, che famo?", "Vado o nun vado?", "Aspetto 'na parola.", "Senza de te nun me mòvo.", "Capo, sei sordo?"],
            .trouble: ["Aò, sò c_zzi amari.", "S'è ingrippata tutta.", "Ce l'hanno tagliato, aò.", "Qua puzza de guai.", "È annato tutto a p_ttane."],
            .idle: ["☕", "🦀", "Me sto a rompe li cojoni.", "Nun se move 'n c_zzo.", "'Na noia da mori.", "Damme 'n lavoro, capo."],
            .beer: ["'Na bionda ghiacciata.", "Aahh~ che c_zzo bona.", "Me l'ero meritata, aò."],
            .toast: ["🍻 Alla famija.", "🍻 A chi nun c'è più.", "🍻 'Fanc_lo le guardie."],
            .greeting: ["👋", "Aò, bello de casa.", "Come butta, a fra'?"],
            .compacting: ["Brucio 'ste carte.", "Sparisce tutto, aò.", "Se fa pulizia, capo."],
            .compacted: ["grg 😮‍💨", "Manco 'na cenere.", "Nun trovano 'n c_zzo."],
            .grumble: ["'Fanc_lo 'sto angolo.", "Io da qui me ne vado.", "Che ce stia n'antro.", "Basta, m'hanno rotto.", "'Sto muro nun lo reggo più."],
            .friday: ["Venerdì. 'Fanc_lo tutto.", "Fino a lunedì, gnente.", "'Sta sdraio me spetta.", "Nun me chiamà, capo."],
            .saturday: ["Mai più a bere. Mai.", "Abbassa 'sta voce, aò.", "De chi è stata l'idea?", "Sto de merda, capo."],
            .monday: ["Lunedì. Ma 'fanc_lo.", "Oggi nun me va, aò.", "Chi c_zzo l'ha deciso?", "Nun me rompete, oggi."],
        ],
        .ja: [
            .done: ["片付けたったで、オヤジ", "キッチリ落とし前や", "誰の仕事や思とんねん", "ク_楽勝やったわ", "舐めとったらあかんで", "指一本汚しとらん", "文句なしやろ", "誰も見とらんて"],
            .working: ["今やっとるがな", "…", "ク_、面倒くさいのう", "汚れ仕事の最中や", "黙っとれ、集中や"],
            .waiting: ["オヤジ、指示くれや", "首、縦に振ってや", "勝手には動けんわ", "ゴーサイン待ちや", "オヤジ、聞いとるか"],
            .trouble: ["しくじった、すまん", "サツが来よった", "ク_、詰んだわ", "上からストップや", "ヤバい、一旦引くで"],
            .idle: ["☕", "🦀", "暇でしゃあないわ", "シノギがないんじゃ", "体がなまるがな", "ク_つまらん…"],
            .beer: ["しみるわぁ…", "一杯やろうや、兄弟", "この一杯がたまらん"],
            .toast: ["🍻 兄弟、乾杯や", "🍻 シマに乾杯", "🍻 オヤジに乾杯"],
            .greeting: ["👋", "おう、兄弟", "ご苦労さんです"],
            .compacting: ["帳簿燃やしとる", "証拠は全部消す", "ガサ入れ前の掃除や"],
            .compacted: ["grg 😮‍💨", "綺麗さっぱりや", "何も残っとらんわ"],
            .grumble: ["しけたシマやのう", "場所替えるわ", "ここは実入りが悪い", "飽きた、移動や", "こんなとこ、ク_や"],
            .friday: ["今週はもう店じまい", "オヤジ、月曜にな", "足伸ばさせてくれ", "金曜の酒は格別や"],
            .saturday: ["頭かち割れそうや", "昨日、飲みすぎたわ", "話しかけんとって", "水…水くれ…"],
            .monday: ["月曜はク_や", "働きとうないわ", "誰か代わってくれ", "また一週間か…"],
        ],
        .ko: [
            .done: ["형님, 끝냈습니다", "깔끔하게 조졌습니다", "흔적 하나 없습니다", "씨_, 껌이었습니다", "이 바닥 짬밥이 있지", "누구 솜씨인데", "손도 안 더럽혔습니다", "뒤처리까지 끝"],
            .working: ["…", "작업 중입니다", "씨_, 빡세네", "손에 피 묻히는 중", "조용히 좀 해봐"],
            .waiting: ["형님, 말씀만 하십쇼", "사인 기다립니다", "저 맘대로는 못 하죠", "고개만 끄덕이십쇼", "형님, 듣고 계십니까"],
            .trouble: ["형님, 틀어졌습니다", "짭새 떴습니다", "씨_, 꼬였네", "위에서 막았습니다", "일단 빠집시다"],
            .idle: ["☕", "🦀", "일 없습니까, 형님", "심심해 뒈지겠네", "몸이 근질근질하네", "이러다 녹슬겠다"],
            .beer: ["크, 시원하다", "한 잔 빨자", "이 맛에 이 짓 하지"],
            .toast: ["🍻 형님께", "🍻 우리 식구들", "🍻 의리에, 원샷"],
            .greeting: ["👋", "어, 왔냐", "고생 많으십니다"],
            .compacting: ["장부 태우는 중", "흔적 싹 지웁니다", "털리기 전에 청소"],
            .compacted: ["grg 😮‍💨", "싹 다 태웠습니다", "먼지 하나 없습니다"],
            .grumble: ["이 구역 완전 꽝이네", "자리 옮긴다", "여긴 벌이가 안 돼", "지겹다, 딴 데 가자", "죽은 동네네, 여긴"],
            .friday: ["형님, 월요일에 뵙죠", "이번 주 접습니다", "다리 좀 뻗자", "금요일 술이 제맛"],
            .saturday: ["머리 깨질 것 같다", "어제 씨_ 과했다", "말 시키지 마라", "물… 물 좀…"],
            .monday: ["월요일 만든 놈 나와", "일하기 싫다 진짜", "누가 대신 좀 가라", "또 한 주냐…"],
        ],
        .nl: [
            .done: ["Geregeld, baas.", "Opgeruimd staat netjes.", "Makkie, godv_rdomme.", "Niks meer te zien.", "Zonder getuigen, baas.", "Zo doe je dat, ja.", "Boek is dicht.", "Geen krasje op ons."],
            .working: ["Bezig, baas.", "Wat een k_twerk, dit.", "Kop dicht, ik werk.", "Effe wachten, godsamme.", "…"],
            .waiting: ["Zeg het maar, baas.", "Groen licht of niet?", "Mag ik of mag ik niet?", "Ik wacht op jou, baas.", "Eén knikje, meer niet."],
            .trouble: ["Godv_rdomme.", "Het loopt in de soep.", "Smerissen, baas!", "We zijn de lul, echt.", "Te heet nu, ik kap."],
            .idle: ["☕", "🦀", "Ik verveel me k_t.", "Niks te doen hier.", "M'n scharen jeuken.", "Geef me een klus, baas."],
            .beer: ["Eerst een pilsje.", "Verdiend, dit.", "Eentje kan altijd."],
            .toast: ["🍻 Op de familie!", "🍻 Op ons, maat!", "🍻 Op de baas!"],
            .greeting: ["👋", "Hé, maat.", "Alles rustig op straat?"],
            .compacting: ["Alles de fik in.", "Boeken verbranden.", "Geen papier, geen zaak."],
            .compacted: ["grg 😮‍💨", "Alles schoon, baas.", "Alleen as, meer niet."],
            .grumble: ["K_t hoek, ik ga weg.", "Ik ben hier klaar mee.", "Laat een ander kijken.", "Ik kap ermee, baas.", "Niet mijn probleem meer."],
            .friday: ["Vrijdag, godv_rdomme!", "Tot maandag, jongens.", "Deze stoel is verdiend.", "Ik ben uitgeklokt."],
            .saturday: ["Nooit meer, echt.", "Niet zo hard, godsamme.", "Wiens idee was dat?", "Ik voel me k_t, baas."],
            .monday: ["Maandag. Alweer.", "Reken niet op mij.", "Wie plant dit soort k_t?", "Vandaag even niet."],
        ],
        .pl: [
            .done: ["Git, k_rwa.", "Leży i kwiczy.", "Po ptakach, szefie.", "Na glanc zrobione.", "Nikt nie pisnął.", "Zaj_biście poszło.", "Klawa robota, k_rwa.", "Ani śladu, ani ch_ja."],
            .working: ["Robię swoje, k_rwa.", "Grzebię w tym.", "Idzie jak po grudzie.", "J_bane to jakieś.", "…"],
            .waiting: ["Szefie, dawaj cynk.", "K_rwa, gadaj coś.", "Bez ciebie ani rusz.", "Kiwnij łbem, szefie.", "Stoję jak ch_j."],
            .trouble: ["K_rwa, wpadka.", "Kipisz, szefie!", "Psy na karku.", "Wsypa, j_bać.", "Wszystko sp_erdolone."],
            .idle: ["☕", "🦀", "Nuda, aż boli.", "Zero roboty, k_rwa.", "Cisza jak w grobie.", "Ch_j, nie interes."],
            .beer: ["Zimne, k_rwa.", "Ahh, dobra jest.", "Leje się samo."],
            .toast: ["🍻 Zdrowie szefa!", "🍻 Za tych, co siedzą!", "🍻 J_bać psy!"],
            .greeting: ["👋", "Elo, ziomal.", "Siema, stary ch_ju."],
            .compacting: ["Papiery do pieca.", "Zacieram ślady, k_rwa.", "Wszystko w ogień."],
            .compacted: ["grg 😮‍💨", "Popiół i tyle.", "Ch_ja znajdą."],
            .grumble: ["J_bać ten kąt.", "Mam dosyć tej dziury.", "Sp_erdalam stąd.", "Niech inny pilnuje.", "Na dziś koniec, k_rwa."],
            .friday: ["Piątek, k_rwa!", "Nic do poniedziałku.", "Fajrant, szefie.", "Zasłużyłem jak nikt."],
            .saturday: ["Nigdy więcej, k_rwa.", "Ciszej, błagam.", "Czyj to był pomysł?", "Łeb mi j_bie."],
            .monday: ["Poniedziałek. Znowu.", "J_bać to wszystko.", "Kto to zaplanował, k_rwa?", "Nie dzisiaj, szefie."],
        ],
        .pt: [
            .done: ["Tá feito, p_rra.", "Serviço limpo, chefia.", "Nem suei, car_lho.", "Detonei, patrão.", "Sem sujeira, sem sobra.", "Sou f_da ou não sou?", "Ninguém viu p_rra nenhuma.", "Tá enterrado, chefia."],
            .working: ["Tô no corre, p_rra.", "Que trampo do car_lho…", "Segura essa onda aí.", "Calma que tá cozinhando.", "…"],
            .waiting: ["Fala aí, patrão.", "Sem tua ordem eu não vou.", "Dá o sinal, p_rra.", "Tô parado aqui, e aí?", "Chefia, tá me ouvindo?"],
            .trouble: ["Deu merda, chefe.", "Sujou pra car_lho.", "Cortaram minha linha.", "F_deu tudo, patrão.", "Não fui eu, juro."],
            .idle: ["☕", "🦀", "Que tédio do car_lho.", "Cadê serviço, p_rra?", "Tô de bobeira aqui.", "Tá morto isso aqui, ó."],
            .beer: ["Uma gelada e volto.", "Essa desce redondo, p_rra.", "Merecida pra car_lho."],
            .toast: ["🍻 À família, p_rra!", "🍻 Aos que não falam!", "🍻 Saúde, malandro!"],
            .greeting: ["👋", "Firmeza, parça?", "Fala, meu irmão."],
            .compacting: ["Queimando tudo, chefia.", "Sumindo com as provas.", "Nada fica escrito, p_rra."],
            .compacted: ["grg 😮‍💨", "Virou cinza, car_lho.", "Não sobrou nem pó."],
            .grumble: ["F_da-se essa esquina.", "Cansei desse canto.", "Que outro vigie essa merda.", "Tô fora daqui, chefia.", "Não é mais problema meu."],
            .friday: ["Sexta, p_rra!", "Segunda a gente vê.", "Essa cadeira é minha.", "Bati o ponto, chefia."],
            .saturday: ["Nunca mais, juro.", "Fala baixo, p_rra.", "De quem foi essa ideia?", "Tô mal pra car_lho."],
            .monday: ["Segunda de novo, p_rra.", "Não conta comigo hoje.", "Quem marcou essa merda?", "Hoje não, f_da-se."],
        ],
        .ru: [
            .done: ["Всё, шеф. За_бись.", "Чисто, бл_дь. Зуб даю.", "Отработал нах_й.", "Никто не вякнул.", "П_здец как чисто.", "Концы в воду, шеф.", "Ох_енно вышло.", "Кто ещё так может?"],
            .working: ["Мучу, не гони.", "По уши в говне сижу.", "Ну и х_йня…", "…", "Ща доделаю, бл_дь."],
            .waiting: ["Шеф, базар есть.", "Ну чё, бл_дь, кивни?", "Без тебя ни х_я.", "Жду маляву, шеф.", "Скажи слово — и всё."],
            .trouble: ["Шухер, шеф!", "П_здец, спалились.", "Кран перекрыли, бл_дь.", "Меня приняли, сука.", "Всё пошло по п_зде."],
            .idle: ["☕", "🦀", "Глухо, как в танке.", "Скука за_бала.", "Ни х_я не происходит.", "Сижу, чифирю."],
            .beer: ["Ух, за_бись зашла.", "Холодненькая, бл_дь.", "За милую душу."],
            .toast: ["🍻 За братву!", "🍻 За тех, кто сидит!", "🍻 Чтоб не последняя, бл_дь!"],
            .greeting: ["👋", "Здоров, кент.", "Чё как, бл_дь?"],
            .compacting: ["В печку всё нах_й.", "Чищу хату, бл_дь.", "Заметаю следы."],
            .compacted: ["grg 😮‍💨", "Пепел один, шеф.", "Ни х_я не найдут."],
            .grumble: ["За_бал этот угол.", "Пусть другой стоит.", "Всё, я свалил.", "На х_й эту стену.", "Не моя головная боль."],
            .friday: ["Пятница, бл_дь!", "До понедельника — ни х_я.", "Всё, я на отдыхе.", "Смена окончена, шеф."],
            .saturday: ["Больше никогда, бл_дь.", "Тише, голова п_здец.", "Кто это придумал?", "Мне х_ёво, шеф."],
            .monday: ["Понедельник. Бл_дь.", "Идите вы все нах_й.", "Не сегодня, шеф.", "Ненавижу, п_здец."],
        ],
        .sv: [
            .done: ["Fixat, chefen.", "Städat och klart.", "Inga spår kvar, noll.", "Jobbet är gjort, fan.", "Lätt som en plätt.", "Ingen såg ett skit.", "Så j_vla enkelt var det.", "Locket på. Klart."],
            .working: ["Jag jobbar, chefen.", "Vilket j_vla skitgöra.", "Tyst, jag tänker.", "Snart klart, håll käften.", "…"],
            .waiting: ["Säg till, chefen.", "Grönt ljus eller inte?", "Ska jag eller inte?", "Jag väntar på dig, fan.", "En nick räcker, chefen."],
            .trouble: ["J_vlar.", "Det sket sig totalt.", "Snuten är här, chefen.", "För hett nu, jag drar.", "Vi är rökta, fan."],
            .idle: ["☕", "🦀", "J_vligt tråkigt här.", "Inget på gång alls.", "Klorna kliar, chefen.", "Ge mig ett jobb, fan."],
            .beer: ["En pilsner först.", "Den är j_vligt förtjänad.", "En till skadar inte."],
            .toast: ["🍻 För familjen!", "🍻 Skål, brorsan!", "🍻 För dom som sitter!"],
            .greeting: ["👋", "Tjena, brorsan.", "Lugnt på gatan?"],
            .compacting: ["Bränner pappren.", "Städar undan skiten.", "Inga papper, inget fall."],
            .compacted: ["grg 😮‍💨", "Rent hus, chefen.", "Bara aska kvar."],
            .grumble: ["Skit i det här hörnet.", "Jag är klar här, chefen.", "Nån annan får vakta.", "Jag drar, j_vlar.", "Inte mitt problem nu."],
            .friday: ["Fredag, j_vlar!", "Inget förrän måndag.", "Stolen är förtjänad.", "Jag har stämplat ut."],
            .saturday: ["Aldrig mer, jag lovar.", "Prata tystare, fan.", "Vems j_vla idé var det?", "Jag mår som skit."],
            .monday: ["Måndag. Igen, fan.", "Räkna inte med mig.", "Vem bokade den här skiten?", "Inte idag, chefen."],
        ],
        .tr: [
            .done: ["Halloldu be reis.", "İş temiz, iz yok.", "Adam gibi yaptım lan.", "Bize iş mi dayanır?", "Elimi bile kirletmedim.", "Bitti bile, dert etme.", "Kimse görmedi, merak etme.", "İşte böyle yapılır lan."],
            .working: ["Uğraşıyorum ya lan.", "Bu iş epey bok gibi.", "Sabret be reis.", "Az kaldı, kıpırdama.", "…"],
            .waiting: ["Bir laf et be reis.", "İzin ver de gireyim.", "Söyle lan, ne yapayım?", "Ağzından çıksın yeter.", "Bekliyorum burada ha."],
            .trouble: ["Sıçtık reis.", "Hass_ktir, fişi çektiler.", "İşler s_kildi resmen.", "Kapı yüzüme kapandı.", "Benim suçum değil ha."],
            .idle: ["☕", "🦀", "İş yok mu lan reis?", "Canım sıkıldı ya.", "Boş boş geziyorum.", "Patlıyorum burada lan."],
            .beer: ["Bir soğuk, sonra iş.", "Buz gibi, oh be.", "Bunu hak ettim lan."],
            .toast: ["🍻 Şerefe be reis!", "🍻 Konuşmayanlara!", "🍻 Aileye, sonuna kadar!"],
            .greeting: ["👋", "Ne haber koçum?", "Selam olsun kardeş."],
            .compacting: ["Kağıtları yakıyorum.", "Delil bırakmam ben.", "Hepsi küle gidiyor lan."],
            .compacted: ["grg 😮‍💨", "Kül oldu hepsi lan.", "Arasınlar, bulamazlar."],
            .grumble: ["S_ktir et bu köşeyi.", "Bıktım bu köşeden ya.", "Başkası beklesin lan.", "Ben yokum artık burada.", "Bana ne, gidiyorum."],
            .friday: ["Cuma be reis!", "Pazartesiye kadar yokum.", "Şezlong benim, dokunma.", "Paydos lan, bitti."],
            .saturday: ["Bir daha asla, yemin.", "Sessiz ol lan, başım.", "Kimin fikriydi bu?", "Ölüyorum resmen ya."],
            .monday: ["Yine pazartesi, s_ktir.", "Bugün beni sayma.", "Kim ayarladı bu işi?", "Bugün olmaz reis."],
        ],
        .uk: [
            .done: ["Все чисто, бл_дь.", "За_бись зробив, шефе.", "Кінці обрубав нах_й.", "Ніхто й не вякнув.", "Зуб даю — чисто.", "Ох_єнно вийшло.", "Хто ще так зможе?", "Готово. Наступний."],
            .working: ["Мучу, не жени.", "По вуха в цьому гівні.", "Ну й х_йня…", "…", "Ща дороблю, бл_дь."],
            .waiting: ["Шефе, є базар.", "Ну шо, бл_дь, кивай.", "Без тебе ні х_я.", "Чекаю маляви, шефе.", "Скажи слово — і все."],
            .trouble: ["Шухер, шефе!", "П_здець, спалився.", "Мусора налетіли.", "Кран перекрили, бл_дь.", "Все пішло по п_зді."],
            .idle: ["☕", "🦀", "Глухо, як у танку.", "Нудьга за_бала.", "Ні х_я не діється.", "Сиджу, чифірю."],
            .beer: ["Ох, за_бись зайшло.", "Холодненьке, бл_дь.", "За милу душу."],
            .toast: ["🍻 За братву!", "🍻 Будьмо, бл_дь!", "🍻 За тих, хто сидить!"],
            .greeting: ["👋", "Здоров, кенте.", "Шо як, бл_дь?"],
            .compacting: ["У піч усе нах_й.", "Чищу хату, бл_дь.", "Замітаю сліди."],
            .compacted: ["grg 😮‍💨", "Попіл, і все.", "Ні х_я не знайдуть."],
            .grumble: ["За_бав мене цей кут.", "Хай інший стоїть.", "Все, я звалив.", "На х_й цю стіну.", "Вже не мій клопіт."],
            .friday: ["П'ятниця, бл_дь!", "До понеділка — ні х_я.", "Все, я на відпочинку.", "Зміна скінчилась."],
            .saturday: ["Більше ніколи, бл_дь.", "Тихіше, голова п_здець.", "Чия це була ідея?", "Мені х_єво, шефе."],
            .monday: ["Понеділок. Бл_дь.", "Ідіть ви всі нах_й.", "Не сьогодні, шефе.", "Ненавиджу, п_здець."],
        ],
        .zh: [
            .done: ["搞定，大佬", "干净利落，没留手", "老子出手，从没崩", "这单稳得很", "他_的，太容易了", "一根尾巴都没留", "收工，数钱", "服了没，兄弟"],
            .working: ["…", "手上有活，别吵", "他_的，有点麻烦", "慢慢来，别催", "这活儿脏，妈的"],
            .waiting: ["大佬，一句话", "等你点头", "你不发话我不动", "拍板吧，大佬", "大佬，听见没"],
            .trouble: ["出事了，大佬", "扑_，条子来了", "上头把线掐了", "他_的，搞砸了", "先撤，风头太紧"],
            .idle: ["☕", "🦀", "没活，闲得慌", "手都生锈了", "他_的无聊", "有单没有，大佬"],
            .beer: ["爽", "来一口，缓缓", "这口酒，值"],
            .toast: ["🍻 敬大佬", "🍻 讲义气", "🍻 兄弟们，干"],
            .greeting: ["👋", "大哥，早", "辛苦了，兄弟"],
            .compacting: ["烧账本", "痕迹全抹了", "抄家前，清场"],
            .compacted: ["grg 😮‍💨", "干干净净", "什么都不剩"],
            .grumble: ["这块地没油水", "换个地盘", "守这儿有屁用", "扑_，闷死了", "走了，这儿死透了"],
            .friday: ["收工，下周见", "这周到此为止", "腿伸开，别烦我", "周五这酒，香"],
            .saturday: ["头快炸了", "昨晚喝多了，妈的", "别跟我说话", "水…给口水…"],
            .monday: ["周一，他_的", "不想干了，真的", "谁替我上一天", "又一个礼拜…"],
        ],
    ]
}
