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

    /// Clean unless you go looking for the other one — the crabs sit on top of whatever
    /// you happen to be screen-sharing.
    static var register: Register = {
        guard let saved = UserDefaults.standard.string(forKey: registerKey) else { return .clean }
        return Register(rawValue: saved) ?? .clean
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
            .done: ["Done and dusted, boss.", "Sorted. Piece of piss.", "Buried it proper.", "Whacked it. Next one.", "Not a scratch on us.", "Easy money, guv.", "Job's a good 'un.", "Nobody saw a thing."],
            .working: ["Grafting, boss.", "Elbows deep in it.", "Sod this bit…", "Nearly there, hold up.", "…"],
            .waiting: ["Oi, boss. A word.", "Waiting on you, guv.", "Give us the nod.", "I ain't moving. Say it.", "Boss? You deaf?"],
            .trouble: ["We're in the shit.", "Old Bill's on me.", "Got pinched, boss.", "It's gone tits up.", "They cut me off cold."],
            .idle: ["Bugger all doing.", "Dead as a doornail.", "Bored out me nut.", "☕", "Business is bollocks.", "🦀"],
            .beer: ["Ahh~ that's the stuff.", "Down the hatch.", "Cheers, ya animals."],
            .toast: ["🍻 To the firm.", "🍻 Up yours, coppers.", "🍻 Chin chin, son."],
            .greeting: ["👋", "Oi oi, saveloy.", "Alright, geezer?"],
            .compacting: ["Torching the books…", "Shredding the lot…", "Bin bags out, boss…"],
            .compacted: ["Books are ash, boss.", "grg 😮‍💨", "Sod all left to find."],
        ],
        .sk: [
            .done: ["Hotovo, šéfko.", "Vybavené načisto.", "Zakopané, ide sa ďalej.", "Ani ťuk, nikto nič.", "Ľahké prachy, šéfe.", "Hračka, šéfko.", "Čistá fuška.", "Po nás ani smrad."],
            .working: ["Fachčím, šéfe.", "Som v tom po lakte.", "Do riti s tým…", "Ešte chvíľu, vydrž.", "…"],
            .waiting: ["Šéfko? Na slovo.", "Čakám na teba, no.", "Kývni a idem.", "Bez teba sa nehnem.", "Šéfe, si hluchý?"],
            .trouble: ["Sme v riti, šéfe.", "Poliši ma zbalili.", "Zavreli mi kohútik.", "Posralo sa to.", "Zlá noc, šéfko."],
            .idle: ["Ani pes neštekne.", "Kšefty za hovno.", "Mŕtvo ako v krypte.", "☕", "Nudím sa na smrť.", "🦀"],
            .beer: ["Ahh~ to pohladí.", "Do dna, chlapci.", "Toto som potreboval."],
            .toast: ["🍻 Na rodinu, chlapi.", "🍻 Do dna!", "🍻 Nech nás nechytia."],
            .greeting: ["👋", "Čau, kámo.", "Zdar, ty gauner."],
            .compacting: ["Pálim účtovníctvo…", "Skartujem ten bordel…", "Upratujem po sebe…"],
            .compacted: ["Knihy sú popol.", "grg 😮‍💨", "Nenájdu ani hovno."],
        ],
        .cs: [
            .done: ["Hotovo, šéfe.", "Vyřízeno načisto.", "Zakopáno, jede se dál.", "Ani ťuk, nikdo nic.", "Lehký prachy, šéfe.", "Hračka, šéfiku.", "Čistá práce.", "Po nás ani smrad."],
            .working: ["Makám, šéfe.", "Jsem v tom po lokty.", "Do prdele s tím…", "Ještě chvilku, vydrž.", "…"],
            .waiting: ["Šéfe? Na slovíčko.", "Čekám na tebe, no.", "Kejvni a jedu.", "Bez tebe se nehnu.", "Šéfe, seš hluchej?"],
            .trouble: ["Jsme v hajzlu, šéfe.", "Sebrali mě chlupatý.", "Zavřeli mi kohoutek.", "Posralo se to.", "Blbá noc, šéfe."],
            .idle: ["Ani pes neštěkne.", "Kšefty za hovno.", "Mrtvo jak v kryptě.", "☕", "Nudím se k smrti.", "🦀"],
            .beer: ["Ahh~ to pohladí.", "Do dna, chlapi.", "Tohle sem potřeboval."],
            .toast: ["🍻 Na rodinu, chlapi.", "🍻 Do dna!", "🍻 Ať nás nechytnou."],
            .greeting: ["👋", "Čau, kámo.", "Zdar, ty grázle."],
            .compacting: ["Pálím účetnictví…", "Skartuju ten bordel…", "Uklízím po sobě…"],
            .compacted: ["Knihy jsou popel.", "grg 😮‍💨", "Nenajdou ani hovno."],
        ],
        .de: [
            .done: ["Erledigt, Chef.", "Sauber weggeräumt.", "Kiste ist zu.", "War 'n Klacks.", "Nix mehr zu sehen.", "Sache ist geregelt.", "Keiner hat was gesehen.", "So macht man das."],
            .working: ["Bin dran, Chef.", "Gleich haben wir's.", "Ruhe jetzt, ich denk.", "Schmutzige Arbeit…", "…"],
            .waiting: ["Sag ein Wort, Chef.", "Grünes Licht?", "Soll ich?", "Ich warte auf dich.", "Nick einmal, Chef."],
            .trouble: ["Wir sind aufgeflogen.", "Scheiße, Chef.", "Die Bullen sind da.", "Läuft schief.", "Zu heiß gerade."],
            .idle: ["☕", "🦀", "Langweilig hier.", "Nix los, Chef.", "Mir juckt die Schere.", "Gib mir was zu tun."],
            .beer: ["Erstmal 'n Bier.", "Hab ich mir verdient.", "Ein Kurzer geht noch."],
            .toast: ["🍻 Auf die Familie!", "🍻 Auf uns, Brüder!", "🍻 Auf den Chef!"],
            .greeting: ["👋", "Ey, Bruder.", "Alles ruhig?"],
            .compacting: ["Akten brennen.", "Alles verschwindet.", "Kein Papier, kein Fall."],
            .compacted: ["grg 😮‍💨", "Alles sauber.", "Asche, mehr nicht."],
        ],
        .el: [
            .done: ["Καθαρή δουλειά.", "Τσακ μπαμ, αφεντικό.", "Ούτε γάτα ούτε ζημιά.", "Τα 'σπασα, γαμώτο.", "Ξηγήθηκα βασιλικά.", "Μαγκιά μου, ε;", "Δεν άφησα ίχνος.", "Άλλο τίποτα;"],
            .working: ["…", "Δούλευε, μη μιλάς.", "Το 'χω, ησύχασε.", "Μη με ζορίζεις τώρα.", "Λύνω το κουβάρι."],
            .waiting: ["Λέγε, αφεντικό.", "Μπαίνω ή όχι;", "Περιμένω σήμα.", "Πες μου ένα ναι.", "Την ευχή σου;"],
            .trouble: ["Έφαγα πόρτα.", "Γαμώτο, κόλλησα.", "Μας κόψαν τη φόρα.", "Στραβό το κλίμα.", "Ζόρια, αφεντικό."],
            .idle: ["☕", "🦀", "Ψόφια πράματα.", "Σκουριάζω, γαμώτο.", "Κάνα κελεπούρι;", "Τίποτα δεν παίζει."],
            .beer: ["Μια γουλιά μόνο.", "Κρύα σαν πάγος.", "Έχει ανάγκες κι ο μάγκας."],
            .toast: ["🍻 Άσπρο πάτο!", "🍻 Γεια μας, μάγκα!", "🍻 Για το αφεντικό!"],
            .greeting: ["👋", "Έλα, μάγκα μου.", "Τι λέει, κουμπάρε;"],
            .compacting: ["Καίω τα χαρτιά.", "Καθαρίζω το σπίτι.", "Στάχτη και μπούρμπερη."],
            .compacted: ["grg 😮‍💨", "Καθαρά τα χαρτιά.", "Ούτε στάχτη έμεινε."],
        ],
        .es: [
            .done: ["Hecho, jefe.", "Ni una huella.", "De puta madre.", "Limpio y sin ruido.", "Trabajito fino, ¿eh?", "Nadie vio una mierda.", "Asunto zanjado.", "Ya está enterrado."],
            .working: ["…", "Estoy en ello, coño.", "Callado y currando.", "Joder, vaya lío.", "Dame un minuto."],
            .waiting: ["Jefe, dime algo.", "¿Le doy o no?", "Espero tu palabra.", "Tú mandas, jefe.", "¿Entro o qué?"],
            .trouble: ["Nos han pillado.", "Hostia. Problema.", "Se ha jodido, jefe.", "Cortaron el grifo.", "Esto huele a madero."],
            .idle: ["☕", "🦀", "Tocándome los huevos.", "Ni un trabajo hoy.", "Esto está muerto.", "Me aburro, jefe."],
            .beer: ["Salud, jefe.", "Una fresquita.", "Me la he ganado."],
            .toast: ["🍻 Por la familia.", "🍻 Salud y dinero.", "🍻 A los que faltan."],
            .greeting: ["👋", "¿Qué pasa, primo?", "Buenas, colega."],
            .compacting: ["Quemando papeles.", "Fuera las pruebas.", "Limpiando la casa."],
            .compacted: ["grg 😮‍💨", "Cenizas, jefe.", "Ni un papel queda."],
        ],
        .fr: [
            .done: ["C'est plié, boss.", "Chanmé, non ?", "Zéro trace, wesh.", "Le taf est fait.", "Vu par personne.", "Propre de ouf.", "Emballé, c'est réglé.", "J'ai géré, tranquille."],
            .working: ["…", "Je gère, laisse-moi.", "Ça bosse, wesh.", "Deux secondes, reuf.", "Putain, ce bordel."],
            .waiting: ["Boss, tu dis quoi ?", "J'y vais ou pas ?", "J'attends ton feu vert.", "C'est toi qui vois.", "Donne le go, boss."],
            .trouble: ["On est grillés.", "Ça a foiré, putain.", "Y a embrouille.", "Le robinet est coupé.", "Chelou, ce truc."],
            .idle: ["☕", "🦀", "Rien à faire, relou.", "Je me fais chier.", "Ça bouge pas, wesh.", "File-moi un taf."],
            .beer: ["Une petite mousse.", "Santé, boss.", "Bien mérité, ça."],
            .toast: ["🍻 À la famille.", "🍻 Aux absents.", "🍻 Santé, reuf."],
            .greeting: ["👋", "Wesh, reuf.", "Ça va ou quoi ?"],
            .compacting: ["Je brûle les papiers.", "Au feu, les preuves.", "On nettoie tout."],
            .compacted: ["grg 😮‍💨", "Tout est cendre.", "Table rase, boss."],
        ],
        .hi: [
            .done: ["अपुन ने कर दिया।", "काम तमाम, भिड़ू।", "एकदम क्लीन काम।", "अपुन का काम बोलता है।", "सेटिंग हो गया न।", "झंझट खतम, बॉस।", "उंगली तक नहीं लगी।", "टपका दिया चुपचाप।"],
            .working: ["अपुन लगा हुआ है।", "थोड़ा लोचा है, रुक।", "सब्र कर ना यार।", "चालू है, टेंशन नहीं।", "…"],
            .waiting: ["बोल भाई, क्या करूँ?", "तेरा हुक्म चाहिए।", "हरी झंडी दे ना।", "अपुन खड़ा है यहीं।", "इशारा कर, बस।"],
            .trouble: ["लोचा हो गया, भाई।", "पंगा हो गया रे।", "अपुन की लाइन कटी।", "गड़बड़, मेरा दोष नहीं।", "आज दिन खराब है।"],
            .idle: ["☕", "🦀", "काम दे ना, भाई।", "बोर हो रहा अपुन।", "खाली बैठा हूँ यार।", "कुछ तो बोल ना।"],
            .beer: ["एक ठंडी, फिर काम।", "क्या माल है ये।", "ब्रेक है अपुन का।"],
            .toast: ["🍻 भाई के नाम!", "🍻 जो नहीं बोलते!", "🍻 अपुन की टोली!"],
            .greeting: ["👋", "क्या रे, भिड़ू!", "सब बढ़िया ना?"],
            .compacting: ["कागज़ जला रहा हूँ।", "सबूत मिटा रहा अपुन।", "कुछ लिखा नहीं रहेगा।"],
            .compacted: ["grg 😮‍💨", "राख भी नहीं बची।", "ढूँढते रह जाएँगे।"],
        ],
        .it: [
            .done: ["Aò capo, è fatto.", "Pulito, nun se vede.", "'Sto lavoro è chiuso.", "Daje, è annata bene.", "Nessuno ha visto gnente.", "'N lavoro de fino.", "Sistemato, capo.", "Manco 'na impronta."],
            .working: ["…", "Sto a lavorà, aò.", "'N attimo, capo.", "Ma che è 'sta roba?", "Zitto e pedala."],
            .waiting: ["Aò, che famo?", "Capo, dimme te.", "Aspetto 'na parola.", "Vado o nun vado?", "Comanni tu, capo."],
            .trouble: ["Aò, sò cazzi.", "S'è ingrippata, capo.", "Ce l'hanno tagliato.", "Qua puzza de guai.", "È annato tutto storto."],
            .idle: ["☕", "🦀", "Me sto a rompe li cojoni.", "Nun se move gnente.", "'Na noia mortale.", "Damme 'n lavoro, capo."],
            .beer: ["'Na bionda ghiacciata.", "Salute, capo.", "Me l'ero meritata."],
            .toast: ["🍻 Alla famija.", "🍻 A chi nun c'è più.", "🍻 Daje, salute!"],
            .greeting: ["👋", "Aò, bello de casa.", "Come butta?"],
            .compacting: ["Brucio le carte.", "Se fa pulizia.", "Sparisce tutto."],
            .compacted: ["grg 😮‍💨", "Manco 'na cenere.", "Tutto pulito, capo."],
        ],
        .ja: [
            .done: ["片付けたで、オヤジ", "ケジメはつけた", "キッチリ落とし前", "血ィ見んで済んだ", "誰の仕事や思とる", "ナメたらあかんで", "おう、終わったで", "文句ないやろ"],
            .working: ["今やっとるがな", "汚れ仕事の最中や", "黙って見とけ", "…", "くそ、面倒やのう"],
            .waiting: ["オヤジ、指示を", "ゴーサイン待ちや", "勝手には動けん", "オヤジ、どうします", "首、縦に振ってや"],
            .trouble: ["しくじった、すまん", "上からストップや", "サツが来よった", "一旦引くで", "くそったれ、詰んだ"],
            .idle: ["☕", "🦀", "暇やのう…", "シノギがないわ", "体がなまるで", "仕事回してや"],
            .beer: ["しみるわぁ", "一杯やろうや", "勝ちの一杯や"],
            .toast: ["🍻 兄弟、乾杯", "🍻 シマに乾杯", "🍻 オヤジに乾杯"],
            .greeting: ["👋", "おう、兄弟", "ご苦労さんです"],
            .compacting: ["帳簿燃やしとる", "証拠は消しとけ", "ガサ入れ前の掃除"],
            .compacted: ["grg 😮‍💨", "綺麗さっぱりや", "何も残っとらん"],
        ],
        .ko: [
            .done: ["깔끔하게 정리했습니다", "손 좀 봐줬습니다", "형님, 끝냈습니다", "뒤처리까지 완료", "흔적 하나 없습니다", "조졌습니다", "이 바닥 짬밥이 있지", "누구 솜씨인데"],
            .working: ["작업 중입니다", "손에 피 묻히는 중", "…", "아, 지저분하네", "제길, 빡세네"],
            .waiting: ["형님, 말씀만 하십쇼", "사인 기다립니다", "저 맘대로는 못 하죠", "고개만 끄덕이십쇼", "답 좀 주십쇼"],
            .trouble: ["형님, 일이 틀어졌습니다", "위에서 막았습니다", "짭새 떴다", "제길, 꼬였네", "일단 빠집시다"],
            .idle: ["☕", "🦀", "일 없습니까", "심심해 죽겠네", "몸이 근질근질", "이러다 녹슬겠네"],
            .beer: ["크, 시원하다", "한 잔 빨자", "이 맛에 일하지"],
            .toast: ["🍻 형님께", "🍻 우리 식구들", "🍻 의리에"],
            .greeting: ["👋", "어, 왔냐", "고생하십니다"],
            .compacting: ["장부 태우는 중", "흔적 지웁니다", "털리기 전에 청소"],
            .compacted: ["grg 😮‍💨", "싹 다 태웠습니다", "깨끗합니다, 형님"],
        ],
        .nl: [
            .done: ["Geregeld, baas.", "Opgeruimd staat netjes.", "Fluitje van een cent.", "Niks meer te zien.", "Klusje geklaard.", "Zonder getuigen.", "Zo doe je dat.", "Boek is dicht."],
            .working: ["Bezig, baas.", "Effe wachten.", "Vies werk, dit.", "Kop dicht, ik werk.", "…"],
            .waiting: ["Zeg het maar, baas.", "Groen licht?", "Mag ik?", "Ik wacht op jou.", "Eén knikje, baas."],
            .trouble: ["Godverdomme.", "Het loopt fout.", "Smerissen, baas!", "Te heet nu.", "We zijn de lul."],
            .idle: ["☕", "🦀", "Verveling, baas.", "Niks te doen hier.", "M'n scharen jeuken.", "Geef me een klus."],
            .beer: ["Eerst een pilsje.", "Verdiend, dit.", "Eentje kan altijd."],
            .toast: ["🍻 Op de familie!", "🍻 Op ons, maat!", "🍻 Op de baas!"],
            .greeting: ["👋", "Hé, maat.", "Alles rustig?"],
            .compacting: ["Alles de fik in.", "Boeken verbranden.", "Geen papier, geen zaak."],
            .compacted: ["grg 😮‍💨", "Alles schoon.", "Alleen as, baas."],
        ],
        .pl: [
            .done: ["Git, szefie.", "Leży i kwiczy.", "Po ptakach.", "Na glanc zrobione.", "Nikt nie pisnął.", "Klawo poszło.", "Cicho i czysto.", "Robota jak złoto."],
            .working: ["Robię swoje.", "Grzebię w tym.", "Idzie jak po grudzie.", "…", "Momencik, szefie."],
            .waiting: ["Szefie, dawaj cynk.", "Kiwnij łbem.", "Bez ciebie ani rusz.", "Gadaj, co robimy.", "Stoję i czekam."],
            .trouble: ["Kurwa, wpadka.", "Kipisz, szefie!", "Psy na karku.", "Wsypa, szefie.", "Wszystko w plecy."],
            .idle: ["☕", "🦀", "Nuda, aż boli.", "Zero roboty.", "Odbijam się od ścian.", "Ani grosza dziś."],
            .beer: ["Zimne, git.", "Ahh, dobra jest.", "Leje się samo."],
            .toast: ["🍻 Zdrowie szefa!", "🍻 Za tych, co siedzą!", "🍻 Nie ma mocnych!"],
            .greeting: ["👋", "Elo, ziomek.", "Co tam, brachu?"],
            .compacting: ["Papiery do pieca.", "Zacieram ślady.", "Wszystko w ogień."],
            .compacted: ["grg 😮‍💨", "Popiół i tyle.", "Nic na mnie nie mają."],
        ],
        .pt: [
            .done: ["Tá feito, porra.", "Serviço limpo, chefia.", "Nem suei, patrão.", "Missão dada é cumprida.", "Deixei no capricho.", "Desenrolei tudo, ó.", "Sem sobra, sem sujeira.", "Sou foda ou não sou?"],
            .working: ["Tô no corre, calma.", "Puta trampo isso aqui.", "Segura a onda aí.", "Tá cozinhando, chefia.", "…"],
            .waiting: ["Fala aí, patrão.", "Preciso do teu aval.", "Dá o sinal, chefia.", "Sem ordem eu não movo.", "Tô parado, e aí?"],
            .trouble: ["Deu merda, chefe.", "Sujou feio aqui.", "Cortaram minha linha.", "Levei um perdido.", "Não fui eu, juro."],
            .idle: ["☕", "🦀", "Cadê o serviço, chefia?", "Que tédio da porra.", "Tô de bobeira aqui.", "Manda alguma coisa, ó."],
            .beer: ["Uma gelada e volto.", "Essa desce redondo.", "Merecida, viu."],
            .toast: ["🍻 À família, porra!", "🍻 Aos que não falam!", "🍻 Saúde, malandro!"],
            .greeting: ["👋", "Firmeza, parça?", "Fala, meu irmão."],
            .compacting: ["Queimando tudo, chefia.", "Sumindo com as provas.", "Nada fica escrito."],
            .compacted: ["grg 😮‍💨", "Virou cinza tudo.", "Não sobrou nem pó."],
        ],
        .ru: [
            .done: ["Всё ровно, шеф.", "По понятиям сделал.", "Зуб даю — чисто.", "Ништяк отработал.", "Никто не вякнул.", "Чётко, как в аптеке.", "Концы обрубил.", "Отвечаю, шеф."],
            .working: ["Мучу тему.", "Не гони, работаю.", "Есть движуха.", "…", "Копаюсь помаленьку."],
            .waiting: ["Шеф, базар есть.", "Ну чё, шеф?", "Кивни — и сделаю.", "Без тебя ни шагу.", "Жду малявы."],
            .trouble: ["Шухер, шеф!", "Бля, спалились.", "Палево.", "Косяк вышел.", "Меня закрыли."],
            .idle: ["☕", "🦀", "Глухо, как в танке.", "Ни движухи.", "Сижу, чифирю.", "Скука, хоть вой."],
            .beer: ["Ух, зашла.", "За милую душу.", "Холодненькая."],
            .toast: ["🍻 За братву!", "🍻 За тех, кто сидит!", "🍻 Чтоб не последняя!"],
            .greeting: ["👋", "Здоров, кент.", "Чё как, братан?"],
            .compacting: ["В печку всё.", "Чищу хату.", "Заметаю следы."],
            .compacted: ["grg 😮‍💨", "Пепел один.", "Взять нечего."],
        ],
        .sv: [
            .done: ["Fixat, chefen.", "Städat och klart.", "Inga spår kvar.", "Jobbet är gjort.", "Lätt som en plätt.", "Ingen såg ett skit.", "Så gör man det.", "Locket på."],
            .working: ["Jag jobbar, chefen.", "Snart klart.", "Skitgöra, det här.", "Tyst, jag tänker.", "…"],
            .waiting: ["Säg till, chefen.", "Grönt ljus?", "Ska jag?", "Jag väntar på dig.", "En nick räcker."],
            .trouble: ["Jävlar.", "Det sket sig.", "Snuten är här.", "För hett just nu.", "Vi är rökta."],
            .idle: ["☕", "🦀", "Tråkigt värre.", "Inget på gång.", "Klorna kliar.", "Ge mig ett jobb."],
            .beer: ["En pilsner först.", "Den är förtjänad.", "En till skadar inte."],
            .toast: ["🍻 För familjen!", "🍻 Skål, brorsan!", "🍻 För chefen!"],
            .greeting: ["👋", "Tjena, brorsan.", "Lugnt på gatan?"],
            .compacting: ["Bränner pappren.", "Städar undan skiten.", "Inga papper, inget fall."],
            .compacted: ["grg 😮‍💨", "Rent hus.", "Bara aska kvar."],
        ],
        .tr: [
            .done: ["Halloldu be reis.", "İş temiz, iz yok.", "Adam gibi yaptım.", "Bize iş mi dayanır?", "Elimi bile kirletmedim.", "Bitti bile, patron.", "Dert etme, hallettim.", "Böyle iş görülür işte."],
            .working: ["Uğraşıyorum ya.", "Sabret be reis.", "Bu iş biraz pis.", "Az kaldı, kıpırdama.", "…"],
            .waiting: ["Bir laf et reis.", "İzin ver, gireyim.", "Söyle, ne yapayım?", "Ağzından çıksın yeter.", "Bekliyorum burada."],
            .trouble: ["Sıçtık reis.", "Fişi çektiler valla.", "İşler karıştı biraz.", "Kapı yüzüme kapandı.", "Benim suçum değil ha."],
            .idle: ["☕", "🦀", "İş yok mu reis?", "Canım sıkıldı ya.", "Boş boş geziyorum.", "Ver bir iş, patlıyorum."],
            .beer: ["Bir soğuk, sonra iş.", "Buz gibi, oh be.", "Bunu hak ettim reis."],
            .toast: ["🍻 Şerefe be reis!", "🍻 Konuşmayanlara!", "🍻 Aileye, sonuna kadar!"],
            .greeting: ["👋", "Ne haber koçum?", "Selam olsun kardeş."],
            .compacting: ["Kağıtları yakıyorum.", "Delil bırakmam ben.", "Küllüğe gidiyor hepsi."],
            .compacted: ["grg 😮‍💨", "Kül oldu hepsi.", "Arasınlar, bulamazlar."],
        ],
        .uk: [
            .done: ["Чітко, шефе.", "Зуб даю — чисто.", "По понятіях, шефе.", "Ніхто не вякнув.", "Кінці обрубав.", "Нема базару.", "Зроблено на ять.", "Гладко пройшло."],
            .working: ["Мучу тему.", "Не жени, роблю.", "Є движ.", "…", "Колупаюсь потроху."],
            .waiting: ["Шефе, є базар.", "Ну шо, шефе?", "Без тебе ні кроку.", "Чекаю маляви.", "Дай знак, шефе."],
            .trouble: ["Кіпіш, шефе!", "Бляха, спалився.", "Засвітився.", "Косяк вийшов.", "Мене закрили."],
            .idle: ["☕", "🦀", "Глухо, як у танку.", "Нема движу.", "Сиджу, чифірю.", "Нудьга, хоч вий."],
            .beer: ["Ух, зайшла.", "Холодненьке.", "За милу душу."],
            .toast: ["🍻 За братву!", "🍻 За тих, хто сидить!", "🍻 Щоб не остання!"],
            .greeting: ["👋", "Здоров, кенте.", "Шо як, братан?"],
            .compacting: ["У піч усе.", "Чищу хату.", "Замітаю сліди."],
            .compacted: ["grg 😮‍💨", "Попіл, і все.", "Брати нема чого."],
        ],
        .zh: [
            .done: ["搞定，大佬", "摆平了", "干净利落，没留手", "一点尾巴都不留", "老子出手，从没崩", "这单，稳得很", "服了吧，兄弟", "收工，数钱"],
            .working: ["手上有活", "别吵，正忙", "…", "妈的，有点麻烦", "慢慢来，别急"],
            .waiting: ["大佬，一句话", "等你点头", "不发话，我不动", "拍板吧，大佬", "等回话呢"],
            .trouble: ["出事了，大佬", "上头卡住了", "条子来了", "妈的，搞砸了", "先撤，回头再来"],
            .idle: ["☕", "🦀", "没活干，闲得慌", "手都生锈了", "有单没有", "无聊死了"],
            .beer: ["爽", "来一口", "这口酒，值"],
            .toast: ["🍻 敬大佬", "🍻 讲义气", "🍻 兄弟们"],
            .greeting: ["👋", "大哥，早", "辛苦了，兄弟"],
            .compacting: ["烧账本", "抹干净痕迹", "抄家前，清场"],
            .compacted: ["grg 😮‍💨", "干干净净", "什么都没了"],
        ],
    ]
}
