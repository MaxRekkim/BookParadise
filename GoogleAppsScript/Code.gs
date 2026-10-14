/**
 * ============================================================================
 * ✨📚 КНИЖНЫЙ РАЙ 📚✨ — Google Apps Script Webhook API (v1.0)
 * ============================================================================
 * 
 * Данный скрипт развертывается как Web App (Веб-приложение) в вашей Google Таблице.
 * Он предоставляет REST API для нативного iOS-приложения BookParadise:
 * - GET: возвращает полную базу книг, планы книжного бинго, циклы и аналитику.
 * - POST: атомарно обновляет прогресс чтения, добавляет новые книги и изменяет планы,
 *   БЕРЕЖНО сохраняя все формулы таблицы (=IMAGE(...), формулы процентов и ключи сортировки).
 *
 * ИНСТРУКЦИЯ ПО РАЗВЕРТЫВАНИЮ:
 * 1. Откройте вашу Google Таблицу «✨📚КНИЖНЫЙ РАЙ📚✨».
 * 2. В верхнем меню выберите: Расширения -> Apps Script.
 * 3. Полностью удалите стандартный код и вставьте содержимое этого файла.
 * 4. Нажмите «Развернуть» (Deploy) -> «Новое развертывание» (New deployment).
 * 5. Тип: «Веб-приложение» (Web app).
 * 6. Описание: BookParadise API.
 * 7. Выполнять от имени: «Я» (Execute as: Me).
 * 8. У кого есть доступ: «Все» (Anyone) — это необходимо, чтобы iOS-приложение
 *    могло отправлять запросы без сложной авторизации OAuth.
 * 9. Нажмите «Развернуть», разрешите доступ и скопируйте URL веб-приложения
 *    (заканчивается на /exec). Вставьте этот URL в настройки приложения на iPhone.
 * ============================================================================
 */

const SHEET_BOOKS = "База книг";
const SHEET_BINGO = "Книжное бинго";
const SHEET_DASHBOARD = "Дашборд";

// Маппинг столбцов листа «База книг» (1-indexed для Sheet API: A=1 ... W=23)
const COL = {
  ID: 1,              // A: № (Int)
  TITLE: 2,           // B: Название книги
  AUTHOR: 3,          // C: Автор
  EDITION: 4,         // D: Издание / Серия
  ISBN: 5,            // E: ISBN
  CYCLE_NUM: 6,       // F: Номер в цикле
  COVER_FORMULA: 7,   // G: Обложка (=IMAGE(S{row}))
  GENRE: 8,           // H: Жанр
  PAGES_READ: 9,      // I: Прочитано стр.
  TOTAL_PAGES: 10,    // J: Всего стр.
  PERCENT_FORMULA: 11,// K: Процент прочтения (=I/J)
  STATUS: 12,         // L: Статус чтения (Не начата, В процессе, Прочитано)
  SHELF: 13,          // M: На полке (В наличии, Онлайн-чтение)
  PLAN_MONTH: 14,     // N: ПЛАН ЧТЕНИЯ (ИЮНЬ, ИЮЛЬ, Заброшено...)
  FORMAT: 15,         // O: Формат книги (Бумажная, Электронная)
  RATING: 16,         // P: Оценка (★, ★★, ..., Шедевр!)
  CYCLE_NAME: 17,     // Q: Название цикла
  CYCLE_STATUS: 18,   // R: Статус цикла (%)
  COVER_URL: 19,      // S: Ссылки на обложки
  START_DATE: 20,     // T: Начало чтения (YYYY-MM-DD)
  END_DATE: 21,       // U: Конец чтения (YYYY-MM-DD)
  MONTH_INDEX: 22,    // V: Месяц по порядку (1-12)
  PURCHASE_DATE: 23   // W: Дата покупки (YYYY-MM-DD)
};

// Фиксированные справочники для валидации
const GENRES = [
  "Детектив",
  "Классическая проза",
  "Любовный роман / Young Adult",
  "Мистика / Готика",
  "Психологический триллер",
  "Современная проза",
  "Фантастика / Альтернативная история",
  "Философия / Психология / Нон-фикшн",
  "True Crime / Нон-фикшн о преступлениях"
];

/**
 * Обработка GET-запроса: загрузка базы данных и статистики в приложение
 */
function doGet(e) {
  try {
    const ss = SpreadsheetApp.getActiveSpreadsheet();
    const booksSheet = ss.getSheetByName(SHEET_BOOKS);
    const bingoSheet = ss.getSheetByName(SHEET_BINGO);
    
    if (!booksSheet) {
      return jsonResponse({ success: false, error: "Лист «" + SHEET_BOOKS + "» не найден в таблице. Проверьте название листа." });
    }

    // 1. Читаем книги из «База книг»
    const booksData = getBooksList(booksSheet);

    // 2. Читаем бинго из «Книжное бинго» (если лист существует)
    const bingoData = bingoSheet ? getBingoList(bingoSheet) : [];

    // 3. Собираем уникальные списки для автодополнения и фильтров
    const authorsSet = new Set();
    const editionsSet = new Set();
    const cyclesMap = {}; // нормализованное_имя -> { canonicalName, booksCount, readCount }

    booksData.forEach(b => {
      if (b.author) authorsSet.add(b.author.trim());
      if (b.edition) {
        b.edition.split(';').forEach(ed => {
          const trimmed = ed.trim();
          if (trimmed) editionsSet.add(trimmed);
        });
      }
      if (b.cycleName && b.cycleName !== "-" && b.cycleName.trim() !== "") {
        const canonical = b.cycleName.trim();
        const normKey = canonical.toLowerCase();
        if (!cyclesMap[normKey]) {
          cyclesMap[normKey] = {
            name: canonical,
            totalBooks: 0,
            readBooks: 0,
            books: []
          };
        }
        cyclesMap[normKey].totalBooks++;
        if (b.status === "Прочитано") {
          cyclesMap[normKey].readBooks++;
        }
        cyclesMap[normKey].books.push({
          id: b.id,
          title: b.title,
          cycleNumber: b.cycleNumber,
          isRead: b.status === "Прочитано"
        });
      }
    });

    const cycles = Object.values(cyclesMap).map(c => {
      c.completionPercent = c.totalBooks > 0 ? Math.round((c.readBooks / c.totalBooks) * 1000) / 10 : 0;
      return c;
    });

    // 4. Сводная статистика для дашборда
    const stats = calculateStats(booksData);

    const response = {
      success: true,
      timestamp: new Date().toISOString(),
      stats: stats,
      genres: GENRES,
      authors: Array.from(authorsSet).sort(),
      editions: Array.from(editionsSet).sort(),
      cycles: cycles,
      books: booksData,
      bingo: bingoData
    };

    return jsonResponse(response);

  } catch (err) {
    return jsonResponse({ success: false, error: err.toString() });
  }
}

/**
 * Обработка POST-запроса: изменение прогресса, добавление книг, редактирование планов
 */
function doPost(e) {
  const lock = LockService.getScriptLock();
  let hasLock = false;
  try {
    hasLock = lock.tryLock(10000);

    if (!e || !e.postData || !e.postData.contents) {
      return jsonResponse({ success: false, error: "Тело запроса пустое (No POST payload)" });
    }

    let payload;
    try {
      payload = JSON.parse(e.postData.contents);
    } catch (parseErr) {
      return jsonResponse({ success: false, error: "Некорректный JSON: " + parseErr.message });
    }

    const action = payload.action;
    const ss = SpreadsheetApp.getActiveSpreadsheet();
    const booksSheet = ss.getSheetByName(SHEET_BOOKS);
    const bingoSheet = ss.getSheetByName(SHEET_BINGO);

    if (!booksSheet) {
      return jsonResponse({ success: false, error: "Лист «" + SHEET_BOOKS + "» не найден." });
    }

    switch (action) {
      case "updateProgress":
        return handleUpdateProgress(booksSheet, payload);

      case "addBook":
        return handleAddBook(booksSheet, payload);

      case "updatePlan":
        return handleUpdatePlan(booksSheet, bingoSheet, payload);

      case "updateBookDetails":
        return handleUpdateBookDetails(booksSheet, payload);

      default:
        return jsonResponse({ success: false, error: "Неизвестное действие: " + action });
    }

  } catch (err) {
    return jsonResponse({ success: false, error: err.toString() });
  } finally {
    if (hasLock) {
      try { lock.releaseLock(); } catch(e) {}
    }
  }
}

/**
 * Сценарий А: Обновление прогресса чтения (I: Прочитано стр.)
 * Автоматически рассчитывает L (Статус), T (Начало), U (Конец), V (Месяц), P (Оценка)
 */
function handleUpdateProgress(sheet, payload) {
  const bookId = parseInt(payload.id, 10);
  const newPagesRead = parseInt(payload.pagesRead, 10);
  const rating = payload.rating || "";

  if (isNaN(bookId) || isNaN(newPagesRead)) {
    return jsonResponse({ success: false, error: "Неверный bookId или pagesRead" });
  }

  const row = findRowByBookId(sheet, bookId);
  if (!row) {
    return jsonResponse({ success: false, error: "Книга с № " + bookId + " не найдена в таблице." });
  }

  // Считываем текущие данные строки
  const totalPages = parseInt(sheet.getRange(row, COL.TOTAL_PAGES).getValue(), 10) || 0;
  const oldPagesRead = parseInt(sheet.getRange(row, COL.PAGES_READ).getValue(), 10) || 0;
  const currentStartDate = sheet.getRange(row, COL.START_DATE).getValue();
  const currentEndDate = sheet.getRange(row, COL.END_DATE).getValue();

  // 1. Записываем прочитанные страницы (I)
  sheet.getRange(row, COL.PAGES_READ).setValue(newPagesRead);

  const todayStr = formatDate(new Date());
  const currentMonthNum = new Date().getMonth() + 1; // 1-12

  // 2. Логика статуса и дат
  if (newPagesRead <= 0) {
    // Не начата
    sheet.getRange(row, COL.STATUS).setValue("Не начата");
    // Не стираем даты, если пользователь не просил явно
  } else if (newPagesRead < totalPages) {
    // В процессе
    sheet.getRange(row, COL.STATUS).setValue("В процессе");
    
    // Если раньше книга не была начата (или дата начала пуста) -> ставим сегодняшнюю дату
    if (!currentStartDate || oldPagesRead === 0) {
      sheet.getRange(row, COL.START_DATE).setValue(todayStr);
      sheet.getRange(row, COL.MONTH_INDEX).setValue(currentMonthNum);
    }
  } else {
    // Прочитано полностью (newPagesRead >= totalPages)
    sheet.getRange(row, COL.PAGES_READ).setValue(totalPages); // Нормализуем, чтобы не превышало всего стр.
    sheet.getRange(row, COL.STATUS).setValue("Прочитано");

    // Если дата начала была пустой — ставим сегодня
    if (!currentStartDate) {
      sheet.getRange(row, COL.START_DATE).setValue(todayStr);
      sheet.getRange(row, COL.MONTH_INDEX).setValue(currentMonthNum);
    }

    // Ставим дату окончания (U)
    sheet.getRange(row, COL.END_DATE).setValue(todayStr);

    // Если передана оценка — записываем в P
    if (rating) {
      sheet.getRange(row, COL.RATING).setValue(rating);
    }
  }

  SpreadsheetApp.flush();

  return jsonResponse({
    success: true,
    message: "Прогресс успешно сохранен",
    bookId: bookId,
    pagesRead: newPagesRead,
    totalPages: totalPages
  });
}

/**
 * Сценарий Б: Добавление новой книги
 * Вычисляет MAX(A:A) + 1, записывает формулу =IMAGE(S{row}) и сохраняет значения
 */
function handleAddBook(sheet, payload) {
  const title = (payload.title || "").trim();
  const author = (payload.author || "").trim();
  const totalPages = parseInt(payload.totalPages, 10);

  if (!title) {
    return jsonResponse({ success: false, error: "Название книги обязательно" });
  }
  if (isNaN(totalPages) || totalPages <= 0) {
    return jsonResponse({ success: false, error: "Количество страниц должно быть больше 0" });
  }

  const lastRow = sheet.getLastRow();
  // Находим максимальный ID в столбце A
  let maxId = 0;
  if (lastRow >= 2) {
    const idRangeValues = sheet.getRange(2, COL.ID, lastRow - 1, 1).getValues();
    for (let i = 0; i < idRangeValues.length; i++) {
      const val = parseInt(idRangeValues[i][0], 10);
      if (!isNaN(val) && val > maxId) {
        maxId = val;
      }
    }
  }
  const newId = maxId + 1;
  const newRow = lastRow + 1;

  // Очистка ISBN от лишних пробелов и переносов строк
  let cleanIsbn = (payload.isbn || "").replace(/[\r\n\t]/g, "").trim();

  // Параметры по умолчанию
  const edition = (payload.edition || "").trim();
  const cycleNum = (payload.cycleNumber || "-").trim();
  const genre = (payload.genre || "Современная проза").trim();
  const pagesRead = parseInt(payload.pagesRead, 10) || 0;
  const format = (payload.format || "Бумажная").trim();
  const shelf = format === "Электронная" ? "Онлайн-чтение" : (payload.shelf || "В наличии").trim();
  const planMonth = (payload.planMonth || "").trim();
  const rating = (payload.rating || "").trim();
  const cycleName = (payload.cycleName || "-").trim();
  const coverUrl = (payload.coverURL || "").trim();
  const todayStr = formatDate(new Date());
  const purchaseDate = payload.purchaseDate ? payload.purchaseDate : todayStr;

  // Статус
  let status = "Не начата";
  let startDate = "";
  let endDate = "";
  let monthIndex = "";

  if (pagesRead > 0 && pagesRead < totalPages) {
    status = "В процессе";
    startDate = todayStr;
    monthIndex = new Date().getMonth() + 1;
  } else if (pagesRead >= totalPages) {
    status = "Прочитано";
    startDate = todayStr;
    endDate = todayStr;
    monthIndex = new Date().getMonth() + 1;
  }

  // Формируем массив значений строки (23 элемента: A-W)
  const rowData = [
    newId,                                        // A: №
    title,                                        // B: Название
    author,                                       // C: Автор
    edition,                                      // D: Издание
    cleanIsbn,                                    // E: ISBN
    cycleNum,                                     // F: Номер в цикле
    '=IMAGE(S' + newRow + ')',                    // G: Обложка (Формула)
    genre,                                        // H: Жанр
    pagesRead > 0 ? pagesRead : "",               // I: Прочитано стр.
    totalPages,                                   // J: Всего стр.
    '=IF(J' + newRow + '>0; I' + newRow + '/J' + newRow + '; 0)', // K: Формула процента
    status,                                       // L: Статус чтения
    shelf,                                        // M: На полке
    planMonth,                                    // N: ПЛАН ЧТЕНИЯ
    format,                                       // O: Формат книги
    rating,                                       // P: Оценка
    cycleName,                                    // Q: Название цикла
    '=IF(OR(Q' + newRow + '="-"; Q' + newRow + '=""); ""; COUNTIFS(Q:Q; Q' + newRow + '; L:L; "Прочитано")/COUNTIF(Q:Q; Q' + newRow + '))', // R: Статус цикла (%)
    coverUrl,                                     // S: Ссылки на обложки
    startDate,                                    // T: Начало чтения
    endDate,                                      // U: Конец чтения
    monthIndex,                                   // V: Месяц по порядку
    purchaseDate                                  // W: Дата покупки
  ];

  sheet.getRange(newRow, 1, 1, 23).setValues([rowData]);
  SpreadsheetApp.flush();

  return jsonResponse({
    success: true,
    message: "Книга успешно добавлена",
    bookId: newId,
    row: newRow
  });
}

/**
 * Сценарий В: Добавление в план месяца и лист «Книжное бинго»
 */
function handleUpdatePlan(booksSheet, bingoSheet, payload) {
  const bookId = parseInt(payload.id, 10);
  const planMonth = (payload.month || "").trim().toUpperCase(); // Например "ИЮЛЬ" или "ЗАБРОШЕНО"
  const planDays = parseInt(payload.planDays, 10) || 0; // План дней на книгу

  if (isNaN(bookId)) {
    return jsonResponse({ success: false, error: "Неверный bookId" });
  }

  const row = findRowByBookId(booksSheet, bookId);
  if (!row) {
    return jsonResponse({ success: false, error: "Книга с № " + bookId + " не найдена" });
  }

  // Обновляем столбец N (ПЛАН ЧТЕНИЯ) в «База книг»
  booksSheet.getRange(row, COL.PLAN_MONTH).setValue(planMonth);

  // Если лист «Книжное бинго» подключен и указаны дни плана, обновляем столбец L в бинго
  if (bingoSheet && planDays > 0) {
    updateBingoPlanDays(bingoSheet, bookId, planDays);
  }

  SpreadsheetApp.flush();

  return jsonResponse({
    success: true,
    message: "План обновлен",
    bookId: bookId,
    planMonth: planMonth
  });
}

/**
 * Редактирование общих полей книги (автор, название, жанр, цикл, обложка и т.д.)
 */
function handleUpdateBookDetails(sheet, payload) {
  const bookId = parseInt(payload.id, 10);
  if (isNaN(bookId)) {
    return jsonResponse({ success: false, error: "Неверный bookId" });
  }

  const row = findRowByBookId(sheet, bookId);
  if (!row) {
    return jsonResponse({ success: false, error: "Книга с № " + bookId + " не найдена" });
  }

  if (payload.title !== undefined) sheet.getRange(row, COL.TITLE).setValue(payload.title.trim());
  if (payload.author !== undefined) sheet.getRange(row, COL.AUTHOR).setValue(payload.author.trim());
  if (payload.edition !== undefined) sheet.getRange(row, COL.EDITION).setValue(payload.edition.trim());
  if (payload.isbn !== undefined) sheet.getRange(row, COL.ISBN).setValue(payload.isbn.replace(/[\r\n\t]/g, "").trim());
  if (payload.cycleNumber !== undefined) sheet.getRange(row, COL.CYCLE_NUM).setValue(payload.cycleNumber.trim());
  if (payload.genre !== undefined) sheet.getRange(row, COL.GENRE).setValue(payload.genre.trim());
  if (payload.totalPages !== undefined) sheet.getRange(row, COL.TOTAL_PAGES).setValue(parseInt(payload.totalPages, 10) || 0);
  if (payload.shelf !== undefined) sheet.getRange(row, COL.SHELF).setValue(payload.shelf.trim());
  if (payload.format !== undefined) sheet.getRange(row, COL.FORMAT).setValue(payload.format.trim());
  if (payload.rating !== undefined) sheet.getRange(row, COL.RATING).setValue(payload.rating.trim());
  if (payload.cycleName !== undefined) sheet.getRange(row, COL.CYCLE_NAME).setValue(payload.cycleName.trim());
  if (payload.coverURL !== undefined) sheet.getRange(row, COL.COVER_URL).setValue(payload.coverURL.trim());
  if (payload.purchaseDate !== undefined) sheet.getRange(row, COL.PURCHASE_DATE).setValue(payload.purchaseDate);

  SpreadsheetApp.flush();

  return jsonResponse({
    success: true,
    message: "Данные книги обновлены",
    bookId: bookId
  });
}

// ----------------------------------------------------------------------------
// ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
// ----------------------------------------------------------------------------

function getBooksList(sheet) {
  const lastRow = sheet.getLastRow();
  if (lastRow < 2) return [];

  // Читаем все строки от A2 до W{lastRow}
  const range = sheet.getRange(2, 1, lastRow - 1, 23);
  const values = range.getValues();
  const books = [];

  for (let i = 0; i < values.length; i++) {
    const row = values[i];
    const id = parseInt(row[COL.ID - 1], 10);
    const title = String(row[COL.TITLE - 1] || "").trim();

    if (!id && !title) continue; // Пропускаем полностью пустые строки

    const pagesRead = parseInt(row[COL.PAGES_READ - 1], 10) || 0;
    const totalPages = parseInt(row[COL.TOTAL_PAGES - 1], 10) || 0;
    const percent = totalPages > 0 ? Math.round((pagesRead / totalPages) * 1000) / 10 : 0;

    books.push({
      id: id || (i + 1),
      title: title,
      author: String(row[COL.AUTHOR - 1] || "").trim(),
      edition: String(row[COL.EDITION - 1] || "").trim(),
      isbn: String(row[COL.ISBN - 1] || "").trim(),
      cycleNumber: String(row[COL.CYCLE_NUM - 1] || "-").trim(),
      genre: String(row[COL.GENRE - 1] || "Современная проза").trim(),
      pagesRead: pagesRead,
      totalPages: totalPages,
      progressPercent: percent,
      status: String(row[COL.STATUS - 1] || (pagesRead >= totalPages && totalPages > 0 ? "Прочитано" : (pagesRead > 0 ? "В процессе" : "Не начата"))).trim(),
      shelf: String(row[COL.SHELF - 1] || "В наличии").trim(),
      planMonth: String(row[COL.PLAN_MONTH - 1] || "").trim(),
      format: String(row[COL.FORMAT - 1] || "Бумажная").trim(),
      rating: String(row[COL.RATING - 1] || "").trim(),
      cycleName: String(row[COL.CYCLE_NAME - 1] || "-").trim(),
      coverURL: String(row[COL.COVER_URL - 1] || "").trim(),
      startDate: formatCellDate(row[COL.START_DATE - 1]),
      endDate: formatCellDate(row[COL.END_DATE - 1]),
      monthIndex: parseInt(row[COL.MONTH_INDEX - 1], 10) || null,
      purchaseDate: formatCellDate(row[COL.PURCHASE_DATE - 1])
    });
  }

  return books;
}

function getBingoList(sheet) {
  const lastRow = sheet.getLastRow();
  if (lastRow < 2) return [];

  // Лист Книжное бинго: A..M (13 колонок)
  const values = sheet.getRange(2, 1, lastRow - 1, 13).getValues();
  const bingo = [];

  for (let i = 0; i < values.length; i++) {
    const row = values[i];
    const id = parseInt(row[0], 10);
    const title = String(row[1] || "").trim();
    if (!id && !title) continue;

    const totalPages = parseInt(row[4], 10) || 0;
    const speed = parseFloat(row[8]) || 0;
    const planDays = parseInt(row[11], 10) || 0;
    const plannedPagesPerDay = parseFloat(row[12]) || (planDays > 0 ? Math.round(totalPages / planDays) : 0);

    bingo.push({
      id: id,
      title: title,
      author: String(row[2] || "").trim(),
      planMonth: String(row[3] || "").trim(),
      totalPages: totalPages,
      startDate: formatCellDate(row[5]),
      endDate: formatCellDate(row[6]),
      genre: String(row[7] || "").trim(),
      speedPagesPerDay: speed,
      planDays: planDays,
      plannedPagesPerDay: plannedPagesPerDay,
      sortKey: String(row[10] || "") // Столбец K (технический ключ)
    });
  }

  return bingo;
}

function updateBingoPlanDays(sheet, bookId, planDays) {
  const lastRow = sheet.getLastRow();
  if (lastRow < 2) return;

  const ids = sheet.getRange(2, 1, lastRow - 1, 1).getValues();
  for (let i = 0; i < ids.length; i++) {
    if (parseInt(ids[i][0], 10) === bookId) {
      // Столбец L — это 12-я колонка
      sheet.getRange(i + 2, 12).setValue(planDays);
      break;
    }
  }
}

function findRowByBookId(sheet, bookId) {
  const lastRow = sheet.getLastRow();
  if (lastRow < 2) return null;

  const idValues = sheet.getRange(2, COL.ID, lastRow - 1, 1).getValues();
  for (let i = 0; i < idValues.length; i++) {
    if (parseInt(idValues[i][0], 10) === bookId) {
      return i + 2; // +2 из-за заголовка и 1-indexed API
    }
  }
  return null;
}

function calculateStats(books) {
  let totalBooks = books.length;
  let readBooks = 0;
  let inProgressBooks = 0;
  let unreadBooks = 0;
  let paperBooks = 0;
  let electronicBooks = 0;
  let totalPagesRead = 0;

  const genreCounts = {};
  const ratingCounts = {};
  const monthlyPurchases = {};

  GENRES.forEach(g => genreCounts[g] = { total: 0, read: 0 });

  books.forEach(b => {
    totalPagesRead += b.pagesRead;

    if (b.status === "Прочитано") readBooks++;
    else if (b.status === "В процессе") inProgressBooks++;
    else unreadBooks++;

    if (b.format === "Электронная") electronicBooks++;
    else paperBooks++;

    if (genreCounts[b.genre]) {
      genreCounts[b.genre].total++;
      if (b.status === "Прочитано") genreCounts[b.genre].read++;
    }

    if (b.rating) {
      ratingCounts[b.rating] = (ratingCounts[b.rating] || 0) + 1;
    }

    if (b.purchaseDate && b.purchaseDate.length >= 7) {
      const yearMonth = b.purchaseDate.substring(0, 7); // YYYY-MM
      monthlyPurchases[yearMonth] = (monthlyPurchases[yearMonth] || 0) + 1;
    }
  });

  return {
    totalBooks: totalBooks,
    readBooks: readBooks,
    inProgressBooks: inProgressBooks,
    unreadBooks: unreadBooks,
    paperBooks: paperBooks,
    electronicBooks: electronicBooks,
    totalPagesRead: totalPagesRead,
    percentRead: totalBooks > 0 ? Math.round((readBooks / totalBooks) * 1000) / 10 : 0,
    genreCounts: genreCounts,
    ratingCounts: ratingCounts,
    monthlyPurchases: monthlyPurchases
  };
}

function formatCellDate(cellValue) {
  if (!cellValue) return "";
  if (cellValue instanceof Date) {
    return formatDate(cellValue);
  }
  return String(cellValue).trim();
}

function formatDate(date) {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, '0');
  const d = String(date.getDate()).padStart(2, '0');
  return y + "-" + m + "-" + d;
}

function jsonResponse(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj))
    .setMimeType(ContentService.MimeType.JSON);
}
