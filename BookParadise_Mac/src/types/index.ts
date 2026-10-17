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

export type AppIconId = 'emerald' | 'wine' | 'midnight' | 'cyberpunk' | 'parchment' | 'dark';

export type AppThemeId = 'emerald' | 'wine' | 'midnight' | 'amber' | 'cyberpunk' | 'dark' | 'autoDayNight';

export type FontFamilyPreference = 'sans' | 'serif' | 'mono' | 'rounded';

export type FontSizePreference = 'compact' | 'normal' | 'comfortable' | 'large';

export type CardStylePreference = '3d' | 'bento' | 'minimal';

export interface UserPersonalization {
  theme: AppThemeId;
  appIcon: AppIconId;
  fontFamily: FontFamilyPreference;
  fontSize: FontSizePreference;
  cardStyle: CardStylePreference;
  kindleEmail: string;
  dailyGoalMinutes: number;
  timerSprintMinutes: number;
  show3DEffects: boolean;
  soundscapeAutoplay: boolean;
  soundscapeDefaultMode: 'fireplace' | 'rain' | 'library' | 'cafe';
  soundscapeVolume: number;
}
