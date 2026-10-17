export interface Book {
  id: string;
  title: string;
  author: string;
  genre: string;
  year?: number;
  totalPages: number;
  readPages: number;
  rating: number; // 0 - 5
  isFinished: boolean;
  coverURL?: string;
  startDate?: string;
  finishDate?: string;
  notesCount?: number;
  quotesCount?: number;
  format?: 'Электронная' | 'Бумажная' | 'Аудио';
}

export interface Quote {
  id: string;
  bookId: string;
  bookTitle: string;
  author: string;
  text: string;
  page?: number;
  date: string;
  tags?: string[];
}

export interface Note {
  id: string;
  bookId?: string;
  bookTitle?: string;
  title: string;
  content: string;
  updatedAt: string;
  tags?: string[];
}

export interface Goal {
  year: number;
  targetBooks: number;
  targetPages: number;
}

export type NavigationTab = 'dashboard' | 'library' | 'challenge' | 'notes' | 'soundscape' | 'settings';
