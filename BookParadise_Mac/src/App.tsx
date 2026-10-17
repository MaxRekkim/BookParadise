import { useState, useEffect } from 'react';
import { Book, Quote, Note, Goal, NavigationTab } from './types';
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

export function App() {
  // Основные данные приложения
  const [books, setBooks] = useState<Book[]>(() => storageService.getBooks());
  const [quotes, setQuotes] = useState<Quote[]>(() => storageService.getQuotes());
  const [notes, setNotes] = useState<Note[]>(() => storageService.getNotes());
  const [goal, setGoal] = useState<Goal>(() => storageService.getGoal());

  // Навигация
  const [currentTab, setCurrentTab] = useState<NavigationTab>('dashboard');

  // Модальные окна
  const [selectedBook, setSelectedBook] = useState<Book | null>(null);
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [isSettingsModalOpen, setIsSettingsModalOpen] = useState(false);
  const [isCommandPaletteOpen, setIsCommandPaletteOpen] = useState(false);

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
      />

      {/* Модальное окно добавления книги */}
      <AddBookModal
        isOpen={isAddModalOpen}
        onClose={() => setIsAddModalOpen(false)}
        onAdd={handleAddBook}
      />

      {/* Модальное окно настроек */}
      <SettingsModal
        isOpen={isSettingsModalOpen}
        onClose={() => setIsSettingsModalOpen(false)}
        books={books}
        quotes={quotes}
        notes={notes}
        onImportBooks={(imported) => setBooks(imported)}
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
    </div>
  );
}

export default App;
