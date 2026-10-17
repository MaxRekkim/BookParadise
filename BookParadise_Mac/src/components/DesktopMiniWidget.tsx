import React, { useState } from 'react';
import { Book, Goal } from '../types';
import { BookOpen, Flame, X, ChevronDown, ChevronUp, Share2 } from 'lucide-react';

interface DesktopMiniWidgetProps {
  currentBook: Book | null;
  goal: Goal;
  finishedCount: number;
  soundscapeActive: boolean;
  onToggleSoundscape: () => void;
  onQuickAddPages: (bookId: string, pages: number) => void;
  onOpenBookDetail: (book: Book) => void;
  onOpenShareCard: (book: Book) => void;
}

export const DesktopMiniWidget: React.FC<DesktopMiniWidgetProps> = ({
  currentBook,
  goal,
  finishedCount,
  soundscapeActive,
  onToggleSoundscape,
  onQuickAddPages,
  onOpenBookDetail,
  onOpenShareCard,
}) => {
  const [isOpen, setIsOpen] = useState(true);
  const [isMinimized, setIsMinimized] = useState(false);

  if (!isOpen) {
    return (
      <button
        type="button"
        onClick={() => setIsOpen(true)}
        className="fixed bottom-4 right-4 z-40 flex items-center gap-2 px-3 py-2 rounded-full bg-[#181822]/90 backdrop-blur-md border border-white/15 text-xs text-emerald-400 hover:text-white shadow-xl hover:border-emerald-500/40 transition-all cursor-pointer animate-in fade-in"
        title="Развернуть компактный виджет чтения"
      >
        <BookOpen className="w-3.5 h-3.5 text-emerald-400" />
        <span className="font-semibold">Виджет</span>
      </button>
    );
  }

  const progress = currentBook
    ? Math.min(100, Math.round((currentBook.readPages / Math.max(1, currentBook.totalPages)) * 100))
    : 0;

  const goalPercent = Math.min(100, Math.round((finishedCount / Math.max(1, goal.targetBooks)) * 100));

  return (
    <aside
      aria-label="Мини-виджет рабочего стола"
      className="fixed bottom-4 right-4 z-40 w-80 rounded-2xl bg-[#181822]/95 backdrop-blur-xl border border-white/15 shadow-2xl shadow-black/80 overflow-hidden transition-all duration-300 animate-in slide-in-from-bottom-3"
    >
      {/* Шапка виджета */}
      <div className="h-8 px-3 bg-white/[0.04] border-b border-white/10 flex items-center justify-between select-none">
        <div className="flex items-center gap-1.5 text-[11px] font-bold text-neutral-300">
          <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />
          <span>Мини-виджет чтения</span>
        </div>
        <div className="flex items-center gap-1">
          <button
            type="button"
            onClick={() => setIsMinimized((prev) => !prev)}
            className="p-1 text-neutral-400 hover:text-white rounded transition-colors cursor-pointer"
            title={isMinimized ? 'Развернуть' : 'Свернуть'}
          >
            {isMinimized ? <ChevronUp className="w-3.5 h-3.5" /> : <ChevronDown className="w-3.5 h-3.5" />}
          </button>
          <button
            type="button"
            onClick={() => setIsOpen(false)}
            className="p-1 text-neutral-400 hover:text-rose-400 rounded transition-colors cursor-pointer"
            title="Закрыть виджет"
          >
            <X className="w-3.5 h-3.5" />
          </button>
        </div>
      </div>

      {/* Содержимое виджета */}
      {!isMinimized ? (
        <div className="p-3.5 space-y-3">
          {currentBook ? (
            <div className="space-y-2.5">
              <div className="flex gap-2.5 items-center">
                <div
                  onClick={() => onOpenBookDetail(currentBook)}
                  className="w-10 h-14 rounded-md bg-neutral-800 overflow-hidden shrink-0 border border-white/10 cursor-pointer hover:scale-105 transition-transform"
                >
                  {currentBook.coverURL ? (
                    <img src={currentBook.coverURL} alt={currentBook.title} className="w-full h-full object-cover" />
                  ) : (
                    <div className="w-full h-full flex items-center justify-center text-emerald-400 bg-neutral-900">
                      <BookOpen className="w-4 h-4" />
                    </div>
                  )}
                </div>

                <div className="flex-1 min-w-0">
                  <h4
                    onClick={() => onOpenBookDetail(currentBook)}
                    className="text-xs font-bold text-white hover:text-emerald-400 transition-colors truncate cursor-pointer"
                  >
                    {currentBook.title}
                  </h4>
                  <p className="text-[10px] text-neutral-400 truncate">{currentBook.author}</p>
                  <div className="flex items-center justify-between text-[10px] text-neutral-400 mt-1">
                    <span>{currentBook.readPages} из {currentBook.totalPages} стр.</span>
                    <span className="font-bold text-emerald-400">{progress}%</span>
                  </div>
                </div>
              </div>

              {/* Прогресс бар */}
              <div className="w-full h-1.5 bg-neutral-800 rounded-full overflow-hidden">
                <div
                  className="h-full bg-gradient-to-r from-emerald-500 to-teal-400 rounded-full transition-all duration-300"
                  style={{ width: `${progress}%` }}
                />
              </div>

              {/* Быстрые действия */}
              <div className="flex items-center justify-between pt-1">
                <div className="flex items-center gap-1">
                  <button
                    type="button"
                    onClick={() => onQuickAddPages(currentBook.id, 5)}
                    className="px-2 py-0.5 text-[10px] font-semibold rounded bg-white/5 hover:bg-emerald-500/20 text-neutral-300 hover:text-emerald-300 border border-white/5 transition-all cursor-pointer"
                  >
                    +5 стр.
                  </button>
                  <button
                    type="button"
                    onClick={() => onQuickAddPages(currentBook.id, 10)}
                    className="px-2 py-0.5 text-[10px] font-semibold rounded bg-white/5 hover:bg-emerald-500/20 text-neutral-300 hover:text-emerald-300 border border-white/5 transition-all cursor-pointer"
                  >
                    +10 стр.
                  </button>
                </div>

                <div className="flex items-center gap-1">
                  <button
                    type="button"
                    onClick={() => onOpenShareCard(currentBook)}
                    className="p-1.5 text-neutral-400 hover:text-emerald-300 hover:bg-white/5 rounded-md transition-colors cursor-pointer"
                    title="Spotify Карточка"
                  >
                    <Share2 className="w-3.5 h-3.5" />
                  </button>
                  <button
                    type="button"
                    onClick={onToggleSoundscape}
                    className={`p-1.5 rounded-md transition-colors cursor-pointer ${
                      soundscapeActive
                        ? 'text-amber-400 bg-amber-500/20'
                        : 'text-neutral-400 hover:text-white hover:bg-white/5'
                    }`}
                    title="Звуковая атмосфера"
                  >
                    <Flame className="w-3.5 h-3.5" />
                  </button>
                </div>
              </div>
            </div>
          ) : (
            <div className="text-center py-2 text-xs text-neutral-400">
              <p>Нет активной книги</p>
            </div>
          )}

          {/* Строка цели года */}
          <div className="pt-2 border-t border-white/10 flex items-center justify-between text-[10px]">
            <span className="text-neutral-400">Вызов {goal.year}:</span>
            <span className="font-bold text-white">
              {finishedCount} / {goal.targetBooks} книг ({goalPercent}%)
            </span>
          </div>
        </div>
      ) : (
        /* Свернутое состояние */
        <div className="px-3 py-2 flex items-center justify-between text-xs">
          <div className="flex items-center gap-2 truncate">
            <span className="text-emerald-400 font-bold">{progress}%</span>
            <span className="text-neutral-300 truncate font-medium">
              {currentBook ? currentBook.title : 'Книжный Рай'}
            </span>
          </div>
          {currentBook && (
            <button
              type="button"
              onClick={() => onQuickAddPages(currentBook.id, 5)}
              className="text-[10px] font-bold text-emerald-400 hover:underline shrink-0 ml-2"
            >
              +5 стр.
            </button>
          )}
        </div>
      )}
    </aside>
  );
};
