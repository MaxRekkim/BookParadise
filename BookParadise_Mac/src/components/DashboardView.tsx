import React, { useState } from 'react';
import { Book, Goal, Quote } from '../types';
import { ChevronDown, ChevronUp, Plus, Minus, BookOpen, Star, Quote as QuoteIcon, ArrowUpRight, Flame, Sparkles } from 'lucide-react';

interface DashboardViewProps {
  books: Book[];
  goal: Goal;
  quotes: Quote[];
  onSelectBook: (book: Book) => void;
  onUpdateGoal: (newGoal: Goal) => void;
  onQuickAddPages: (bookId: string, pagesToAdd: number) => void;
  onNavigateToChallenge: () => void;
}

export const DashboardView: React.FC<DashboardViewProps> = ({
  books,
  goal,
  quotes,
  onSelectBook,
  onUpdateGoal,
  onQuickAddPages,
  onNavigateToChallenge,
}) => {
  const [isFinishedListExpanded, setIsFinishedListExpanded] = useState(false);

  const inProgressBooks = books.filter((b) => b.readPages > 0 && !b.isFinished);
  const finishedBooks = books.filter((b) => b.isFinished);
  const totalPagesRead = books.reduce((sum, b) => sum + b.readPages, 0);

  const goalPercent = Math.min(100, Math.round((finishedBooks.length / Math.max(1, goal.targetBooks)) * 100));

  // Случайная или первая цитата дня
  const quoteOfTheDay = quotes.length > 0 ? quotes[0] : null;

  return (
    <div className="max-w-6xl mx-auto space-y-8 animate-in fade-in duration-200">
      {/* Приветствие */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold text-white tracking-tight flex items-center gap-2">
            <span>Добрый день! Что читаем сегодня?</span>
            <Sparkles className="w-5 h-5 text-emerald-400" />
          </h2>
          <p className="text-xs text-neutral-400 mt-1">
            Ваш личный прогресс чтения, книжные цели и вдохновение
          </p>
        </div>

        {/* Быстрая статистика */}
        <div className="flex items-center gap-3">
          <div className="px-4 py-2 rounded-xl bg-white/[0.03] border border-white/10 flex items-center gap-2.5">
            <Flame className="w-4 h-4 text-amber-400" />
            <div>
              <span className="text-[10px] text-neutral-400 block font-medium">Прочитано страниц</span>
              <span className="text-sm font-bold text-white">{totalPagesRead.toLocaleString()}</span>
            </div>
          </div>
          <div className="px-4 py-2 rounded-xl bg-white/[0.03] border border-white/10 flex items-center gap-2.5">
            <BookOpen className="w-4 h-4 text-emerald-400" />
            <div>
              <span className="text-[10px] text-neutral-400 block font-medium">Книг завершено</span>
              <span className="text-sm font-bold text-white">{finishedBooks.length} из {goal.targetBooks}</span>
            </div>
          </div>
        </div>
      </div>

      {/* Bento Grid: Верхний ряд (Цель года + Цитата дня) */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {/* Карточка 1: Интерактивная Цель Года (занимает 2 колонки) */}
        <div className="md:col-span-2 p-6 rounded-2xl bg-gradient-to-br from-[#1c1c24] to-[#16161c] border border-white/10 shadow-mac-card transition-all duration-200">
          <div className="flex items-start justify-between">
            <div className="flex items-center gap-4">
              {/* Круговой индикатор SVG */}
              <div className="relative w-20 h-20 shrink-0">
                <svg className="w-full h-full transform -rotate-90" viewBox="0 0 36 36">
                  <path
                    className="text-neutral-800"
                    strokeWidth="3.5"
                    stroke="currentColor"
                    fill="none"
                    d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                  />
                  <path
                    className="text-emerald-400 transition-all duration-500"
                    strokeDasharray={`${goalPercent}, 100`}
                    strokeWidth="3.5"
                    strokeLinecap="round"
                    stroke="currentColor"
                    fill="none"
                    d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                  />
                </svg>
                <div className="absolute inset-0 flex flex-col items-center justify-center">
                  <span className="text-sm font-bold text-white">{goalPercent}%</span>
                </div>
              </div>

              <div>
                <div className="flex items-center gap-2">
                  <h3 className="text-base font-bold text-white">Книжный вызов 2026</h3>
                  <button
                    type="button"
                    onClick={onNavigateToChallenge}
                    className="p-1 text-neutral-400 hover:text-emerald-400 transition-colors"
                    title="Перейти в подробный отчет вызова"
                  >
                    <ArrowUpRight className="w-4 h-4" />
                  </button>
                </div>
                <p className="text-xs text-neutral-400 mt-0.5">
                  Прочитано {finishedBooks.length} из {goal.targetBooks} книг в этом году
                </p>

                {/* Управление шагом цели (шаг 1 книга!) */}
                <div className="flex items-center gap-2 mt-3">
                  <span className="text-xs text-neutral-500">Цель:</span>
                  <div className="flex items-center gap-1 bg-black/40 border border-white/10 rounded-lg p-0.5">
                    <button
                      type="button"
                      onClick={() => onUpdateGoal({ ...goal, targetBooks: Math.max(1, goal.targetBooks - 1) })}
                      className="p-1 text-neutral-400 hover:text-white rounded hover:bg-white/10 transition-colors"
                      title="Уменьшить цель на 1 книгу"
                    >
                      <Minus className="w-3 h-3" />
                    </button>
                    <span className="text-xs font-semibold px-2 text-white">{goal.targetBooks}</span>
                    <button
                      type="button"
                      onClick={() => onUpdateGoal({ ...goal, targetBooks: goal.targetBooks + 1 })}
                      className="p-1 text-neutral-400 hover:text-white rounded hover:bg-white/10 transition-colors"
                      title="Увеличить цель на 1 книгу"
                    >
                      <Plus className="w-3 h-3" />
                    </button>
                  </div>
                </div>
              </div>
            </div>

            {/* Кнопка раскрытия прочитанных книг прямо в виджете */}
            {finishedBooks.length > 0 && (
              <button
                type="button"
                onClick={() => setIsFinishedListExpanded(!isFinishedListExpanded)}
                className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-medium text-emerald-400 bg-emerald-500/10 hover:bg-emerald-500/20 border border-emerald-500/20 transition-all cursor-pointer"
              >
                <span>Прочитано ({finishedBooks.length})</span>
                {isFinishedListExpanded ? <ChevronUp className="w-3.5 h-3.5" /> : <ChevronDown className="w-3.5 h-3.5" />}
              </button>
            )}
          </div>

          {/* Раскрывающийся список прочитанных книг */}
          {isFinishedListExpanded && (
            <div className="mt-5 pt-4 border-t border-white/10 space-y-2 animate-in slide-in-from-top-2 duration-150">
              <span className="text-xs font-semibold text-neutral-400 block mb-2">
                Завершенные книги (кликните для деталей):
              </span>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 max-h-48 overflow-y-auto pr-1">
                {finishedBooks.map((b) => (
                  <button
                    key={b.id}
                    type="button"
                    onClick={() => onSelectBook(b)}
                    className="flex items-center gap-3 p-2.5 rounded-xl bg-white/[0.02] hover:bg-emerald-500/10 border border-white/5 hover:border-emerald-500/30 text-left transition-all group cursor-pointer"
                  >
                    <div className="w-8 h-11 rounded bg-neutral-800 overflow-hidden shrink-0 border border-white/10">
                      {b.coverURL ? (
                        <img src={b.coverURL} alt={b.title} className="w-full h-full object-cover" />
                      ) : (
                        <div className="w-full h-full flex items-center justify-center text-emerald-500">
                          <BookOpen className="w-4 h-4" />
                        </div>
                      )}
                    </div>
                    <div className="flex-1 min-w-0">
                      <span className="text-xs font-semibold text-white truncate block group-hover:text-emerald-300">
                        {b.title}
                      </span>
                      <span className="text-[11px] text-neutral-400 truncate block">
                        {b.author} • {b.finishDate || '2026'}
                      </span>
                    </div>
                    {b.rating > 0 && (
                      <div className="flex items-center text-amber-400 text-xs shrink-0">
                        <Star className="w-3 h-3 fill-amber-400" />
                        <span className="ml-1 font-bold">{b.rating}</span>
                      </div>
                    )}
                  </button>
                ))}
              </div>
            </div>
          )}
        </div>

        {/* Карточка 2: Цитата дня */}
        <div className="p-6 rounded-2xl bg-gradient-to-br from-[#1c1c24] to-[#16161c] border border-white/10 shadow-mac-card flex flex-col justify-between">
          <div>
            <div className="flex items-center gap-2 mb-3">
              <QuoteIcon className="w-4 h-4 text-amber-400" />
              <h3 className="text-xs font-semibold text-amber-400 uppercase tracking-wider">Цитата дня</h3>
            </div>
            {quoteOfTheDay ? (
              <blockquote className="text-sm text-neutral-200 italic leading-relaxed">
                «{quoteOfTheDay.text}»
              </blockquote>
            ) : (
              <p className="text-xs text-neutral-500">Добавьте свои любимые цитаты в библиотеку</p>
            )}
          </div>
          {quoteOfTheDay && (
            <div className="pt-4 border-t border-white/5 mt-4">
              <span className="text-xs font-semibold text-white block">{quoteOfTheDay.author}</span>
              <span className="text-[11px] text-neutral-400 block truncate">«{quoteOfTheDay.bookTitle}»</span>
            </div>
          )}
        </div>
      </div>

      {/* Секция: Книги в фокусе (Hot Reads) */}
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Flame className="w-5 h-5 text-amber-400" />
            <h3 className="text-lg font-bold text-white tracking-tight">Книги в фокусе чтения</h3>
          </div>
          <span className="text-xs text-neutral-400">
            {inProgressBooks.length} {inProgressBooks.length === 1 ? 'книга читается' : 'книги читаются'}
          </span>
        </div>

        {inProgressBooks.length > 0 ? (
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {inProgressBooks.map((book) => {
              const progress = Math.min(100, Math.round((book.readPages / Math.max(1, book.totalPages)) * 100));
              return (
                <div
                  key={book.id}
                  className="group relative p-5 rounded-2xl bg-gradient-to-br from-[#1e1e26] to-[#17171d] border border-white/10 shadow-mac-card hover:shadow-mac-card-hover hover:border-emerald-500/30 transition-all duration-200 flex flex-col justify-between"
                >
                  <div className="flex gap-4 cursor-pointer" onClick={() => onSelectBook(book)}>
                    {/* Обложка с эффектом увеличения при наведении */}
                    <div className="w-16 h-24 rounded-lg bg-neutral-800 overflow-hidden shadow-md shrink-0 border border-white/10 group-hover:scale-105 transition-transform duration-200">
                      {book.coverURL ? (
                        <img src={book.coverURL} alt={book.title} className="w-full h-full object-cover" />
                      ) : (
                        <div className="w-full h-full flex items-center justify-center text-emerald-500 bg-neutral-900">
                          <BookOpen className="w-6 h-6" />
                        </div>
                      )}
                    </div>

                    {/* Информация */}
                    <div className="flex-1 min-w-0">
                      <h4 className="text-sm font-bold text-white group-hover:text-emerald-400 transition-colors line-clamp-2">
                        {book.title}
                      </h4>
                      <p className="text-xs text-neutral-400 mt-0.5 truncate">{book.author}</p>
                      <span className="inline-block mt-2 text-[10px] px-2 py-0.5 rounded bg-white/5 text-neutral-300 border border-white/5">
                        {book.genre}
                      </span>
                    </div>
                  </div>

                  {/* Прогресс-бар капсульный без текстурных артефактов */}
                  <div className="mt-5 space-y-2">
                    <div className="flex justify-between text-xs">
                      <span className="text-neutral-400">{book.readPages} из {book.totalPages} стр.</span>
                      <span className="font-bold text-emerald-400">{progress}%</span>
                    </div>
                    <div className="w-full h-2 bg-neutral-800 rounded-full overflow-hidden border border-white/5">
                      <div
                        className="h-full bg-gradient-to-r from-emerald-500 to-teal-400 rounded-full transition-all duration-300"
                        style={{ width: `${progress}%` }}
                      />
                    </div>

                    {/* Кнопки быстрой записи страниц (+10, +25) */}
                    <div className="pt-2 flex items-center justify-between">
                      <span className="text-[10px] text-neutral-500">Быстрая запись:</span>
                      <div className="flex gap-1.5">
                        <button
                          type="button"
                          onClick={() => onQuickAddPages(book.id, 10)}
                          className="px-2 py-1 text-[11px] font-semibold rounded bg-white/5 hover:bg-emerald-500/20 hover:text-emerald-300 text-neutral-300 transition-colors cursor-pointer"
                        >
                          +10 стр.
                        </button>
                        <button
                          type="button"
                          onClick={() => onQuickAddPages(book.id, 25)}
                          className="px-2 py-1 text-[11px] font-semibold rounded bg-white/5 hover:bg-emerald-500/20 hover:text-emerald-300 text-neutral-300 transition-colors cursor-pointer"
                        >
                          +25 стр.
                        </button>
                      </div>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        ) : (
          <div className="p-8 rounded-2xl bg-white/[0.02] border border-dashed border-white/10 text-center">
            <BookOpen className="w-10 h-10 text-neutral-600 mx-auto mb-2" />
            <p className="text-sm text-neutral-400">Сейчас нет книг в процессе чтения</p>
            <p className="text-xs text-neutral-500 mt-1">Откройте библиотеку и выберите книгу для старта!</p>
          </div>
        )}
      </div>
    </div>
  );
};
