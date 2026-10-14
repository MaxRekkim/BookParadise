import Foundation

public struct SampleData {
    public static let sampleEditions: [String] = [
        "Эксмо", "Магистраль", "Эксклюзивная классика", "INSPIRIA", "МИФ",
        "АСТ", "Азбука-Классика", "Большие книги", "Pocket book", "Фолио",
        "Corpus", "Синдбад", "Альпина Паблишер", "Popcorn Books", "NoSugar Books",
        "Like Book", "Freedom", "Аркадия", "Иностранка", "Phantom Press",
        "Clever", "Самокат", "Поляндрия", "Ad Marginem", "Livebook"
    ]
    
    public static let sampleAuthors: [String] = [
        "Агата Кристи", "Эрих Мария Ремарк", "Майк Омер", "Нора Сакавич", "Рина Кент",
        "Джон Стрелеки", "Александр Дюма", "Стивен Кинг", "Федор Достоевский", "Лев Толстой",
        "Михаил Булгаков", "Джордж Оруэлл", "Франц Кафка", "Харуки Мураками", "Фредрик Бакман",
        "Донна Тартт", "Ханья Янагихара", "Ю Несбё", "Роберт Гэлбрейт", "Гиллиан Флинн",
        "Люси Фоли", "Алекс Михаэлидес", "Селеста Инг", "Кристин Ханна", "Бернар Вербер",
        "Артур Конан Дойл", "Оскар Уайльд", "Джейн Остин", "Шарлотта Бронте", "Эмили Бронте",
        "Виктор Гюго", "Габриэль Гарсиа Маркес", "Рэй Брэдбери", "Олдос Хаксли", "Станислав Лем"
    ]

    public static func generateInitialBooks() -> [Book] {
        var list: [Book] = []
        
        // 1. Читаемые прямо сейчас книги (из ТЗ: 3 книги)
        let inProgress1 = Book(
            id: 1,
            title: "Дурное поведение",
            author: "Зои Бентли",
            edition: "INSPIRIA",
            isbn: "978-5-04-117823-9",
            cycleNumber: "2",
            genre: .psychologicalThriller,
            pagesRead: 210,
            totalPages: 416,
            progressPercent: 50.5,
            status: .inProgress,
            shelf: .onShelf,
            planMonth: "ОКТЯБРЬ",
            format: .paper,
            cycleName: "Зои Бентли",
            cycleStatus: 33.3,
            coverURL: "https://img-gorod.ru/upload/iblock/c38/c384d5df63897b2bc24254f15d7e3661.jpg",
            startDate: "2026-10-01",
            monthIndex: 10,
            purchaseDate: "2026-05-15"
        )
        
        let inProgress2 = Book(
            id: 2,
            title: "Время жить и время умирать",
            author: "Эрих Мария Ремарк",
            edition: "Магистраль",
            isbn: "978-5-17-090287-3",
            cycleNumber: "-",
            genre: .classicProse,
            pagesRead: 97,
            totalPages: 448,
            progressPercent: 21.7,
            status: .inProgress,
            shelf: .onShelf,
            planMonth: "ОКТЯБРЬ",
            format: .paper,
            cycleName: "-",
            coverURL: "https://img-gorod.ru/upload/iblock/98b/98b163a89e900508fc43cf3d2efad70f.jpg",
            startDate: "2026-10-05",
            monthIndex: 10,
            purchaseDate: "2026-04-12"
        )
        
        let inProgress3 = Book(
            id: 3,
            title: "Королевская Элита: Безжалостный рыцарь",
            author: "Рина Кент",
            edition: "Like Book",
            isbn: "978-5-04-159302-5",
            cycleNumber: "2",
            genre: .romanceYA,
            pagesRead: 140,
            totalPages: 384,
            progressPercent: 36.5,
            status: .inProgress,
            shelf: .onShelf,
            planMonth: "ОКТЯБРЬ",
            format: .paper,
            cycleName: "Королевская Элита",
            cycleStatus: 20.0,
            coverURL: "https://img-gorod.ru/upload/iblock/510/510658fa23932782e4e897e937d53a9e.jpg",
            startDate: "2026-10-08",
            monthIndex: 10,
            purchaseDate: "2026-08-20"
        )
        
        list.append(contentsOf: [inProgress1, inProgress2, inProgress3])
        
        // 2. Добавляем ключевые серии из ТЗ
        // Серия «Эркюль Пуаро» (4 из 12 прочитано)
        let poirotTitles = [
            ("Таинственное происшествие в Стайлзе", 288, true, "2026-01-10", "2026-01-14", BookRating.star5),
            ("Убийство на поле для гольфа", 320, true, "2026-02-01", "2026-02-06", BookRating.star4),
            ("Убийство Роджера Экройда", 352, true, "2026-03-12", "2026-03-16", BookRating.masterpiece),
            ("Большая четверка", 256, true, "2026-04-05", "2026-04-09", BookRating.star4),
            ("Тайна «Голубого поезда»", 320, false, nil, nil, nil),
            ("Загадка Эндхауза", 288, false, nil, nil, nil),
            ("Смерть лорда Эджвера", 320, false, nil, nil, nil),
            ("Убийство в Восточном экспрессе", 320, false, nil, nil, nil),
            ("Трагедия в трех актах", 288, false, nil, nil, nil),
            ("Смерть в облаках", 288, false, nil, nil, nil),
            ("Убийства по алфавиту", 320, false, nil, nil, nil),
            ("Карты на стол", 320, false, nil, nil, nil)
        ]
        
        for (idx, item) in poirotTitles.enumerated() {
            let bookId = list.count + 1
            let isRead = item.2
            let book = Book(
                id: bookId,
                title: item.0,
                author: "Агата Кристи",
                edition: "Эксклюзивная классика",
                isbn: "978-5-17-10\(1000 + idx)",
                cycleNumber: "\(idx + 1)",
                genre: .detective,
                pagesRead: isRead ? item.1 : 0,
                totalPages: item.1,
                progressPercent: isRead ? 100.0 : 0.0,
                status: isRead ? .read : .notStarted,
                shelf: .onShelf,
                planMonth: isRead ? nil : "НОЯБРЬ",
                format: .paper,
                rating: item.5,
                cycleName: "Эркюль Пуаро",
                cycleStatus: 33.3,
                coverURL: "https://img-gorod.ru/upload/iblock/c38/c384d5df63897b2bc24254f15d7e3661.jpg",
                startDate: item.3,
                endDate: item.4,
                monthIndex: isRead ? (idx + 1) : nil,
                purchaseDate: "2026-01-05"
            )
            list.append(book)
        }
        
        // Серия «Все ради игры» Нора Сакавич (3 книги)
        let allForGame = [
            ("Лисья нора", 336, true, BookRating.masterpiece),
            ("Король Воронов", 448, true, BookRating.star5),
            ("Свита короля", 544, true, BookRating.masterpiece)
        ]
        for (idx, item) in allForGame.enumerated() {
            let bookId = list.count + 1
            let book = Book(
                id: bookId,
                title: item.0,
                author: "Нора Сакавич",
                edition: "Popcorn Books",
                isbn: "978-5-6042\(400 + idx)",
                cycleNumber: "\(idx + 1)",
                genre: .romanceYA,
                pagesRead: item.1,
                totalPages: item.1,
                progressPercent: 100.0,
                status: .read,
                shelf: .onShelf,
                format: .paper,
                rating: item.3,
                cycleName: "Все ради игры",
                cycleStatus: 100.0,
                coverURL: "https://img-gorod.ru/upload/iblock/c38/c384d5df63897b2bc24254f15d7e3661.jpg",
                startDate: "2026-06-0\(idx + 1)",
                endDate: "2026-06-0\(idx + 5)",
                monthIndex: 6,
                purchaseDate: "2026-02-14"
            )
            list.append(book)
        }
        
        // Единственная электронная книга из ТЗ (326 бумажных / 1 электронная)
        let electronicBook = Book(
            id: list.count + 1,
            title: "Кафе на краю земли",
            author: "Джон Стрелеки",
            edition: "МИФ",
            isbn: "978-5-00169-123-4",
            cycleNumber: "1",
            genre: .philosophyPsychology,
            pagesRead: 160,
            totalPages: 160,
            progressPercent: 100.0,
            status: .read,
            shelf: .onlineReading,
            format: .electronic,
            rating: .star5,
            cycleName: "Кафе на краю земли",
            cycleStatus: 50.0,
            coverURL: "https://img-gorod.ru/upload/iblock/c38/c384d5df63897b2bc24254f15d7e3661.jpg",
            startDate: "2026-05-10",
            endDate: "2026-05-11",
            monthIndex: 5,
            purchaseDate: "2026-05-09"
        )
        list.append(electronicBook)
        
        // 3. Заполняем остальные прочитанные книги до 77 шт.
        let titlesPool = [
            ("1984", "Джордж Оруэлл", Genre.sciFiAltHistory, 320, BookRating.masterpiece),
            ("Преступление и наказание", "Федор Достоевский", Genre.classicProse, 672, BookRating.star5),
            ("Мастер и Маргарита", "Михаил Булгаков", Genre.mysticGothic, 512, BookRating.masterpiece),
            ("Внутри убийцы", "Майк Омер", Genre.psychologicalThriller, 416, BookRating.star5),
            ("Заживо в темноте", "Майк Омер", Genre.psychologicalThriller, 384, BookRating.star4),
            ("Глазами жертвы", "Майк Омер", Genre.psychologicalThriller, 416, BookRating.star4),
            ("Три товарища", "Эрих Мария Ремарк", Genre.classicProse, 480, BookRating.masterpiece),
            ("Триумфальная арка", "Эрих Мария Ремарк", Genre.classicProse, 512, BookRating.star5),
            ("На Западном фронте без перемен", "Эрих Мария Ремарк", Genre.classicProse, 288, BookRating.star5),
            ("Тайная история", "Донна Тартт", Genre.modernProse, 592, BookRating.masterpiece),
            ("Щегол", "Донна Тартт", Genre.modernProse, 832, BookRating.star5),
            ("Вторая жизнь Уве", "Фредрик Бакман", Genre.modernProse, 384, BookRating.masterpiece),
            ("Тревожные люди", "Фредрик Бакман", Genre.modernProse, 416, BookRating.star5),
            ("Медвежий угол", "Фредрик Бакман", Genre.modernProse, 528, BookRating.star5),
            ("Мы против вас", "Фредрик Бакман", Genre.modernProse, 544, BookRating.star4),
            ("Победители", "Фредрик Бакман", Genre.modernProse, 688, BookRating.star5),
            ("Безмолвный пациент", "Алекс Михаэлидес", Genre.psychologicalThriller, 352, BookRating.star4),
            ("Девы", "Алекс Михаэлидес", Genre.psychologicalThriller, 384, BookRating.star3),
            ("Охотничий дом", "Люси Фоли", Genre.detective, 384, BookRating.star4),
            ("Список гостей", "Люси Фоли", Genre.detective, 384, BookRating.star4),
            ("Квартира в Париже", "Люси Фоли", Genre.detective, 416, BookRating.star3),
            ("Исчезнувшая", "Гиллиан Флинн", Genre.psychologicalThriller, 512, BookRating.star5),
            ("Острые предметы", "Гиллиан Флинн", Genre.psychologicalThriller, 320, BookRating.star4),
            ("Темные тайны", "Гиллиан Флинн", Genre.psychologicalThriller, 448, BookRating.star4),
            ("Снеговик", "Ю Несбё", Genre.detective, 512, BookRating.masterpiece),
            ("Красношейка", "Ю Несбё", Genre.detective, 480, BookRating.star4),
            ("Нетопырь", "Ю Несбё", Genre.detective, 384, BookRating.star3),
            ("Тараканы", "Ю Несбё", Genre.detective, 416, BookRating.star3),
            ("Зов Кукушки", "Роберт Гэлбрейт", Genre.detective, 480, BookRating.star5),
            ("Шелкопряд", "Роберт Гэлбрейт", Genre.detective, 512, BookRating.star4),
            ("На службе зла", "Роберт Гэлбрейт", Genre.detective, 576, BookRating.star5),
            ("Смертельная белизна", "Роберт Гэлбрейт", Genre.detective, 672, BookRating.star4),
            ("Дурная кровь", "Роберт Гэлбрейт", Genre.detective, 960, BookRating.masterpiece),
            ("Иллиум", "Рина Кент", Genre.romanceYA, 380, BookRating.star4),
            ("Королевская элита: Порочный принц", "Рина Кент", Genre.romanceYA, 360, BookRating.star5), // Дубликат регистра
            ("Убийство в «Восточном экспрессе»", "Агата Кристи", Genre.detective, 256, BookRating.masterpiece),
            ("Десять негритят", "Агата Кристи", Genre.detective, 288, BookRating.masterpiece),
            ("И никого не стало", "Агата Кристи", Genre.detective, 288, BookRating.star5),
            ("Смерть на Ниле", "Агата Кристи", Genre.detective, 352, BookRating.star5),
            ("Убийства в десятиугольном доме", "Юкито Аяцудзи", Genre.detective, 320, BookRating.star4),
            ("Токийский Зодиак", "Содзи Симада", Genre.detective, 352, BookRating.star5),
            ("Двойник с Лунной дамбы", "Содзи Симада", Genre.detective, 384, BookRating.star4),
            ("Хладнокровное убийство", "Трумен Капоте", Genre.trueCrime, 416, BookRating.masterpiece),
            ("Не говори никому", "Грегг Олсен", Genre.trueCrime, 480, BookRating.star5),
            ("Я исчезну во тьме", "Мишель Макнамара", Genre.trueCrime, 448, BookRating.star4),
            ("Кладбище домашних животных", "Стивен Кинг", Genre.mysticGothic, 480, BookRating.masterpiece),
            ("Сияние", "Стивен Кинг", Genre.mysticGothic, 544, BookRating.masterpiece),
            ("Оно", "Стивен Кинг", Genre.mysticGothic, 1248, BookRating.masterpiece),
            ("Мизери", "Стивен Кинг", Genre.psychologicalThriller, 416, BookRating.star5),
            ("Зеленая миля", "Стивен Кинг", Genre.classicProse, 448, BookRating.masterpiece),
            ("Побег из Шоушенка", "Стивен Кинг", Genre.classicProse, 192, BookRating.masterpiece),
            ("Цветы для Элджернона", "Дэниел Киз", Genre.sciFiAltHistory, 320, BookRating.masterpiece),
            ("Таинственная история Билли Миллигана", "Дэниел Киз", Genre.trueCrime, 576, BookRating.masterpiece),
            ("Американский психопат", "Брет Истон Эллис", Genre.psychologicalThriller, 544, BookRating.star4),
            ("О дивный новый мир", "Олдос Хаксли", Genre.sciFiAltHistory, 352, BookRating.star5),
            ("451 градус по Фаренгейту", "Рэй Брэдбери", Genre.sciFiAltHistory, 256, BookRating.masterpiece),
            ("Вино из одуванчиков", "Рэй Брэдбери", Genre.classicProse, 320, BookRating.star5),
            ("Марсианские хроники", "Рэй Брэдбери", Genre.sciFiAltHistory, 320, BookRating.star4),
            ("Маленький принц", "Антуан де Сент-Экзюпери", Genre.classicProse, 128, BookRating.masterpiece),
            ("Портрет Дориана Грея", "Оскар Уайльд", Genre.classicProse, 320, BookRating.masterpiece),
            ("Граф Монте-Кристо. Том 1", "Александр Дюма", Genre.classicProse, 672, BookRating.masterpiece),
            ("Граф Монте-Кристо. Том 2", "Александр Дюма", Genre.classicProse, 704, BookRating.masterpiece),
            ("Три мушкетера", "Александр Дюма", Genre.classicProse, 640, BookRating.star5),
            ("Гордость и предубеждение", "Джейн Остин", Genre.romanceYA, 416, BookRating.masterpiece),
            ("Джейн Эйр", "Шарлотта Бронте", Genre.romanceYA, 576, BookRating.masterpiece),
            ("Грозовой перевал", "Эмили Бронте", Genre.mysticGothic, 416, BookRating.star5),
            ("Отверженные. Том 1", "Виктор Гюго", Genre.classicProse, 736, BookRating.masterpiece),
            ("Собор Парижской Богоматери", "Виктор Гюго", Genre.classicProse, 544, BookRating.masterpiece)
        ]
        
        let readTarget = 77
        var currentRead = list.filter { $0.status == .read }.count
        
        for item in titlesPool {
            if currentRead >= readTarget { break }
            let bookId = list.count + 1
            let cycleName = item.0.contains("Граф Монте-Кристо") ? "Граф Монте-Кристо" : (item.0.contains("Королевская элита") ? "Королевская элита" : "-")
            let book = Book(
                id: bookId,
                title: item.0,
                author: item.1,
                edition: "Эксклюзивная классика",
                isbn: "978-5-17-00\(1000 + bookId)",
                genre: item.2,
                pagesRead: item.3,
                totalPages: item.3,
                progressPercent: 100.0,
                status: .read,
                shelf: .onShelf,
                format: .paper,
                rating: item.4,
                cycleName: cycleName,
                coverURL: "https://img-gorod.ru/upload/iblock/c38/c384d5df63897b2bc24254f15d7e3661.jpg",
                startDate: "2026-02-10",
                endDate: "2026-02-18",
                monthIndex: 2,
                purchaseDate: "2026-01-15"
            )
            list.append(book)
            currentRead += 1
        }
        
        // 4. Добавляем не начатые книги («В очереди», статус «Не начата») до ровно 327 книг (247 не начатых)
        let totalTarget = 327
        let neededUnread = totalTarget - list.count
        
        let unreadTitles = [
            "Ночь в Лиссабоне", "Возлюби ближнего своего", "Черный обелиск", "Тени в раю",
            "Жизнь взаймы", "Земля обетованная", "Братья Карамазовы", "Идиот", "Бесы",
            "Записки из подполья", "Униженные и оскорбленные", "Подросток", "Война и мир",
            "Анна Каренина", "Воскресение", "Смерть Ивана Ильича", "Белая гвардия", "Собачье сердце",
            "Роковые яйца", "Морфий", "Записки юного врача", "Театральный роман", "Дьяволиада",
            "Скотный двор", "Памяти Каталонии", "Дни в Бирме", "Процесс", "Замок", "Превращение",
            "Норвежский лес", "Кафка на пляже", "Охота на овец", "Хроники Заводной Птицы",
            "1Q84", "Бессердечные", "Город полумесяца", "Королевство шипов и роз", "Шестерка воронов",
            "Продажное королевство", "Тень и кость", "Штурм и буря", "Крах и восход"
        ]
        
        for i in 0..<neededUnread {
            let bookId = list.count + 1
            let titleIndex = i % unreadTitles.count
            let title = "\(unreadTitles[titleIndex])\(i >= unreadTitles.count ? " (Экз. \(i / unreadTitles.count + 1))" : "")"
            let author = sampleAuthors[i % sampleAuthors.count]
            let genre = Genre.allCases[i % Genre.allCases.count]
            let edition = sampleEditions[i % sampleEditions.count]
            let totalPages = 280 + (i * 17) % 450
            
            let planMonth: String? = (i % 7 == 0) ? "НОЯБРЬ" : ((i % 11 == 0) ? "ДЕКАБРЬ" : nil)
            
            let book = Book(
                id: bookId,
                title: title,
                author: author,
                edition: edition,
                isbn: "978-5-04-10\(2000 + i)",
                genre: genre,
                pagesRead: 0,
                totalPages: totalPages,
                progressPercent: 0.0,
                status: .notStarted,
                shelf: .onShelf,
                planMonth: planMonth,
                format: .paper,
                cycleName: "-",
                coverURL: "https://img-gorod.ru/upload/iblock/c38/c384d5df63897b2bc24254f15d7e3661.jpg",
                purchaseDate: "2026-07-10"
            )
            list.append(book)
        }
        
        return list
    }
    
    public static func generateInitialBingo() -> [BingoItem] {
        return [
            BingoItem(
                id: 1,
                title: "Дурное поведение",
                author: "Зои Бентли",
                planMonth: "ОКТЯБРЬ",
                totalPages: 416,
                startDate: "2026-10-01",
                genre: "Психологический триллер",
                speedPagesPerDay: 35.0,
                planDays: 4,
                plannedPagesPerDay: 104.0
            ),
            BingoItem(
                id: 2,
                title: "Время жить и время умирать",
                author: "Эрих Мария Ремарк",
                planMonth: "ОКТЯБРЬ",
                totalPages: 448,
                startDate: "2026-10-05",
                genre: "Классическая проза",
                speedPagesPerDay: 48.0,
                planDays: 6,
                plannedPagesPerDay: 75.0
            ),
            BingoItem(
                id: 3,
                title: "Королевская Элита: Безжалостный рыцарь",
                author: "Рина Кент",
                planMonth: "ОКТЯБРЬ",
                totalPages: 384,
                startDate: "2026-10-08",
                genre: "Любовный роман / Young Adult",
                speedPagesPerDay: 70.0,
                planDays: 3,
                plannedPagesPerDay: 128.0
            ),
            BingoItem(
                id: 4,
                title: "Тайна «Голубого поезда»",
                author: "Агата Кристи",
                planMonth: "НОЯБРЬ",
                totalPages: 320,
                genre: "Детектив",
                planDays: 3,
                plannedPagesPerDay: 107.0
            ),
            BingoItem(
                id: 5,
                title: "Загадка Эндхауза",
                author: "Агата Кристи",
                planMonth: "НОЯБРЬ",
                totalPages: 288,
                genre: "Детектив",
                planDays: 2,
                plannedPagesPerDay: 144.0
            )
        ]
    }
}
