import React, { useState } from 'react';
import { Book } from '../types';
import { LayoutGrid, List, Search, Star, BookOpen, CheckCircle } from 'lucide-react';

interface LibraryViewProps {
  books: Book[];
  onSelectBook: (book: Book) => void;
  onOpenAddModal: () => void;
}

export const LibraryView: React.FC<LibraryViewProps> = ({
  books,
  onSelectBook,
  onOpenAddModal,
}) => {
  const [viewMode, setViewMode] = useState<'grid' | 'table'>('grid');
  const [statusFilter, setStatusFilter] = useState<'all' | 'reading' | 'finished' | 'planned'>('all');
  const [searchQuery, setSearchQuery] = useState('');
  const [genreFilter, setGenreFilter] = useState<string>('all');
  const [sortBy, setSortBy] = useState<'title' | 'author' | 'progress' | 'rating'>('progress');

  // Уникальные жанры
  const genres = Array.from(new Set(books.map((b) => b.genre).filter(Boolean)));

  // Фильтрация
  const filteredBooks = books
    .filter((b) => {
      // Статус
      if (statusFilter === 'reading') return b.readPages > 0 && !b.isFinished;
      if (statusFilter === 'finished') return b.isFinished;
      if (statusFilter === 'planned') return b.readPages === 0 && !b.isFinished;
      return true;
    })
    .filter((b) => {
      // Жанр
      if (genreFilter !== 'all' && b.genre !== genreFilter) return false;
      // Поиск
      if (searchQuery.trim()) {
        const q = searchQuery.toLowerCase();
        return b.title.toLowerCase().includes(q) || b.author.toLowerCase().includes(q);
      }
      return true;
    })
    .sort((a, b) => {
      if (sortBy === 'title') return a.title.localeCompare(b.title);
      if (sortBy === 'author') return a.author.localeCompare(b.author);
      if (sortBy === 'rating') return b.rating - a.rating;
      // progress
      const pA = a.readPages / Math.max(1, a.totalPages);
      const pB = b.readPages / Math.max(1, b.totalPages);
      return pB - pA;
    });

  return (
    <div className="max-w-6xl mx-auto space-y-6 animate-in fade-in duration-200">
      {/* Шапка раздела */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold text-white tracking-tight">Библиотека</h2>
          <p className="text-xs text-neutral-400 mt-1">
            Всего в каталоге: {books.length} {books.length === 1 ? 'книга' : 'книг'}
          </p>
        </div>

        {/* Переключатель вида Grid / Table */}
        <div className="flex items-center gap-2">
          <div className="flex items-center bg-white/5 border border-white/10 rounded-xl p-1">
            <button
              type="button"
              onClick={() => setViewMode('grid')}
              className={`p-1.5 rounded-lg transition-colors cursor-pointer ${
                viewMode === 'grid' ? 'bg-white/15 text-white' : 'text-neutral-400 hover:text-white'
              }`}
              title="Сетка"
            >
              <LayoutGrid className="w-4 h-4" />
            </button>
            <button
              type="button"
              onClick={() => setViewMode('table')}
              className={`p-1.5 rounded-lg transition-colors cursor-pointer ${
                viewMode === 'table' ? 'bg-white/15 text-white' : 'text-neutral-400 hover:text-white'
              }`}
              title="Таблица"
            >
              <List className="w-4 h-4" />
            </button>
          </div>

          <button
            type="button"
            onClick={onOpenAddModal}
            className="px-4 py-2 bg-emerald-600 hover:bg-emerald-500 text-white rounded-xl text-xs font-semibold shadow-lg shadow-emerald-950/50 active:scale-95 transition-all cursor-pointer"
          >
            + Добавить книгу
          </button>
        </div>
      </div>

      {/* Панель фильтров и поиска */}
      <div className="flex flex-wrap items-center justify-between gap-4 p-4 rounded-2xl bg-[#181820] border border-white/10">
        {/* Фильтры статуса */}
        <div className="flex items-center gap-1.5">
          {(
            [
              { id: 'all', label: 'Все' },
              { id: 'reading', label: 'Читаю сейчас' },
              { id: 'finished', label: 'Прочитано' },
              { id: 'planned', label: 'В планах' },
            ] as const
          ).map((tab) => (
            <button
              key={tab.id}
              type="button"
              onClick={() => setStatusFilter(tab.id)}
              className={`px-3 py-1.5 rounded-xl text-xs font-medium transition-all cursor-pointer ${
                statusFilter === tab.id
                  ? 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/30 font-semibold'
                  : 'text-neutral-400 hover:text-white hover:bg-white/5'
              }`}
            >
              {tab.label}
            </button>
          ))}
        </div>

        {/* Поиск и выпадающие списки */}
        <div className="flex items-center gap-3">
          <div className="relative">
            <Search className="w-4 h-4 text-neutral-500 absolute left-3 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              placeholder="Поиск по названию или автору..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="pl-9 pr-3 py-1.5 bg-neutral-900 border border-white/10 rounded-xl text-xs text-white placeholder-neutral-500 w-60 focus:outline-none focus:border-emerald-500"
            />
          </div>

          {/* Жанр */}
          <select
            value={genreFilter}
            onChange={(e) => setGenreFilter(e.target.value)}
            className="px-3 py-1.5 bg-neutral-900 border border-white/10 rounded-xl text-xs text-neutral-300 focus:outline-none focus:border-emerald-500 cursor-pointer"
          >
            <option value="all">Все жанры</option>
            {genres.map((g) => (
              <option key={g} value={g}>
                {g}
              </option>
            ))}
          </select>

          {/* Сортировка */}
          <select
            value={sortBy}
            onChange={(e) => setSortBy(e.target.value as 'title' | 'author' | 'progress' | 'rating')}
            className="px-3 py-1.5 bg-neutral-900 border border-white/10 rounded-xl text-xs text-neutral-300 focus:outline-none focus:border-emerald-500 cursor-pointer"
          >
            <option value="progress">По прогрессу</option>
            <option value="rating">По рейтингу</option>
            <option value="title">По названию</option>
            <option value="author">По автору</option>
          </select>
        </div>
      </div>

      {/* Отображение: Сетка с эффектом 3D Hover Lift */}
      {viewMode === 'grid' ? (
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-6">
          {filteredBooks.map((book) => {
            const progress = Math.min(100, Math.round((book.readPages / Math.max(1, book.totalPages)) * 100));
            return (
              <div
                key={book.id}
                onClick={() => onSelectBook(book)}
                className="group relative flex flex-col rounded-2xl bg-[#191922] border border-white/10 overflow-hidden shadow-mac-card hover:shadow-mac-card-hover hover:border-emerald-500/40 hover:-translate-y-1.5 hover:scale-[1.02] transition-all duration-200 cursor-pointer"
              >
                {/* Обложка книги */}
                <div className="relative aspect-[2/3] w-full bg-neutral-900 overflow-hidden">
                  {book.coverURL ? (
                    <img
                      src={book.coverURL}
                      alt={book.title}
                      className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                    />
                  ) : (
                    <div className="w-full h-full flex flex-col items-center justify-center p-3 text-neutral-500 bg-neutral-900">
                      <BookOpen className="w-8 h-8 text-emerald-500 mb-2" />
                      <span className="text-xs text-center text-neutral-400 font-medium line-clamp-2">
                        {book.title}
                      </span>
                    </div>
                  )}

                  {/* Бейдж завершения */}
                  {book.isFinished && (
                    <div className="absolute top-2 right-2 px-2 py-0.5 rounded-full bg-emerald-500 text-white text-[10px] font-bold shadow-md flex items-center gap-1">
                      <CheckCircle className="w-3 h-3" />
                      <span>100%</span>
                    </div>
                  )}

                  {/* Прогресс-бар полоской внизу обложки */}
                  {!book.isFinished && book.readPages > 0 && (
                    <div className="absolute bottom-0 inset-x-0 h-1.5 bg-black/50">
                      <div className="h-full bg-emerald-400" style={{ width: `${progress}%` }} />
                    </div>
                  )}
                </div>

                {/* Метаданные книги */}
                <div className="p-3.5 flex-1 flex flex-col justify-between space-y-2">
                  <div>
                    <h3 className="text-xs font-bold text-white group-hover:text-emerald-400 transition-colors line-clamp-1">
                      {book.title}
                    </h3>
                    <p className="text-[11px] text-neutral-400 truncate mt-0.5">{book.author}</p>
                  </div>

                  <div className="flex items-center justify-between pt-1 border-t border-white/5 text-[10px] text-neutral-400">
                    <span>{book.genre}</span>
                    {book.rating > 0 ? (
                      <span className="flex items-center gap-0.5 text-amber-400 font-bold">
                        <Star className="w-3 h-3 fill-amber-400" />
                        {book.rating}
                      </span>
                    ) : (
                      <span>{book.readPages}/{book.totalPages} с.</span>
                    )}
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      ) : (
        /* Табличный вид */
        <div className="rounded-2xl bg-[#191922] border border-white/10 overflow-hidden shadow-mac-card">
          <table className="w-full text-left text-xs">
            <thead className="bg-white/5 border-b border-white/10 text-neutral-400 font-semibold uppercase tracking-wider text-[10px]">
              <tr>
                <th className="py-3 px-4">Книга</th>
                <th className="py-3 px-4">Автор</th>
                <th className="py-3 px-4">Жанр</th>
                <th className="py-3 px-4">Прогресс</th>
                <th className="py-3 px-4">Оценка</th>
                <th className="py-3 px-4">Статус</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-white/5">
              {filteredBooks.map((b) => (
                <tr
                  key={b.id}
                  onClick={() => onSelectBook(b)}
                  className="hover:bg-white/[0.04] transition-colors cursor-pointer group"
                >
                  <td className="py-3 px-4 font-semibold text-white group-hover:text-emerald-400 flex items-center gap-3">
                    <div className="w-7 h-10 rounded bg-neutral-800 overflow-hidden shrink-0 border border-white/10">
                      {b.coverURL ? (
                        <img src={b.coverURL} alt="" className="w-full h-full object-cover" />
                      ) : (
                        <div className="w-full h-full flex items-center justify-center text-emerald-500">
                          <BookOpen className="w-3 h-3" />
                        </div>
                      )}
                    </div>
                    <span>{b.title}</span>
                  </td>
                  <td className="py-3 px-4 text-neutral-300">{b.author}</td>
                  <td className="py-3 px-4 text-neutral-400">{b.genre}</td>
                  <td className="py-3 px-4">
                    <span className="font-mono text-emerald-400">
                      {b.readPages} / {b.totalPages} с. ({Math.round((b.readPages / b.totalPages) * 100)}%)
                    </span>
                  </td>
                  <td className="py-3 px-4">
                    {b.rating > 0 ? (
                      <span className="flex items-center gap-1 text-amber-400 font-bold">
                        <Star className="w-3.5 h-3.5 fill-amber-400" /> {b.rating}
                      </span>
                    ) : (
                      <span className="text-neutral-500">—</span>
                    )}
                  </td>
                  <td className="py-3 px-4">
                    {b.isFinished ? (
                      <span className="px-2 py-0.5 rounded-full bg-emerald-500/20 text-emerald-400 text-[10px] font-semibold border border-emerald-500/30">
                        Прочитано
                      </span>
                    ) : b.readPages > 0 ? (
                      <span className="px-2 py-0.5 rounded-full bg-amber-500/20 text-amber-300 text-[10px] font-semibold border border-amber-500/30">
                        В процессе
                      </span>
                    ) : (
                      <span className="px-2 py-0.5 rounded-full bg-white/5 text-neutral-400 text-[10px] font-semibold">
                        В планах
                      </span>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
};
