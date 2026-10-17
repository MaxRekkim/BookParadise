import { Book, Quote, Note, Goal, UserPersonalization } from '../types';
import { initialBooks, initialQuotes, initialNotes, initialGoal } from '../data/initialData';

const STORAGE_KEYS = {
  BOOKS: 'bookparadise_books_v2',
  QUOTES: 'bookparadise_quotes_v2',
  NOTES: 'bookparadise_notes_v2',
  GOAL: 'bookparadise_goal_v2',
  SHEETS_URL: 'bookparadise_sheets_url_v2',
  APP_ICON: 'bookparadise_app_icon_v2',
  PERSONALIZATION: 'bookparadise_personalization_v2',
};

export const defaultPersonalization: UserPersonalization = {
  theme: 'emerald',
  appIcon: 'emerald',
  fontFamily: 'sans',
  fontSize: 'normal',
  cardStyle: 'bento',
  kindleEmail: '',
  dailyGoalMinutes: 30,
  timerSprintMinutes: 25,
  show3DEffects: true,
  soundscapeAutoplay: false,
  soundscapeDefaultMode: 'fireplace',
  soundscapeVolume: 0.4,
};

export const storageService = {
  getBooks(): Book[] {
    const raw = localStorage.getItem(STORAGE_KEYS.BOOKS);
    if (!raw) {
      localStorage.setItem(STORAGE_KEYS.BOOKS, JSON.stringify(initialBooks));
      return initialBooks;
    }
    try {
      return JSON.parse(raw);
    } catch {
      return initialBooks;
    }
  },

  saveBooks(books: Book[]) {
    localStorage.setItem(STORAGE_KEYS.BOOKS, JSON.stringify(books));
  },

  getQuotes(): Quote[] {
    const raw = localStorage.getItem(STORAGE_KEYS.QUOTES);
    if (!raw) {
      localStorage.setItem(STORAGE_KEYS.QUOTES, JSON.stringify(initialQuotes));
      return initialQuotes;
    }
    try {
      return JSON.parse(raw);
    } catch {
      return initialQuotes;
    }
  },

  saveQuotes(quotes: Quote[]) {
    localStorage.setItem(STORAGE_KEYS.QUOTES, JSON.stringify(quotes));
  },

  getNotes(): Note[] {
    const raw = localStorage.getItem(STORAGE_KEYS.NOTES);
    if (!raw) {
      localStorage.setItem(STORAGE_KEYS.NOTES, JSON.stringify(initialNotes));
      return initialNotes;
    }
    try {
      return JSON.parse(raw);
    } catch {
      return initialNotes;
    }
  },

  saveNotes(notes: Note[]) {
    localStorage.setItem(STORAGE_KEYS.NOTES, JSON.stringify(notes));
  },

  getGoal(): Goal {
    const raw = localStorage.getItem(STORAGE_KEYS.GOAL);
    if (!raw) {
      localStorage.setItem(STORAGE_KEYS.GOAL, JSON.stringify(initialGoal));
      return initialGoal;
    }
    try {
      return JSON.parse(raw);
    } catch {
      return initialGoal;
    }
  },

  saveGoal(goal: Goal) {
    localStorage.setItem(STORAGE_KEYS.GOAL, JSON.stringify(goal));
  },

  getSheetsUrl(): string {
    return localStorage.getItem(STORAGE_KEYS.SHEETS_URL) || '';
  },

  saveSheetsUrl(url: string) {
    localStorage.setItem(STORAGE_KEYS.SHEETS_URL, url);
  },

  getAppIcon(): string {
    return localStorage.getItem(STORAGE_KEYS.APP_ICON) || 'emerald';
  },

  saveAppIcon(iconId: string) {
    localStorage.setItem(STORAGE_KEYS.APP_ICON, iconId);
  },

  getPersonalization(): UserPersonalization {
    const raw = localStorage.getItem(STORAGE_KEYS.PERSONALIZATION);
    if (!raw) return defaultPersonalization;
    try {
      return { ...defaultPersonalization, ...JSON.parse(raw) };
    } catch {
      return defaultPersonalization;
    }
  },

  savePersonalization(settings: UserPersonalization) {
    localStorage.setItem(STORAGE_KEYS.PERSONALIZATION, JSON.stringify(settings));
    if (settings.appIcon) {
      this.saveAppIcon(settings.appIcon);
    }
  },

  exportMarkdown(books: Book[], quotes: Quote[], notes: Note[]): string {
    let md = `# 📚 Книжный Рай — Экспорт Библиотеки (Obsidian / Notion)\n\n`;
    md += `*Экспортировано: ${new Date().toLocaleString('ru-RU')}*\n\n`;
    md += `## Статистика\n- Всего книг: ${books.length}\n- Прочитано: ${books.filter(b => b.isFinished).length}\n- Цитат: ${quotes.length}\n- Заметок: ${notes.length}\n\n---\n\n`;

    md += `## 📖 Каталог книг\n\n`;
    for (const b of books) {
      const status = b.isFinished ? '✅ Прочитано' : b.readPages > 0 ? '📖 В процессе' : '⏳ В планах';
      md += `### ${b.title}\n`;
      md += `- **Автор:** ${b.author}\n`;
      md += `- **Жанр:** ${b.genre}\n`;
      md += `- **Статус:** ${status} (${b.readPages}/${b.totalPages} стр.)\n`;
      if (b.rating > 0) md += `- **Оценка:** ${'★'.repeat(b.rating)}${'☆'.repeat(5 - b.rating)}\n`;
      if (b.finishDate) md += `- **Дата завершения:** ${b.finishDate}\n`;
      md += `\n`;
    }

    if (quotes.length > 0) {
      md += `---\n\n## 💬 Цитатник\n\n`;
      for (const q of quotes) {
        md += `> ${q.text}\n\n`;
        md += `*— ${q.author}, «${q.bookTitle}»${q.page ? ` (стр. ${q.page})` : ''}*\n\n`;
      }
    }

    if (notes.length > 0) {
      md += `---\n\n## 📝 Дневник заметок\n\n`;
      for (const n of notes) {
        md += `### ${n.title}\n`;
        if (n.bookTitle) md += `*Книга: ${n.bookTitle}* | *${n.updatedAt}*\n\n`;
        md += `${n.content}\n\n`;
      }
    }

    return md;
  },

  downloadFile(content: string, filename: string, type: string) {
    const blob = new Blob([content], { type });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  }
};
