import React, { useState } from 'react';
import { Book, Quote, Note } from '../../types';
import { ModalWrapper } from './ModalWrapper';
import { storageService } from '../../services/storage';
import { Download, Upload, FileText, CheckCircle, Sparkles, Command } from 'lucide-react';

interface SettingsModalProps {
  isOpen: boolean;
  onClose: () => void;
  books: Book[];
  quotes: Quote[];
  notes: Note[];
  onImportBooks: (imported: Book[]) => void;
}

export const SettingsModal: React.FC<SettingsModalProps> = ({
  isOpen,
  onClose,
  books,
  quotes,
  notes,
  onImportBooks,
}) => {
  const [sheetsUrl, setSheetsUrl] = useState(storageService.getSheetsUrl());
  const [copied, setCopied] = useState(false);

  const handleExportMarkdown = () => {
    const md = storageService.exportMarkdown(books, quotes, notes);
    storageService.downloadFile(md, 'Каталог_Книжный_Рай.md', 'text/markdown;charset=utf-8');
  };

  const handleExportJSON = () => {
    const data = JSON.stringify({ books, quotes, notes, version: '2.12.0' }, null, 2);
    storageService.downloadFile(data, 'BookParadise_Backup.json', 'application/json');
  };

  const handleImportJSON = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = (event) => {
      try {
        const parsed = JSON.parse(event.target?.result as string);
        if (Array.isArray(parsed.books)) {
          onImportBooks(parsed.books);
          alert(`Успешно импортировано ${parsed.books.length} книг!`);
        }
      } catch {
        alert('Ошибка при чтении файла бэкапа');
      }
    };
    reader.readAsText(file);
  };

  return (
    <ModalWrapper
      isOpen={isOpen}
      onClose={onClose}
      title="Настройки BookParadise macOS"
      subtitle="Синхронизация данных, экспорт базы, шорткаты и профиль"
      maxWidth="max-w-3xl"
    >
      <div className="space-y-6">
        {/* Экспорт и бэкапы */}
        <div className="p-5 rounded-xl bg-white/[0.03] border border-white/10 space-y-4">
          <div className="flex items-center gap-2">
            <FileText className="w-5 h-5 text-emerald-400" />
            <h3 className="text-sm font-semibold text-white">Экспорт в Markdown (Obsidian / Notion)</h3>
          </div>
          <p className="text-xs text-neutral-400 leading-relaxed">
            Выгрузите весь каталог книг, статус, авторов, цитаты и заметки в один структурированный Markdown-файл для личной базы знаний PKM.
          </p>
          <div className="flex gap-3">
            <button
              type="button"
              onClick={handleExportMarkdown}
              className="flex items-center gap-2 px-4 py-2 bg-emerald-500/15 hover:bg-emerald-500/25 border border-emerald-500/30 text-emerald-400 text-xs font-semibold rounded-lg transition-colors cursor-pointer"
            >
              <Download className="w-4 h-4" />
              Экспортировать каталог (.md)
            </button>
            <button
              type="button"
              onClick={handleExportJSON}
              className="flex items-center gap-2 px-4 py-2 bg-white/5 hover:bg-white/10 border border-white/10 text-neutral-300 text-xs font-semibold rounded-lg transition-colors cursor-pointer"
            >
              <Download className="w-4 h-4" />
              Полный JSON бэкап
            </button>
            <label className="flex items-center gap-2 px-4 py-2 bg-white/5 hover:bg-white/10 border border-white/10 text-neutral-300 text-xs font-semibold rounded-lg transition-colors cursor-pointer">
              <Upload className="w-4 h-4" />
              Восстановить из JSON
              <input type="file" accept=".json" onChange={handleImportJSON} className="hidden" />
            </label>
          </div>
        </div>

        {/* Облачная синхронизация */}
        <div className="p-5 rounded-xl bg-white/[0.03] border border-white/10 space-y-4">
          <div className="flex items-center gap-2">
            <Sparkles className="w-5 h-5 text-teal-400" />
            <h3 className="text-sm font-semibold text-white">Google Таблицы / Облачная база</h3>
          </div>
          <p className="text-xs text-neutral-400 leading-relaxed">
            Подключите личную Google Таблицу через Apps Script веб-приложение для бесшовной синхронизации между мобильным телефоном и десктопом.
          </p>
          <div className="flex gap-2">
            <input
              type="url"
              placeholder="https://script.google.com/macros/s/.../exec"
              value={sheetsUrl}
              onChange={(e) => setSheetsUrl(e.target.value)}
              className="flex-1 px-3.5 py-2 bg-neutral-900 border border-white/10 rounded-lg text-xs text-white focus:outline-none focus:border-emerald-500"
            />
            <button
              type="button"
              onClick={() => {
                storageService.saveSheetsUrl(sheetsUrl);
                setCopied(true);
                setTimeout(() => setCopied(false), 2000);
              }}
              className="px-4 py-2 bg-emerald-600 hover:bg-emerald-500 text-xs font-semibold text-white rounded-lg transition-colors cursor-pointer"
            >
              {copied ? 'Сохранено!' : 'Сохранить'}
            </button>
          </div>
        </div>

        {/* Горячие клавиши (Raycast style) */}
        <div className="p-5 rounded-xl bg-white/[0.03] border border-white/10 space-y-3">
          <div className="flex items-center gap-2">
            <Command className="w-5 h-5 text-neutral-400" />
            <h3 className="text-sm font-semibold text-white">Горячие клавиши macOS</h3>
          </div>
          <div className="grid grid-cols-2 gap-3 text-xs">
            <div className="flex items-center justify-between p-2 rounded-lg bg-black/20 border border-white/5">
              <span className="text-neutral-400">Быстрый поиск (Spotlight)</span>
              <kbd className="px-2 py-0.5 rounded bg-white/10 text-white font-mono">⌘ K</kbd>
            </div>
            <div className="flex items-center justify-between p-2 rounded-lg bg-black/20 border border-white/5">
              <span className="text-neutral-400">Закрыть любое окно / модалку</span>
              <kbd className="px-2 py-0.5 rounded bg-white/10 text-white font-mono">Esc</kbd>
            </div>
            <div className="flex items-center justify-between p-2 rounded-lg bg-black/20 border border-white/5">
              <span className="text-neutral-400">Перейти на Дашборд</span>
              <kbd className="px-2 py-0.5 rounded bg-white/10 text-white font-mono">⌘ 1</kbd>
            </div>
            <div className="flex items-center justify-between p-2 rounded-lg bg-black/20 border border-white/5">
              <span className="text-neutral-400">Перейти в Библиотеку</span>
              <kbd className="px-2 py-0.5 rounded bg-white/10 text-white font-mono">⌘ 2</kbd>
            </div>
          </div>
        </div>

        {/* О приложении */}
        <div className="pt-2 flex items-center justify-between text-xs text-neutral-500">
          <span>BookParadise Desktop macOS v2.12.0 (Build 20)</span>
          <span className="flex items-center gap-1 text-emerald-400">
            <CheckCircle className="w-3.5 h-3.5" /> Актуальная сборка
          </span>
        </div>
      </div>
    </ModalWrapper>
  );
};
