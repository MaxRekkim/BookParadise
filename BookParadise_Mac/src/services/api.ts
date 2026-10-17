import { Book } from '../types';
import { storageService } from './storage';

export const DEFAULT_SHEETS_URL =
  'https://script.google.com/macros/s/AKfycbxfxFYCUW_A8dUXwm0ATVJDZMJyFxgMDmjT4ugMOnhAh9bYclpMFGG6eWpGLbxyI9ZVXw/exec';

interface RawBookResponse {
  id: number | string;
  title: string;
  author: string;
  genre?: string;
  year?: number;
  totalPages?: number;
  pagesRead?: number;
  readPages?: number;
  status?: string;
  isFinished?: boolean;
  coverURL?: string;
  coverUrl?: string;
  startDate?: string;
  endDate?: string;
  finishDate?: string;
  format?: string;
  rating?: number | { stars?: number } | string;
  notesCount?: number;
  quotesCount?: number;
}

interface ApiResponse {
  success?: boolean;
  books?: RawBookResponse[];
  bingo?: unknown[];
  stats?: unknown;
  error?: string;
}

export const apiService = {
  getEffectiveUrl(): string {
    const saved = storageService.getSheetsUrl();
    if (saved && saved.trim().startsWith('https://')) {
      return saved.trim();
    }
    // Используем сохраненный URL по умолчанию
    storageService.saveSheetsUrl(DEFAULT_SHEETS_URL);
    return DEFAULT_SHEETS_URL;
  },

  async fetchLibrary(): Promise<{ success: boolean; books: Book[]; count: number; error?: string }> {
    const url = this.getEffectiveUrl();
    if (!url) {
      return { success: false, books: [], count: 0, error: 'URL Google Таблицы не настроен' };
    }

    try {
      const response = await fetch(url, {
        method: 'GET',
        headers: {
          Accept: 'application/json',
        },
      });

      if (!response.ok) {
        throw new Error(`HTTP error ${response.status}`);
      }

      const json: ApiResponse = await response.json();
      if (!json.books || !Array.isArray(json.books)) {
        throw new Error(json.error || 'Неверный формат ответа от Google Таблицы');
      }

      const normalizedBooks: Book[] = json.books.map((b, idx) => {
        const totalPages = Number(b.totalPages) || 100;
        const readPages = Number(b.pagesRead ?? b.readPages ?? 0);
        const isFinished =
          b.status === 'Прочитано' ||
          Boolean(b.isFinished) ||
          (totalPages > 0 && readPages >= totalPages);

        let ratingNum = 0;
        if (typeof b.rating === 'number') {
          ratingNum = b.rating;
        } else if (typeof b.rating === 'object' && b.rating && 'stars' in b.rating) {
          ratingNum = Number(b.rating.stars) || 0;
        } else if (typeof b.rating === 'string') {
          ratingNum = b.rating.includes('★') ? b.rating.split('★').length - 1 : Number(b.rating) || 0;
        }

        let fmt: 'Электронная' | 'Бумажная' | 'Аудио' = 'Бумажная';
        if (b.format?.toLowerCase().includes('электр')) fmt = 'Электронная';
        else if (b.format?.toLowerCase().includes('аудио')) fmt = 'Аудио';

        return {
          id: String(b.id || `book_${idx + 1}`),
          title: b.title || 'Без названия',
          author: b.author || 'Неизвестный автор',
          genre: b.genre || 'Классика',
          year: b.year,
          totalPages,
          readPages,
          rating: Math.max(0, Math.min(5, ratingNum)),
          isFinished,
          coverURL: b.coverURL || b.coverUrl,
          startDate: b.startDate,
          finishDate: b.endDate || b.finishDate,
          format: fmt,
          notesCount: b.notesCount || 0,
          quotesCount: b.quotesCount || 0,
        };
      });

      // Сохраняем в кэш
      storageService.saveBooks(normalizedBooks);

      return {
        success: true,
        books: normalizedBooks,
        count: normalizedBooks.length,
      };
    } catch (err) {
      console.error('[BookParadise API] Sync error:', err);
      return {
        success: false,
        books: [],
        count: 0,
        error: err instanceof Error ? err.message : String(err),
      };
    }
  },
};
