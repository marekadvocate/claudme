import Foundation

/// What a crab can say. Every line is in the voice of a made man reporting to his
/// boss — you. These are not translations of the English: each language was written
/// in its own crime-fiction register, so the jokes land for a native speaker.
///
/// To add a language: add a case to `Lang` and an entry to `table`. Nothing else.
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
    case en, sk, cs, de, es, fr, hi, it, ja, ko, nl, pl, pt, ru, sv, tr, uk, zh

    var displayName: String {
        switch self {
        case .en: return "English"
        case .sk: return "Slovenčina"
        case .cs: return "Čeština"
        case .de: return "Deutsch"
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
        .es: [
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
}
