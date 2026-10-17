import React from 'react';
import { Book, Goal } from '../types';
import { Trophy, Calendar, CheckCircle2, Star, BookOpen, TrendingUp } from 'lucide-react';

interface ReadingChallengeViewProps {
  books: Book[];
  goal: Goal;
  onSelectBook: (book: Book) => void;
  onUpdateGoal: (newGoal: Goal) => void;
}

export const ReadingChallengeView: React.FC<ReadingChallengeViewProps> = ({
  books,
  goal,
  onSelectBook,
  onUpdateGoal,
}) => {
  const finishedBooks = books.filter((b) => b.isFinished);
  const totalPages = books.reduce((sum, b) => sum + b.readPages, 0);

  const percent = Math.min(100, Math.round((finishedBooks.length / Math.max(1, goal.targetBooks)) * 100));

  // Расчет темпа (для 2026 года)
  const currentMonth = new Date().getMonth() + 1; // 1-12
  const expectedPace = Math.round((goal.targetBooks / 12) * currentMonth);
  const diffPace = finishedBooks.length - expectedPace;

  return (
    <div className="max-w-5xl mx-auto space-y-8 animate-in fade-in duration-200">
      {/* Шапка */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold text-white tracking-tight flex items-center gap-2">
            <Trophy className="w-6 h-6 text-amber-400" />
            <span>Книжный вызов {goal.year}</span>
          </h2>
          <p className="text-xs text-neutral-400 mt-1">
            Персональная цель по количеству прочитанных произведений
          </p>
        </div>

        {/* Быстрое изменение цели (шаг 1) */}
        <div className="flex items-center gap-2 p-1.5 rounded-xl bg-white/5 border border-white/10">
          <span className="text-xs text-neutral-400 pl-2">Цель:</span>
          <button
            type="button"
            onClick={() => onUpdateGoal({ ...goal, targetBooks: Math.max(1, goal.targetBooks - 1) })}
            className="w-7 h-7 flex items-center justify-center text-white hover:bg-white/10 rounded-lg text-sm font-bold"
          >
            -
          </button>
          <span className="text-sm font-bold text-emerald-400 px-1">{goal.targetBooks}</span>
          <button
            type="button"
            onClick={() => onUpdateGoal({ ...goal, targetBooks: goal.targetBooks + 1 })}
            className="w-7 h-7 flex items-center justify-center text-white hover:bg-white/10 rounded-lg text-sm font-bold"
          >
            +
          </button>
        </div>
      </div>

      {/* Большая карточка прогресса */}
      <div className="p-8 rounded-3xl bg-gradient-to-br from-[#1e1e28] to-[#14141a] border border-white/10 shadow-mac-card grid grid-cols-1 md:grid-cols-3 gap-8 items-center">
        {/* Индикатор */}
        <div className="flex flex-col items-center justify-center">
          <div className="relative w-40 h-40">
            <svg className="w-full h-full transform -rotate-90" viewBox="0 0 36 36">
              <path
                className="text-neutral-800"
                strokeWidth="3.5"
                stroke="currentColor"
                fill="none"
                d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
              />
              <path
                className="text-emerald-400 transition-all duration-700"
                strokeDasharray={`${percent}, 100`}
                strokeWidth="3.5"
                strokeLinecap="round"
                stroke="currentColor"
                fill="none"
                d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
              />
            </svg>
            <div className="absolute inset-0 flex flex-col items-center justify-center">
              <span className="text-3xl font-extrabold text-white">{percent}%</span>
              <span className="text-[11px] text-neutral-400 font-medium">выполнено</span>
            </div>
          </div>
        </div>

        {/* Статистика и темп */}
        <div className="md:col-span-2 space-y-5">
          <div>
            <span className="text-3xl font-black text-white">
              {finishedBooks.length}{' '}
              <span className="text-lg font-normal text-neutral-400">из {goal.targetBooks} книг</span>
            </span>
            <div className="flex items-center gap-2 mt-2">
              <TrendingUp className="w-4 h-4 text-emerald-400" />
              <span className="text-xs text-neutral-300">
                {diffPace >= 0
                  ? `Вы опережаете график на ${diffPace} ${diffPace === 1 ? 'книгу' : 'книг'}!`
                  : `До планового темпа не хватает ${Math.abs(diffPace)} ${Math.abs(diffPace) === 1 ? 'книги' : 'книг'}.`}
              </span>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4 pt-2">
            <div className="p-4 rounded-2xl bg-white/[0.03] border border-white/5">
              <span className="text-[11px] text-neutral-400 block font-medium">Прочитано страниц</span>
              <span className="text-xl font-bold text-emerald-400 mt-1 block">
                {totalPages.toLocaleString()}
              </span>
            </div>
            <div className="p-4 rounded-2xl bg-white/[0.03] border border-white/5">
              <span className="text-[11px] text-neutral-400 block font-medium">Осталось прочитать</span>
              <span className="text-xl font-bold text-white mt-1 block">
                {Math.max(0, goal.targetBooks - finishedBooks.length)} книг
              </span>
            </div>
          </div>
        </div>
      </div>

      {/* Список всех прочитанных книг года */}
      <div className="space-y-4">
        <h3 className="text-lg font-bold text-white tracking-tight flex items-center gap-2">
          <CheckCircle2 className="w-5 h-5 text-emerald-400" />
          <span>Прочитано в {goal.year} году ({finishedBooks.length})</span>
        </h3>

        {finishedBooks.length > 0 ? (
          <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4">
            {finishedBooks.map((b) => (
              <div
                key={b.id}
                onClick={() => onSelectBook(b)}
                className="group p-4 rounded-2xl bg-[#191922] border border-white/10 hover:border-emerald-500/40 hover:-translate-y-1 transition-all duration-200 cursor-pointer flex gap-4"
              >
                <div className="w-14 h-20 rounded-lg bg-neutral-800 overflow-hidden shrink-0 border border-white/10 shadow">
                  {b.coverURL ? (
                    <img src={b.coverURL} alt="" className="w-full h-full object-cover" />
                  ) : (
                    <div className="w-full h-full flex items-center justify-center text-emerald-500 bg-neutral-900">
                      <BookOpen className="w-5 h-5" />
                    </div>
                  )}
                </div>

                <div className="flex-1 min-w-0 flex flex-col justify-between">
                  <div>
                    <h4 className="text-xs font-bold text-white group-hover:text-emerald-400 transition-colors line-clamp-1">
                      {b.title}
                    </h4>
                    <p className="text-[11px] text-neutral-400 truncate mt-0.5">{b.author}</p>
                  </div>

                  <div className="flex items-center justify-between text-[10px] text-neutral-400 pt-1">
                    <span className="flex items-center gap-1">
                      <Calendar className="w-3 h-3 text-emerald-400" />
                      {b.finishDate || '2026'}
                    </span>
                    {b.rating > 0 && (
                      <span className="flex items-center gap-0.5 text-amber-400 font-bold">
                        <Star className="w-3 h-3 fill-amber-400" />
                        {b.rating}
                      </span>
                    )}
                  </div>
                </div>
              </div>
            ))}
          </div>
        ) : (
          <div className="p-8 rounded-2xl bg-white/[0.02] border border-dashed border-white/10 text-center">
            <Trophy className="w-10 h-10 text-neutral-600 mx-auto mb-2" />
            <p className="text-sm text-neutral-400">В этом году еще нет прочитанных книг</p>
            <p className="text-xs text-neutral-500 mt-1">
              Завершите чтение первой книги, и она появится на этой доске почета!
            </p>
          </div>
        )}
      </div>
    </div>
  );
};
