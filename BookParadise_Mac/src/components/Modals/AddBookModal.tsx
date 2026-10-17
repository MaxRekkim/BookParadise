import React, { useState } from 'react';
import { Book } from '../../types';
import { ModalWrapper } from './ModalWrapper';

interface AddBookModalProps {
  isOpen: boolean;
  onClose: () => void;
  onAdd: (newBook: Book) => void;
}

export const AddBookModal: React.FC<AddBookModalProps> = ({ isOpen, onClose, onAdd }) => {
  const [title, setTitle] = useState('');
  const [author, setAuthor] = useState('');
  const [genre, setGenre] = useState('Классика');
  const [totalPages, setTotalPages] = useState(350);
  const [readPages, setReadPages] = useState(0);
  const [coverURL, setCoverURL] = useState('');
  const [format, setFormat] = useState<'Бумажная' | 'Электронная' | 'Аудио'>('Бумажная');

  const handleSubmit = (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    if (!title.trim() || !author.trim()) return;

    const newBook: Book = {
      id: 'b_' + Date.now(),
      title: title.trim(),
      author: author.trim(),
      genre,
      totalPages: Math.max(1, totalPages),
      readPages: Math.min(totalPages, Math.max(0, readPages)),
      rating: 0,
      isFinished: readPages >= totalPages && totalPages > 0,
      coverURL: coverURL.trim() || undefined,
      startDate: readPages > 0 ? new Date().toISOString().split('T')[0] : undefined,
      format,
    };

    onAdd(newBook);
    onClose();
    // Reset form
    setTitle('');
    setAuthor('');
    setCoverURL('');
    setReadPages(0);
  };

  return (
    <ModalWrapper
      isOpen={isOpen}
      onClose={onClose}
      onDone={handleSubmit}
      title="Добавить книгу в библиотеку"
      subtitle="Заполните информацию о книге для отслеживания чтения"
      maxWidth="max-w-2xl"
    >
      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <label className="block text-xs font-semibold text-neutral-300 mb-1">
            Название книги *
          </label>
          <input
            type="text"
            required
            placeholder="Например: Война и мир"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            className="w-full px-3.5 py-2.5 bg-neutral-900 border border-white/10 rounded-xl text-white text-sm focus:outline-none focus:border-emerald-500 transition-colors"
          />
        </div>

        <div>
          <label className="block text-xs font-semibold text-neutral-300 mb-1">
            Автор *
          </label>
          <input
            type="text"
            required
            placeholder="Например: Лев Толстой"
            value={author}
            onChange={(e) => setAuthor(e.target.value)}
            className="w-full px-3.5 py-2.5 bg-neutral-900 border border-white/10 rounded-xl text-white text-sm focus:outline-none focus:border-emerald-500 transition-colors"
          />
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="block text-xs font-semibold text-neutral-300 mb-1">Жанр</label>
            <select
              value={genre}
              onChange={(e) => setGenre(e.target.value)}
              className="w-full px-3.5 py-2.5 bg-neutral-900 border border-white/10 rounded-xl text-white text-sm focus:outline-none focus:border-emerald-500"
            >
              <option value="Классика">Классика</option>
              <option value="Фантастика">Фантастика</option>
              <option value="Антиутопия">Антиутопия</option>
              <option value="Детектив">Детектив</option>
              <option value="Нон-фикшн">Нон-фикшн</option>
              <option value="Философия">Философия</option>
              <option value="История">История</option>
              <option value="Другое">Другое</option>
            </select>
          </div>

          <div>
            <label className="block text-xs font-semibold text-neutral-300 mb-1">Формат</label>
            <select
              value={format}
              onChange={(e) => setFormat(e.target.value as 'Бумажная' | 'Электронная' | 'Аудио')}
              className="w-full px-3.5 py-2.5 bg-neutral-900 border border-white/10 rounded-xl text-white text-sm focus:outline-none focus:border-emerald-500"
            >
              <option value="Бумажная">Бумажная</option>
              <option value="Электронная">Электронная</option>
              <option value="Аудио">Аудио</option>
            </select>
          </div>
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="block text-xs font-semibold text-neutral-300 mb-1">
              Всего страниц (до 10 000)
            </label>
            <input
              type="number"
              min={1}
              max={10000}
              value={totalPages}
              onChange={(e) => setTotalPages(Number(e.target.value))}
              className="w-full px-3.5 py-2.5 bg-neutral-900 border border-white/10 rounded-xl text-white text-sm focus:outline-none focus:border-emerald-500"
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-neutral-300 mb-1">
              Уже прочитано страниц
            </label>
            <input
              type="number"
              min={0}
              max={10000}
              value={readPages}
              onChange={(e) => setReadPages(Number(e.target.value))}
              className="w-full px-3.5 py-2.5 bg-neutral-900 border border-white/10 rounded-xl text-white text-sm focus:outline-none focus:border-emerald-500"
            />
          </div>
        </div>

        <div>
          <label className="block text-xs font-semibold text-neutral-300 mb-1">
            Ссылка на обложку (URL картинки)
          </label>
          <input
            type="url"
            placeholder="https://images.unsplash.com/..."
            value={coverURL}
            onChange={(e) => setCoverURL(e.target.value)}
            className="w-full px-3.5 py-2.5 bg-neutral-900 border border-white/10 rounded-xl text-white text-sm focus:outline-none focus:border-emerald-500"
          />
        </div>

        <div className="pt-4 flex justify-end gap-3 border-t border-white/10">
          <button
            type="button"
            onClick={onClose}
            className="px-4 py-2 text-sm text-neutral-400 hover:text-white rounded-xl hover:bg-white/5 transition-colors cursor-pointer"
          >
            Отмена
          </button>
          <button
            type="submit"
            className="px-5 py-2 text-sm font-semibold text-white bg-emerald-600 hover:bg-emerald-500 rounded-xl shadow-lg active:scale-95 transition-all cursor-pointer"
          >
            Добавить книгу
          </button>
        </div>
      </form>
    </ModalWrapper>
  );
};
