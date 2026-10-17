import React, { useState, useEffect } from 'react';
import { Book, NavigationTab } from '../types';
import { Search, BookOpen, Plus, Flame, FileText, Settings, ArrowRight } from 'lucide-react';

interface CommandPaletteProps {
  isOpen: boolean;
  onClose: () => void;
  books: Book[];
  onSelectBook: (book: Book) => void;
  onNavigate: (tab: NavigationTab) => void;
  onOpenAddModal: () => void;
  onToggleSoundscape: () => void;
  onOpenSettings: () => void;
}

export const CommandPalette: React.FC<CommandPaletteProps> = ({
  isOpen,
  onClose,
  books,
  onSelectBook,
  onNavigate,
  onOpenAddModal,
  onToggleSoundscape,
  onOpenSettings,
}) => {
  const [query, setQuery] = useState('');

  useEffect(() => {
    if (!isOpen) {
      setQuery('');
      return;
    }

    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        e.preventDefault();
        onClose();
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  const filteredBooks = books.filter(
    (b) =>
      b.title.toLowerCase().includes(query.toLowerCase()) ||
      b.author.toLowerCase().includes(query.toLowerCase()) ||
      b.genre.toLowerCase().includes(query.toLowerCase())
  ).slice(0, 5);

  const actions = [
    {
      id: 'add_book',
      title: 'Добавить новую книгу...',
      icon: Plus,
      category: 'Действие',
      perform: () => {
        onOpenAddModal();
        onClose();
      },
    },
    {
      id: 'goto_challenge',
      title: 'Открыть Книжный вызов 2026',
      icon: ArrowRight,
      category: 'Навигация',
      perform: () => {
        onNavigate('challenge');
        onClose();
      },
    },
    {
      id: 'goto_notes',
      title: 'Открыть Дневник заметок и цитат',
      icon: FileText,
      category: 'Навигация',
      perform: () => {
        onNavigate('notes');
        onClose();
      },
    },
    {
      id: 'toggle_soundscape',
      title: 'Переключить атмосферный звук (Камин / Дождь)',
      icon: Flame,
      category: 'Звук',
      perform: () => {
        onToggleSoundscape();
        onClose();
      },
    },
    {
      id: 'settings',
      title: 'Настройки и экспорт в Markdown',
      icon: Settings,
      category: 'Система',
      perform: () => {
        onOpenSettings();
        onClose();
      },
    },
  ];

  return (
    <div
      className="fixed inset-0 z-50 flex items-start justify-center pt-24 bg-black/60 backdrop-blur-md animate-in fade-in duration-100"
      onClick={onClose}
    >
      <div
        className="w-full max-w-xl bg-[#1c1c24] border border-white/10 rounded-2xl shadow-mac-modal overflow-hidden flex flex-col animate-in zoom-in-95 duration-150"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Поле поиска */}
        <div className="flex items-center px-4 py-3.5 border-b border-white/10 bg-[#22222c]">
          <Search className="w-5 h-5 text-neutral-400 mr-3 shrink-0" />
          <input
            type="text"
            autoFocus
            placeholder="Поиск книг, авторов или команд (⌘K)..."
            value={query}
            onChange={(e) => {
              setQuery(e.target.value);
            }}
            className="w-full bg-transparent text-white placeholder-neutral-500 text-sm focus:outline-none"
          />
          <kbd className="px-2 py-0.5 text-xs text-neutral-400 bg-white/10 rounded border border-white/10 font-mono">
            Esc
          </kbd>
        </div>

        {/* Результаты поиска */}
        <div className="max-h-80 overflow-y-auto p-2 space-y-1">
          {/* Секция: Книги */}
          {filteredBooks.length > 0 && (
            <div className="mb-2">
              <span className="px-3 py-1 text-[11px] font-semibold text-neutral-500 uppercase tracking-wider block">
                Книги ({filteredBooks.length})
              </span>
              {filteredBooks.map((book) => (
                <button
                  key={book.id}
                  type="button"
                  onClick={() => {
                    onSelectBook(book);
                    onClose();
                  }}
                  className="w-full flex items-center justify-between px-3 py-2 rounded-xl text-left hover:bg-emerald-500/15 hover:text-white group transition-colors cursor-pointer"
                >
                  <div className="flex items-center gap-3">
                    <BookOpen className="w-4 h-4 text-emerald-400" />
                    <div>
                      <span className="text-sm font-medium text-white block group-hover:text-emerald-300">
                        {book.title}
                      </span>
                      <span className="text-xs text-neutral-400">
                        {book.author} • {book.readPages}/{book.totalPages} стр.
                      </span>
                    </div>
                  </div>
                  <span className="text-xs text-neutral-500 group-hover:text-emerald-400">
                    {book.isFinished ? 'Прочитана' : `${Math.round((book.readPages / book.totalPages) * 100)}%`}
                  </span>
                </button>
              ))}
            </div>
          )}

          {/* Секция: Быстрые действия */}
          <div>
            <span className="px-3 py-1 text-[11px] font-semibold text-neutral-500 uppercase tracking-wider block">
              Быстрые команды
            </span>
            {actions.map((act) => {
              const IconComp = act.icon;
              return (
                <button
                  key={act.id}
                  type="button"
                  onClick={act.perform}
                  className="w-full flex items-center justify-between px-3 py-2 rounded-xl text-left hover:bg-white/10 hover:text-white group transition-colors cursor-pointer"
                >
                  <div className="flex items-center gap-3">
                    <IconComp className="w-4 h-4 text-neutral-400 group-hover:text-white" />
                    <span className="text-sm font-medium text-neutral-200 group-hover:text-white">
                      {act.title}
                    </span>
                  </div>
                  <span className="text-[11px] px-2 py-0.5 rounded bg-white/5 text-neutral-400 border border-white/5">
                    {act.category}
                  </span>
                </button>
              );
            })}
          </div>
        </div>

        {/* Футер */}
        <div className="px-4 py-2 border-t border-white/10 bg-[#16161c] flex items-center justify-between text-[11px] text-neutral-500">
          <span>Нажмите Enter для выбора</span>
          <span>Нажмите Esc для выхода</span>
        </div>
      </div>
    </div>
  );
};
