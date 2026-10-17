import React, { useState } from 'react';
import { Quote, Note } from '../types';
import { Quote as QuoteIcon, FileText, Plus, Search, Trash2, Share2 } from 'lucide-react';

interface NotesStudioViewProps {
  quotes: Quote[];
  notes: Note[];
  onAddQuote: (q: Quote) => void;
  onAddNote: (n: Note) => void;
  onDeleteQuote: (id: string) => void;
  onDeleteNote: (id: string) => void;
  onShareQuote?: (q: Quote) => void;
}

export const NotesStudioView: React.FC<NotesStudioViewProps> = ({
  quotes,
  notes,
  onAddQuote,
  onAddNote,
  onDeleteQuote,
  onDeleteNote,
  onShareQuote,
}) => {
  const [activeTab, setActiveTab] = useState<'quotes' | 'notes'>('quotes');
  const [searchQuery, setSearchQuery] = useState('');

  // Состояние создания цитаты
  const [isAddingQuote, setIsAddingQuote] = useState(false);
  const [quoteText, setQuoteText] = useState('');
  const [quoteBook, setQuoteBook] = useState('');
  const [quoteAuthor, setQuoteAuthor] = useState('');
  const [quotePage, setQuotePage] = useState<number | ''>('');

  // Состояние создания заметки
  const [isAddingNote, setIsAddingNote] = useState(false);
  const [noteTitle, setNoteTitle] = useState('');
  const [noteBook, setNoteBook] = useState('');
  const [noteContent, setNoteContent] = useState('');

  const handleCreateQuote = (e: React.FormEvent) => {
    e.preventDefault();
    if (!quoteText.trim()) return;
    const newQuote: Quote = {
      id: 'q_' + Date.now(),
      text: quoteText.trim(),
      bookTitle: quoteBook.trim() || 'Без книги',
      bookId: 'custom',
      author: quoteAuthor.trim() || 'Не указан',
      page: quotePage ? Number(quotePage) : undefined,
      date: new Date().toISOString().split('T')[0],
    };
    onAddQuote(newQuote);
    setQuoteText('');
    setQuoteBook('');
    setQuoteAuthor('');
    setQuotePage('');
    setIsAddingQuote(false);
  };

  const handleCreateNote = (e: React.FormEvent) => {
    e.preventDefault();
    if (!noteTitle.trim() || !noteContent.trim()) return;
    const newNote: Note = {
      id: 'n_' + Date.now(),
      title: noteTitle.trim(),
      bookTitle: noteBook.trim() || undefined,
      content: noteContent.trim(),
      updatedAt: new Date().toISOString().split('T')[0],
    };
    onAddNote(newNote);
    setNoteTitle('');
    setNoteBook('');
    setNoteContent('');
    setIsAddingNote(false);
  };

  // Фильтрация
  const filteredQuotes = quotes.filter(
    (q) =>
      q.text.toLowerCase().includes(searchQuery.toLowerCase()) ||
      q.author.toLowerCase().includes(searchQuery.toLowerCase()) ||
      q.bookTitle.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const filteredNotes = notes.filter(
    (n) =>
      n.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
      n.content.toLowerCase().includes(searchQuery.toLowerCase()) ||
      (n.bookTitle && n.bookTitle.toLowerCase().includes(searchQuery.toLowerCase()))
  );

  return (
    <div className="max-w-5xl mx-auto space-y-6 animate-in fade-in duration-200">
      {/* Зафиксированная шапка: НИКОГДА не съезжает при вертикальном скролле */}
      <div className="sticky top-0 z-20 bg-[#121216]/95 backdrop-blur-md pt-2 pb-4 border-b border-white/10 flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold text-white tracking-tight">Дневник заметок и цитат</h2>
          <p className="text-xs text-neutral-400 mt-0.5">
            Фиксируйте главные мысли, озарения и мудрые строки из прочитанного
          </p>
        </div>

        {/* Переключатель вкладок и кнопка добавления */}
        <div className="flex items-center gap-3">
          <div className="flex bg-white/5 border border-white/10 rounded-xl p-1">
            <button
              type="button"
              onClick={() => setActiveTab('quotes')}
              className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold transition-all cursor-pointer ${
                activeTab === 'quotes' ? 'bg-emerald-500/20 text-emerald-400' : 'text-neutral-400 hover:text-white'
              }`}
            >
              <QuoteIcon className="w-3.5 h-3.5" />
              <span>Цитаты ({quotes.length})</span>
            </button>
            <button
              type="button"
              onClick={() => setActiveTab('notes')}
              className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold transition-all cursor-pointer ${
                activeTab === 'notes' ? 'bg-emerald-500/20 text-emerald-400' : 'text-neutral-400 hover:text-white'
              }`}
            >
              <FileText className="w-3.5 h-3.5" />
              <span>Заметки ({notes.length})</span>
            </button>
          </div>

          <button
            type="button"
            onClick={() => (activeTab === 'quotes' ? setIsAddingQuote(true) : setIsAddingNote(true))}
            className="flex items-center gap-1.5 px-4 py-2 bg-emerald-600 hover:bg-emerald-500 text-white text-xs font-semibold rounded-xl shadow-lg transition-all cursor-pointer"
          >
            <Plus className="w-4 h-4" />
            <span>{activeTab === 'quotes' ? 'Новая цитата' : 'Новая заметка'}</span>
          </button>
        </div>
      </div>

      {/* Поиск */}
      <div className="relative">
        <Search className="w-4 h-4 text-neutral-500 absolute left-3 top-1/2 -translate-y-1/2" />
        <input
          type="text"
          placeholder={`Поиск по ${activeTab === 'quotes' ? 'цитатам, авторам или книгам' : 'заметкам и тексту'}...`}
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          className="w-full pl-9 pr-4 py-2.5 bg-neutral-900 border border-white/10 rounded-xl text-xs text-white placeholder-neutral-500 focus:outline-none focus:border-emerald-500"
        />
      </div>

      {/* Форма добавления новой цитаты */}
      {isAddingQuote && (
        <form onSubmit={handleCreateQuote} className="p-5 rounded-2xl bg-[#1a1a24] border border-emerald-500/30 space-y-4">
          <h3 className="text-sm font-bold text-white flex items-center gap-2">
            <QuoteIcon className="w-4 h-4 text-emerald-400" />
            <span>Добавить новую цитату</span>
          </h3>
          <textarea
            required
            rows={3}
            placeholder="Введите текст цитаты..."
            value={quoteText}
            onChange={(e) => setQuoteText(e.target.value)}
            className="w-full p-3 bg-neutral-900 border border-white/10 rounded-xl text-xs text-white focus:outline-none focus:border-emerald-500"
          />
          <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
            <input
              type="text"
              placeholder="Название книги"
              value={quoteBook}
              onChange={(e) => setQuoteBook(e.target.value)}
              className="p-2.5 bg-neutral-900 border border-white/10 rounded-xl text-xs text-white focus:outline-none focus:border-emerald-500"
            />
            <input
              type="text"
              placeholder="Автор"
              value={quoteAuthor}
              onChange={(e) => setQuoteAuthor(e.target.value)}
              className="p-2.5 bg-neutral-900 border border-white/10 rounded-xl text-xs text-white focus:outline-none focus:border-emerald-500"
            />
            <input
              type="number"
              placeholder="Страница (номер)"
              value={quotePage}
              onChange={(e) => setQuotePage(e.target.value ? Number(e.target.value) : '')}
              className="p-2.5 bg-neutral-900 border border-white/10 rounded-xl text-xs text-white focus:outline-none focus:border-emerald-500"
            />
          </div>
          <div className="flex justify-end gap-2">
            <button
              type="button"
              onClick={() => setIsAddingQuote(false)}
              className="px-3 py-1.5 text-xs text-neutral-400 hover:text-white"
            >
              Отмена
            </button>
            <button
              type="submit"
              className="px-4 py-1.5 bg-emerald-600 hover:bg-emerald-500 text-white text-xs font-semibold rounded-lg shadow"
            >
              Сохранить цитату
            </button>
          </div>
        </form>
      )}

      {/* Форма добавления новой заметки */}
      {isAddingNote && (
        <form onSubmit={handleCreateNote} className="p-5 rounded-2xl bg-[#1a1a24] border border-teal-500/30 space-y-4">
          <h3 className="text-sm font-bold text-white flex items-center gap-2">
            <FileText className="w-4 h-4 text-teal-400" />
            <span>Добавить новую заметку</span>
          </h3>
          <div className="grid grid-cols-2 gap-3">
            <input
              type="text"
              required
              placeholder="Заголовок заметки..."
              value={noteTitle}
              onChange={(e) => setNoteTitle(e.target.value)}
              className="p-2.5 bg-neutral-900 border border-white/10 rounded-xl text-xs text-white focus:outline-none focus:border-emerald-500"
            />
            <input
              type="text"
              placeholder="Книга (опционально)..."
              value={noteBook}
              onChange={(e) => setNoteBook(e.target.value)}
              className="p-2.5 bg-neutral-900 border border-white/10 rounded-xl text-xs text-white focus:outline-none focus:border-emerald-500"
            />
          </div>
          <textarea
            required
            rows={4}
            placeholder="Текст вашей заметки или анализа..."
            value={noteContent}
            onChange={(e) => setNoteContent(e.target.value)}
            className="w-full p-3 bg-neutral-900 border border-white/10 rounded-xl text-xs text-white focus:outline-none focus:border-emerald-500"
          />
          <div className="flex justify-end gap-2">
            <button
              type="button"
              onClick={() => setIsAddingNote(false)}
              className="px-3 py-1.5 text-xs text-neutral-400 hover:text-white"
            >
              Отмена
            </button>
            <button
              type="submit"
              className="px-4 py-1.5 bg-teal-600 hover:bg-teal-500 text-white text-xs font-semibold rounded-lg shadow"
            >
              Сохранить заметку
            </button>
          </div>
        </form>
      )}

      {/* Список цитат */}
      {activeTab === 'quotes' && (
        <div className="space-y-4">
          {filteredQuotes.map((q) => (
            <div
              key={q.id}
              className="group p-5 rounded-2xl bg-[#181822] border border-white/10 hover:border-emerald-500/30 transition-all flex justify-between gap-4"
            >
              <div className="space-y-2 flex-1">
                <blockquote className="text-sm text-neutral-200 italic leading-relaxed">
                  «{q.text}»
                </blockquote>
                <div className="flex items-center gap-2 text-xs text-neutral-400">
                  <span className="font-semibold text-white">{q.author}</span>
                  <span>•</span>
                  <span>«{q.bookTitle}»</span>
                  {q.page && <span>(стр. {q.page})</span>}
                </div>
              </div>

              <div className="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-all shrink-0">
                {onShareQuote && (
                  <button
                    type="button"
                    onClick={() => onShareQuote(q)}
                    className="p-2 text-neutral-400 hover:text-emerald-400 hover:bg-emerald-500/10 rounded-lg transition-all h-fit cursor-pointer"
                    title="Создать Spotify Lyrics карточку для Stories"
                  >
                    <Share2 className="w-4 h-4" />
                  </button>
                )}
                <button
                  type="button"
                  onClick={() => onDeleteQuote(q.id)}
                  className="p-2 text-neutral-500 hover:text-rose-400 hover:bg-rose-500/10 rounded-lg transition-all h-fit cursor-pointer"
                  title="Удалить цитату"
                >
                  <Trash2 className="w-4 h-4" />
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Список заметок */}
      {activeTab === 'notes' && (
        <div className="space-y-4">
          {filteredNotes.map((n) => (
            <div
              key={n.id}
              className="group p-5 rounded-2xl bg-[#181822] border border-white/10 hover:border-teal-500/30 transition-all flex justify-between gap-4"
            >
              <div className="space-y-2 flex-1">
                <div className="flex items-center justify-between">
                  <h4 className="text-sm font-bold text-white">{n.title}</h4>
                  <span className="text-[10px] text-neutral-500">{n.updatedAt}</span>
                </div>
                {n.bookTitle && (
                  <span className="text-xs text-teal-400 block font-medium">Книга: {n.bookTitle}</span>
                )}
                <p className="text-xs text-neutral-300 leading-relaxed whitespace-pre-line">
                  {n.content}
                </p>
              </div>

              <button
                type="button"
                onClick={() => onDeleteNote(n.id)}
                className="opacity-0 group-hover:opacity-100 p-2 text-neutral-500 hover:text-rose-400 hover:bg-white/5 rounded-lg transition-all h-fit cursor-pointer"
                title="Удалить заметку"
              >
                <Trash2 className="w-4 h-4" />
              </button>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};
