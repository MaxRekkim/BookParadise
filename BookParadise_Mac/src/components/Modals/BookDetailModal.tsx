import React, { useState } from 'react';
import { Book } from '../../types';
import { ModalWrapper } from './ModalWrapper';
import { Star, BookOpen, Trash2, Calendar, Award } from 'lucide-react';

interface BookDetailModalProps {
  book: Book | null;
  isOpen: boolean;
  onClose: () => void;
  onUpdate: (updated: Book) => void;
  onDelete: (id: string) => void;
}

export const BookDetailModal: React.FC<BookDetailModalProps> = ({
  book,
  isOpen,
  onClose,
  onUpdate,
  onDelete,
}) => {
  if (!book) return null;

  const [readPages, setReadPages] = useState(book.readPages);
  const [totalPages, setTotalPages] = useState(book.totalPages);
  const [rating, setRating] = useState(book.rating);
  const [isFinished, setIsFinished] = useState(book.isFinished);
  const [maxSliderLimit, setMaxSliderLimit] = useState(Math.max(1000, book.totalPages, 10000));

  const percent = totalPages > 0 ? Math.min(100, Math.round((readPages / totalPages) * 100)) : 0;

  const handleSave = () => {
    onUpdate({
      ...book,
      readPages,
      totalPages,
      rating,
      isFinished: isFinished || (readPages >= totalPages && totalPages > 0),
      finishDate: isFinished && !book.finishDate ? new Date().toISOString().split('T')[0] : book.finishDate,
    });
  };

  const handlePagesSlider = (val: number) => {
    setReadPages(val);
    if (val >= totalPages && totalPages > 0) {
      setIsFinished(true);
    } else {
      setIsFinished(false);
    }
  };

  return (
    <ModalWrapper
      isOpen={isOpen}
      onClose={onClose}
      onDone={handleSave}
      title={book.title}
      subtitle={`${book.author} • ${book.genre || 'Без жанра'}`}
      maxWidth="max-w-4xl"
    >
      <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
        {/* Левая колонка: Обложка и статус */}
        <div className="flex flex-col items-center text-center">
          <div className="relative group w-48 h-72 rounded-xl overflow-hidden shadow-2xl border border-white/10 bg-neutral-900 transition-transform duration-300 hover:scale-105">
            {book.coverURL ? (
              <img
                src={book.coverURL}
                alt={book.title}
                className="w-full h-full object-cover"
              />
            ) : (
              <div className="w-full h-full flex flex-col items-center justify-center p-4 bg-gradient-to-br from-emerald-950 to-neutral-900 text-neutral-400">
                <BookOpen className="w-12 h-12 text-emerald-500 mb-2" />
                <span className="font-semibold text-sm text-neutral-200">{book.title}</span>
              </div>
            )}
            <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity flex items-end p-3 justify-center">
              <span className="text-xs font-medium text-white/90">Кликните «Готово» для сохранения</span>
            </div>
          </div>

          {/* Рейтинг */}
          <div className="mt-5 flex items-center gap-1">
            {[1, 2, 3, 4, 5].map((star) => (
              <button
                key={star}
                type="button"
                onClick={() => setRating(star)}
                className="p-1 hover:scale-125 transition-transform"
                title={`${star} из 5 звезд`}
              >
                <Star
                  className={`w-5 h-5 ${
                    star <= rating ? 'text-amber-400 fill-amber-400' : 'text-neutral-600'
                  }`}
                />
              </button>
            ))}
          </div>
          <span className="text-xs text-neutral-400 mt-1">Оценка книги</span>
        </div>

        {/* Правая колонка: Прогресс, слайдер до 10 000 страниц, настройки */}
        <div className="md:col-span-2 space-y-6">
          {/* Плашка прогресса */}
          <div className="p-5 rounded-xl bg-white/[0.03] border border-white/10">
            <div className="flex items-center justify-between mb-3">
              <span className="text-sm font-medium text-neutral-300">Прогресс чтения</span>
              <div className="flex items-center gap-2">
                <span className="text-2xl font-bold text-emerald-400">{percent}%</span>
                {percent === 100 && (
                  <span className="flex items-center gap-1 text-xs font-semibold px-2 py-0.5 rounded-full bg-emerald-500/20 text-emerald-400 border border-emerald-500/30">
                    <Award className="w-3.5 h-3.5" /> Прочитано
                  </span>
                )}
              </div>
            </div>

            {/* Прогресс-бар */}
            <div className="w-full h-3 bg-neutral-800 rounded-full overflow-hidden border border-white/5">
              <div
                className="h-full bg-gradient-to-r from-emerald-500 to-teal-400 rounded-full transition-all duration-300"
                style={{ width: `${percent}%` }}
              />
            </div>

            {/* Слайдер и поля ввода до 10 000 страниц */}
            <div className="mt-6 space-y-4">
              <div className="flex items-center justify-between text-xs text-neutral-400">
                <span>0 стр.</span>
                <span className="font-medium text-neutral-200">
                  Текущая страница: <strong className="text-emerald-400 text-sm">{readPages}</strong> из {totalPages}
                </span>
                <span>{maxSliderLimit} стр.</span>
              </div>

              {/* Ползунок */}
              <input
                type="range"
                min={0}
                max={Math.max(totalPages, maxSliderLimit)}
                step={1}
                value={readPages}
                onChange={(e) => handlePagesSlider(Number(e.target.value))}
                className="w-full accent-emerald-500 cursor-pointer h-2 bg-neutral-700 rounded-lg"
              />

              {/* Ручные поля ввода */}
              <div className="grid grid-cols-2 gap-4 pt-2">
                <div>
                  <label className="block text-xs font-medium text-neutral-400 mb-1">
                    Прочитано страниц:
                  </label>
                  <input
                    type="number"
                    min={0}
                    max={10000}
                    value={readPages}
                    onChange={(e) => handlePagesSlider(Math.max(0, Number(e.target.value)))}
                    className="w-full px-3 py-2 text-sm bg-neutral-900 border border-white/10 rounded-lg text-white focus:outline-none focus:border-emerald-500"
                  />
                </div>
                <div>
                  <label className="block text-xs font-medium text-neutral-400 mb-1">
                    Всего страниц в книге:
                  </label>
                  <input
                    type="number"
                    min={1}
                    max={10000}
                    value={totalPages}
                    onChange={(e) => {
                      const newTotal = Math.max(1, Number(e.target.value));
                      setTotalPages(newTotal);
                      if (newTotal > maxSliderLimit) setMaxSliderLimit(newTotal);
                    }}
                    className="w-full px-3 py-2 text-sm bg-neutral-900 border border-white/10 rounded-lg text-white focus:outline-none focus:border-emerald-500"
                  />
                </div>
              </div>
            </div>
          </div>

          {/* Метаданные */}
          <div className="grid grid-cols-2 gap-4">
            <div className="p-4 rounded-xl bg-white/[0.02] border border-white/10 flex items-center gap-3">
              <Calendar className="w-5 h-5 text-emerald-400" />
              <div>
                <span className="text-xs text-neutral-400 block">Начало чтения</span>
                <span className="text-sm font-medium text-white">
                  {book.startDate || 'Не указано'}
                </span>
              </div>
            </div>
            <div className="p-4 rounded-xl bg-white/[0.02] border border-white/10 flex items-center gap-3">
              <Award className="w-5 h-5 text-teal-400" />
              <div>
                <span className="text-xs text-neutral-400 block">Завершение чтения</span>
                <span className="text-sm font-medium text-white">
                  {book.finishDate || (book.isFinished ? 'Завершена' : 'В процессе')}
                </span>
              </div>
            </div>
          </div>

          {/* Кнопка удаления */}
          <div className="pt-4 border-t border-white/10 flex justify-between items-center">
            <button
              type="button"
              onClick={() => {
                if (confirm(`Удалить книгу «${book.title}» из библиотеки?`)) {
                  onDelete(book.id);
                  onClose();
                }
              }}
              className="flex items-center gap-2 text-xs font-semibold text-rose-400 hover:text-rose-300 hover:bg-rose-500/10 px-3 py-2 rounded-lg transition-colors cursor-pointer"
            >
              <Trash2 className="w-4 h-4" />
              Удалить из библиотеки
            </button>
            <button
              type="button"
              onClick={() => {
                handleSave();
                onClose();
              }}
              className="px-5 py-2 text-sm font-semibold text-white bg-emerald-600 hover:bg-emerald-500 rounded-lg shadow-lg active:scale-95 transition-all cursor-pointer"
            >
              Сохранить изменения
            </button>
          </div>
        </div>
      </div>
    </ModalWrapper>
  );
};
