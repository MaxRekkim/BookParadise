import { useState, useEffect } from 'react';
import { Book, Quote, Note, Goal, NavigationTab, AppIconId, UserPersonalization } from './types';
import { storageService } from './services/storage';
import { soundscape } from './services/soundscape';
import { Sidebar } from './components/Sidebar';
import { WindowFrame } from './components/WindowFrame';
import { DashboardView } from './components/DashboardView';
import { LibraryView } from './components/LibraryView';
import { ReadingChallengeView } from './components/ReadingChallengeView';
import { NotesStudioView } from './components/NotesStudioView';
import { SoundscapeView } from './components/SoundscapeView';
import { CommandPalette } from './components/CommandPalette';
import { BookDetailModal } from './components/Modals/BookDetailModal';
import { AddBookModal } from './components/Modals/AddBookModal';
import { SettingsModal } from './components/Modals/SettingsModal';
import { ShareCardModal } from './components/Modals/ShareCardModal';
import { DesktopMiniWidget } from './components/DesktopMiniWidget';

export function App() {
  // Основные данные приложения
  const [books, setBooks] = useState<Book[]>(() => storageService.getBooks());
  const [quotes, setQuotes] = useState<Quote[]>(() => storageService.getQuotes());
  const [notes, setNotes] = useState<Note[]>(() => storageService.getNotes());
  const [goal, setGoal] = useState<Goal>(() => storageService.getGoal());
  const [personalization, setPersonalization] = useState<UserPersonalization>(() =>
    storageService.getPersonalization()
  );
  const [appIcon, setAppIcon] = useState<AppIconId>(
    () => (storageService.getAppIcon() as AppIconId) || 'emerald'
  );

  // Навигация
  const [currentTab, setCurrentTab] = useState<NavigationTab>('dashboard');

  // Модальные окна
  const [selectedBook, setSelectedBook] = useState<Book | null>(null);
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [isSettingsModalOpen, setIsSettingsModalOpen] = useState(false);
  const [isCommandPaletteOpen, setIsCommandPaletteOpen] = useState(false);
  const [shareCardPayload, setShareCardPayload] = useState<{
    book?: Book | null;
    quote?: Quote | null;
    goal?: Goal | null;
  } | null>(null);

  // Звуковой ландшафт
  const [soundscapePlaying, setSoundscapePlaying] = useState(false);
  const [soundscapeMode, setSoundscapeMode] = useState<'fireplace' | 'rain' | 'library' | 'cafe' | null>(null);

  // Сохранение в LocalStorage при изменениях
  useEffect(() => {
    storageService.saveBooks(books);
  }, [books]);

  useEffect(() => {
    storageService.saveQuotes(quotes);
  }, [quotes]);

  useEffect(() => {
    storageService.saveNotes(notes);
  }, [notes]);

  useEffect(() => {
    storageService.saveGoal(goal);
  }, [goal]);

  // Применение темы, шрифта и размера ко всему интерфейсу приложения
  useEffect(() => {
    storageService.savePersonalization(personalization);
    if (personalization.appIcon !== appIcon) {
      setAppIcon(personalization.appIcon);
    }

    let effectiveTheme = personalization.theme;
    if (effectiveTheme === 'autoDayNight') {
      const hour = new Date().getHours();
      effectiveTheme = (hour >= 19 || hour < 7) ? 'midnight' : 'wine';
    }

    document.documentElement.setAttribute('data-theme', effectiveTheme);
    document.documentElement.setAttribute('data-font', personalization.fontFamily);
    document.documentElement.setAttribute('data-size', personalization.fontSize);
  }, [personalization]);

  // Динамическое обновление фавиконки приложения в соответствии с выбранной иконкой
  useEffect(() => {
    try {
      const canvas = document.createElement('canvas');
      canvas.width = 64;
      canvas.height = 64;
      const ctx = canvas.getContext('2d');
      if (ctx) {
        const grad = ctx.createLinearGradient(0, 0, 64, 64);
        if (appIcon === 'wine') {
          grad.addColorStop(0, '#9f1239');
          grad.addColorStop(1, '#4c0519');
        } else if (appIcon === 'midnight') {
          grad.addColorStop(0, '#4338ca');
          grad.addColorStop(1, '#1e1b4b');
        } else if (appIcon === 'cyberpunk') {
          grad.addColorStop(0, '#c026d3');
          grad.addColorStop(1, '#0891b2');
        } else if (appIcon === 'parchment') {
          grad.addColorStop(0, '#b45309');
          grad.addColorStop(1, '#451a03');
        } else if (appIcon === 'dark') {
          grad.addColorStop(0, '#404040');
          grad.addColorStop(1, '#0a0a0a');
        } else {
          grad.addColorStop(0, '#059669');
          grad.addColorStop(1, '#064e3b');
        }
        ctx.fillStyle = grad;
        ctx.beginPath();
        if (ctx.roundRect) {
          ctx.roundRect(0, 0, 64, 64, 16);
        } else {
          ctx.rect(0, 0, 64, 64);
        }
        ctx.fill();

        ctx.fillStyle = appIcon === 'wine' || appIcon === 'parchment' ? '#fbbf24' : '#ffffff';
        ctx.fillRect(24, 14, 16, 36);
        ctx.beginPath();
        ctx.moveTo(24, 50);
        ctx.lineTo(32, 42);
        ctx.lineTo(40, 50);
        ctx.fillStyle = grad;
        ctx.fill();

        const link = (document.querySelector("link[rel*='icon']") as HTMLLinkElement) || document.createElement('link');
        link.type = 'image/x-icon';
        link.rel = 'shortcut icon';
        link.href = canvas.toDataURL();
        document.getElementsByTagName('head')[0].appendChild(link);
      }
    } catch {
      // Ignore in non-browser context
    }
  }, [appIcon]);

  // Глобальные клавиатурные шорткаты macOS
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      const isMeta = e.metaKey || e.ctrlKey;

      // ⌘K - Command Palette
      if (isMeta && e.key.toLowerCase() === 'k') {
        e.preventDefault();
        setIsCommandPaletteOpen((prev) => !prev);
      }

      // ⌘1 .. ⌘5 - Переключение разделов
      if (isMeta && e.key === '1') {
        e.preventDefault();
        setCurrentTab('dashboard');
      } else if (isMeta && e.key === '2') {
        e.preventDefault();
        setCurrentTab('library');
      } else if (isMeta && e.key === '3') {
        e.preventDefault();
        setCurrentTab('challenge');
      } else if (isMeta && e.key === '4') {
        e.preventDefault();
        setCurrentTab('notes');
      } else if (isMeta && e.key === '5') {
        e.preventDefault();
        setCurrentTab('soundscape');
      } else if (isMeta && e.key === ',') {
        // ⌘, - Настройки
        e.preventDefault();
        setIsSettingsModalOpen(true);
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, []);

  // CRUD для книг
  const handleAddBook = (newBook: Book) => {
    setBooks((prev) => [newBook, ...prev]);
  };

  const handleUpdateBook = (updated: Book) => {
    setBooks((prev) => prev.map((b) => (b.id === updated.id ? updated : b)));
    setSelectedBook(updated);
  };

  const handleDeleteBook = (id: string) => {
    setBooks((prev) => prev.filter((b) => b.id !== id));
  };

  const handleQuickAddPages = (bookId: string, pagesToAdd: number) => {
    setBooks((prev) =>
      prev.map((b) => {
        if (b.id !== bookId) return b;
        const newRead = Math.min(b.totalPages, b.readPages + pagesToAdd);
        const finished = newRead >= b.totalPages;
        return {
          ...b,
          readPages: newRead,
          isFinished: finished,
          finishDate: finished && !b.finishDate ? new Date().toISOString().split('T')[0] : b.finishDate,
        };
      })
    );
  };

  // CRUD для цитат и заметок
  const handleAddQuote = (q: Quote) => setQuotes((prev) => [q, ...prev]);
  const handleDeleteQuote = (id: string) => setQuotes((prev) => prev.filter((q) => q.id !== id));

  const handleAddNote = (n: Note) => setNotes((prev) => [n, ...prev]);
  const handleDeleteNote = (id: string) => setNotes((prev) => prev.filter((n) => n.id !== id));

  // Звуковой ландшафт
  const handlePlaySoundscape = (mode: 'fireplace' | 'rain' | 'library' | 'cafe') => {
    soundscape.play(mode);
    setSoundscapePlaying(true);
    setSoundscapeMode(mode);
  };

  const handleStopSoundscape = () => {
    soundscape.stop();
    setSoundscapePlaying(false);
    setSoundscapeMode(null);
  };

  const handleToggleSoundscape = () => {
    if (soundscapePlaying) {
      handleStopSoundscape();
    } else {
      handlePlaySoundscape('fireplace');
    }
  };

  const inProgressCount = books.filter((b) => b.readPages > 0 && !b.isFinished).length;
  const finishedCount = books.filter((b) => b.isFinished).length;

  return (
    <div className="flex h-screen w-screen overflow-hidden bg-[#121216] text-white">
      {/* Боковой сайдбар macOS */}
      <Sidebar
        currentTab={currentTab}
        onSelectTab={(tab) => {
          if (tab === 'settings') {
            setIsSettingsModalOpen(true);
          } else {
            setCurrentTab(tab);
          }
        }}
        booksCount={books.length}
        readingCount={inProgressCount}
        finishedCount={finishedCount}
        onOpenAddModal={() => setIsAddModalOpen(true)}
        soundscapeActive={soundscapePlaying}
        appIcon={appIcon}
      />

      {/* Окно с нативным тайтлбаром и контентом */}
      <WindowFrame
        currentTab={currentTab}
        onOpenCommandPalette={() => setIsCommandPaletteOpen(true)}
        soundscapeActive={soundscapePlaying}
        onToggleSoundscape={handleToggleSoundscape}
      >
        {currentTab === 'dashboard' && (
          <DashboardView
            books={books}
            goal={goal}
            quotes={quotes}
            onSelectBook={(book) => setSelectedBook(book)}
            onUpdateGoal={setGoal}
            onQuickAddPages={handleQuickAddPages}
            onNavigateToChallenge={() => setCurrentTab('challenge')}
            onShareBook={(book) => setShareCardPayload({ book })}
            onShareQuote={(quote) => setShareCardPayload({ quote })}
          />
        )}

        {currentTab === 'library' && (
          <LibraryView
            books={books}
            onSelectBook={(book) => setSelectedBook(book)}
            onOpenAddModal={() => setIsAddModalOpen(true)}
          />
        )}

        {currentTab === 'challenge' && (
          <ReadingChallengeView
            books={books}
            goal={goal}
            onSelectBook={(book) => setSelectedBook(book)}
            onUpdateGoal={setGoal}
            onShareWrapped={() => setShareCardPayload({ goal })}
          />
        )}

        {currentTab === 'notes' && (
          <NotesStudioView
            quotes={quotes}
            notes={notes}
            onAddQuote={handleAddQuote}
            onAddNote={handleAddNote}
            onDeleteQuote={handleDeleteQuote}
            onDeleteNote={handleDeleteNote}
            onShareQuote={(quote) => setShareCardPayload({ quote })}
          />
        )}

        {currentTab === 'soundscape' && (
          <SoundscapeView
            activeMode={soundscapeMode}
            isPlaying={soundscapePlaying}
            onPlayMode={handlePlaySoundscape}
            onStop={handleStopSoundscape}
          />
        )}
      </WindowFrame>

      {/* Модальное окно деталей книги со слайдером до 10 000 страниц */}
      <BookDetailModal
        book={selectedBook}
        isOpen={Boolean(selectedBook)}
        onClose={() => setSelectedBook(null)}
        onUpdate={handleUpdateBook}
        onDelete={handleDeleteBook}
        onShare={(book) => setShareCardPayload({ book })}
      />

      {/* Модальное окно добавления книги */}
      <AddBookModal
        isOpen={isAddModalOpen}
        onClose={() => setIsAddModalOpen(false)}
        onAdd={handleAddBook}
      />

      {/* Модальное окно настроек и персонализации */}
      <SettingsModal
        isOpen={isSettingsModalOpen}
        onClose={() => setIsSettingsModalOpen(false)}
        books={books}
        quotes={quotes}
        notes={notes}
        goal={goal}
        onUpdateGoal={(newGoal) => setGoal(newGoal)}
        onImportBooks={(imported) => setBooks(imported)}
        personalization={personalization}
        onUpdatePersonalization={(updated) => setPersonalization(updated)}
        onPlaySoundscape={(mode) => {
          soundscape.play(mode, personalization.soundscapeVolume ?? 0.4);
          setSoundscapePlaying(true);
          setSoundscapeMode(mode);
        }}
        onStopSoundscape={() => {
          soundscape.stop();
          setSoundscapePlaying(false);
          setSoundscapeMode(null);
        }}
        soundscapePlaying={soundscapePlaying}
      />

      {/* Command Palette (⌘K) */}
      <CommandPalette
        isOpen={isCommandPaletteOpen}
        onClose={() => setIsCommandPaletteOpen(false)}
        books={books}
        onSelectBook={(b) => setSelectedBook(b)}
        onNavigate={(tab) => setCurrentTab(tab)}
        onOpenAddModal={() => setIsAddModalOpen(true)}
        onToggleSoundscape={handleToggleSoundscape}
        onOpenSettings={() => setIsSettingsModalOpen(true)}
      />

      {/* Модальное окно генератора Spotify Share Cards */}
      <ShareCardModal
        isOpen={Boolean(shareCardPayload)}
        onClose={() => setShareCardPayload(null)}
        book={shareCardPayload?.book}
        quote={shareCardPayload?.quote}
        goal={shareCardPayload?.goal}
        books={books}
      />

      {/* Плавающий настольный мини-виджет чтения */}
      <DesktopMiniWidget
        currentBook={books.find((b) => b.readPages > 0 && !b.isFinished) || books[0] || null}
        goal={goal}
        finishedCount={finishedCount}
        soundscapeActive={soundscapePlaying}
        onToggleSoundscape={handleToggleSoundscape}
        onQuickAddPages={handleQuickAddPages}
        onOpenBookDetail={(b) => setSelectedBook(b)}
        onOpenShareCard={(b) => setShareCardPayload({ book: b })}
      />
    </div>
  );
}

export default App;
