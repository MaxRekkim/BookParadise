import React, { useState } from 'react';
import { Book, Quote, Note, Goal, UserPersonalization, AppThemeId, AppIconId, FontFamilyPreference, FontSizePreference } from '../../types';
import { ModalWrapper } from './ModalWrapper';
import { storageService } from '../../services/storage';
import { soundscape } from '../../services/soundscape';
import {
  Palette,
  Type,
  Flame,
  CloudRain,
  BookOpen,
  Coffee,
  Volume2,
  Send,
  Sparkles,
  Download,
  Upload,
  FileText,
  Command,
  CheckCircle,
  Check,
  Trophy,
  Clock,
  Sliders,
  Layers,
  HelpCircle,
  Smartphone,
  Cloud,
} from 'lucide-react';

interface SettingsModalProps {
  isOpen: boolean;
  onClose: () => void;
  books: Book[];
  quotes: Quote[];
  notes: Note[];
  goal: Goal;
  onUpdateGoal: (goal: Goal) => void;
  onImportBooks: (imported: Book[]) => void;
  personalization: UserPersonalization;
  onUpdatePersonalization: (settings: UserPersonalization) => void;
  onPlaySoundscape?: (mode: 'fireplace' | 'rain' | 'library' | 'cafe') => void;
  onStopSoundscape?: () => void;
  soundscapePlaying?: boolean;
}

type SettingsTab = 'appearance' | 'habits' | 'soundscape' | 'kindle' | 'sync' | 'shortcuts';

export const SettingsModal: React.FC<SettingsModalProps> = ({
  isOpen,
  onClose,
  books,
  quotes,
  notes,
  goal,
  onUpdateGoal,
  onImportBooks,
  personalization,
  onUpdatePersonalization,
  onPlaySoundscape,
  onStopSoundscape,
  soundscapePlaying = false,
}) => {
  const [activeTab, setActiveTab] = useState<SettingsTab>('appearance');
  const [sheetsUrl, setSheetsUrl] = useState(storageService.getSheetsUrl());
  const [kindleInput, setKindleInput] = useState(personalization.kindleEmail || '');
  const [copiedSheets, setCopiedSheets] = useState(false);
  const [kindleSaved, setKindleSaved] = useState(false);
  const [kindleTestSent, setKindleTestSent] = useState(false);
  const [soundVolume, setSoundVolume] = useState(personalization.soundscapeVolume ?? 0.4);

  // Обработчик обновления части настроек персонализации
  const updateSetting = <K extends keyof UserPersonalization>(key: K, value: UserPersonalization[K]) => {
    const updated = { ...personalization, [key]: value };
    onUpdatePersonalization(updated);
    storageService.savePersonalization(updated);
  };

  const handleExportMarkdown = () => {
    const md = storageService.exportMarkdown(books, quotes, notes);
    storageService.downloadFile(md, 'Каталог_Книжный_Рай.md', 'text/markdown;charset=utf-8');
  };

  const handleExportJSON = () => {
    const data = JSON.stringify({ books, quotes, notes, personalization, goal, version: '2.12.0' }, null, 2);
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
        }
        if (parsed.personalization) {
          onUpdatePersonalization(parsed.personalization);
          storageService.savePersonalization(parsed.personalization);
        }
        if (parsed.goal) {
          onUpdateGoal(parsed.goal);
        }
        alert(`Успешно восстановлено: ${parsed.books?.length || 0} книг, настройки и цели!`);
      } catch {
        alert('Ошибка при чтении файла бэкапа JSON');
      }
    };
    reader.readAsText(file);
  };

  const themeOptions: Array<{
    id: AppThemeId;
    title: string;
    subtitle: string;
    accent: string;
    dotColor: string;
    bgPreview: string;
  }> = [
    {
      id: 'emerald',
      title: 'Изумрудный бор',
      subtitle: 'Классическая библиотека с зелеными лампами и хвоей',
      accent: 'border-emerald-500 text-emerald-400',
      dotColor: 'bg-emerald-500',
      bgPreview: 'from-emerald-950/80 to-[#0d1210]',
    },
    {
      id: 'wine',
      title: 'Винный бархат',
      subtitle: 'Глубокие тона бордо, марсала и королевского золота',
      accent: 'border-rose-500 text-rose-400',
      dotColor: 'bg-rose-500',
      bgPreview: 'from-rose-950/80 to-[#12080b]',
    },
    {
      id: 'midnight',
      title: 'Полуночный оксфорд',
      subtitle: 'Глубокий чернильный индиго для комфортного ночного чтения',
      accent: 'border-indigo-500 text-indigo-400',
      dotColor: 'bg-indigo-500',
      bgPreview: 'from-indigo-950/80 to-[#090a14]',
    },
    {
      id: 'amber',
      title: 'Книжный янтарь',
      subtitle: 'Теплая янтарно-кофейная гамма с золотистым акцентом',
      accent: 'border-amber-500 text-amber-400',
      dotColor: 'bg-amber-500',
      bgPreview: 'from-amber-950/80 to-[#120d08]',
    },
    {
      id: 'cyberpunk',
      title: 'Киберпанк неон',
      subtitle: 'Футуристический дуэт фуксии, неона и циана',
      accent: 'border-fuchsia-500 text-fuchsia-400',
      dotColor: 'bg-fuchsia-500',
      bgPreview: 'from-fuchsia-950/80 to-[#0d0614]',
    },
    {
      id: 'dark',
      title: 'OLED Обсидиан',
      subtitle: 'Минималистичный глубокий матовый черный монохром',
      accent: 'border-neutral-400 text-neutral-200',
      dotColor: 'bg-neutral-300',
      bgPreview: 'from-neutral-900 to-black',
    },
    {
      id: 'autoDayNight',
      title: 'Автосмена День/Ночь',
      subtitle: 'Днем (07:00–19:00) Винный бархат, ночью Полуночный оксфорд',
      accent: 'border-purple-400 text-purple-300',
      dotColor: 'bg-gradient-to-r from-rose-500 to-indigo-500',
      bgPreview: 'from-rose-950/40 via-purple-950/40 to-indigo-950/40',
    },
  ];

  const iconOptions: Array<{
    id: AppIconId;
    name: string;
    subtitle: string;
    gradient: string;
    border: string;
  }> = [
    {
      id: 'emerald',
      name: 'Изумрудный Лес',
      subtitle: 'Фирменный хвойный macOS стиль',
      gradient: 'from-emerald-700 via-teal-800 to-emerald-950',
      border: 'border-emerald-500/40',
    },
    {
      id: 'wine',
      name: 'Королевский Бордо',
      subtitle: 'Благородный винный бархат и золото',
      gradient: 'from-rose-900 via-rose-950 to-neutral-950',
      border: 'border-rose-500/40',
    },
    {
      id: 'midnight',
      name: 'Полночный Индиго',
      subtitle: 'Звездное небо и тишина',
      gradient: 'from-indigo-700 via-purple-900 to-slate-950',
      border: 'border-indigo-500/40',
    },
    {
      id: 'cyberpunk',
      name: 'Киберпанк Неон',
      subtitle: 'Энергичный дуэт фуксии и циана',
      gradient: 'from-fuchsia-600 via-purple-800 to-cyan-800',
      border: 'border-cyan-500/40',
    },
    {
      id: 'parchment',
      name: 'Старинный Пергамент',
      subtitle: 'Теплый кожаный переплет и крафт',
      gradient: 'from-amber-800 via-[#2e1d13] to-[#120a06]',
      border: 'border-amber-500/40',
    },
    {
      id: 'dark',
      name: 'OLED Obsidian',
      subtitle: 'Лаконичный матовый черный монохром',
      gradient: 'from-neutral-800 via-neutral-900 to-black',
      border: 'border-neutral-500/40',
    },
  ];

  const fontOptions: Array<{ id: FontFamilyPreference; name: string; sample: string; desc: string }> = [
    { id: 'sans', name: 'San Francisco (Apple System)', sample: 'Книжный Рай 2026', desc: 'Четкий, современный системный гротеск Apple' },
    { id: 'serif', name: 'New York / Antiqua (Книжный)', sample: 'Великие романы человечества', desc: 'Элегантный книжный шрифт с засечками для чтения' },
    { id: 'mono', name: 'JetBrains Mono / Code', sample: 'ReadPage(342, total: 512)', desc: 'Моноширинный технический шрифт' },
    { id: 'rounded', name: 'SF Pro Rounded (Мягкий)', sample: 'Уютное чтение вечерами', desc: 'Скругленный дружелюбный интерфейс' },
  ];

  const sizeOptions: Array<{ id: FontSizePreference; label: string; px: string }> = [
    { id: 'compact', label: 'Компактный', px: '14 px' },
    { id: 'normal', label: 'Стандартный', px: '15 px' },
    { id: 'comfortable', label: 'Комфортный', px: '16 px' },
    { id: 'large', label: 'Крупный', px: '17 px' },
  ];

  const soundscapes = [
    { id: 'fireplace' as const, title: 'Треск камина', icon: Flame, color: 'text-amber-400' },
    { id: 'rain' as const, title: 'Дождь за окном', icon: CloudRain, color: 'text-blue-400' },
    { id: 'library' as const, title: 'Старинная библиотека', icon: BookOpen, color: 'text-emerald-400' },
    { id: 'cafe' as const, title: 'Уютная кофейня', icon: Coffee, color: 'text-stone-300' },
  ];

  return (
    <ModalWrapper
      isOpen={isOpen}
      onClose={onClose}
      title="Настройки и Персонализация"
      subtitle="Цветовые схемы, шрифты, иконки, саундскейпы, Kindle и синхронизация"
      maxWidth="max-w-4xl"
    >
      <div className="flex flex-col md:flex-row gap-6 min-h-[520px]">
        {/* Навигационная колонка табов */}
        <div className="w-full md:w-56 shrink-0 space-y-1 border-b md:border-b-0 md:border-r border-white/10 pb-4 md:pb-0 md:pr-4">
          <button
            type="button"
            onClick={() => setActiveTab('appearance')}
            className={`w-full flex items-center gap-2.5 px-3 py-2.5 rounded-xl text-xs font-semibold transition-all cursor-pointer ${
              activeTab === 'appearance'
                ? 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/30 shadow-sm'
                : 'text-neutral-400 hover:text-white hover:bg-white/5'
            }`}
          >
            <Palette className="w-4 h-4 shrink-0" />
            <span>Оформление и Темы</span>
          </button>

          <button
            type="button"
            onClick={() => setActiveTab('habits')}
            className={`w-full flex items-center gap-2.5 px-3 py-2.5 rounded-xl text-xs font-semibold transition-all cursor-pointer ${
              activeTab === 'habits'
                ? 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/30 shadow-sm'
                : 'text-neutral-400 hover:text-white hover:bg-white/5'
            }`}
          >
            <Trophy className="w-4 h-4 shrink-0" />
            <span>Цели и Привычки</span>
          </button>

          <button
            type="button"
            onClick={() => setActiveTab('soundscape')}
            className={`w-full flex items-center gap-2.5 px-3 py-2.5 rounded-xl text-xs font-semibold transition-all cursor-pointer ${
              activeTab === 'soundscape'
                ? 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/30 shadow-sm'
                : 'text-neutral-400 hover:text-white hover:bg-white/5'
            }`}
          >
            <Volume2 className="w-4 h-4 shrink-0" />
            <span>Атмосфера звуков</span>
          </button>

          <button
            type="button"
            onClick={() => setActiveTab('kindle')}
            className={`w-full flex items-center gap-2.5 px-3 py-2.5 rounded-xl text-xs font-semibold transition-all cursor-pointer ${
              activeTab === 'kindle'
                ? 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/30 shadow-sm'
                : 'text-neutral-400 hover:text-white hover:bg-white/5'
            }`}
          >
            <Smartphone className="w-4 h-4 shrink-0" />
            <span>Отправка на Kindle</span>
          </button>

          <button
            type="button"
            onClick={() => setActiveTab('sync')}
            className={`w-full flex items-center gap-2.5 px-3 py-2.5 rounded-xl text-xs font-semibold transition-all cursor-pointer ${
              activeTab === 'sync'
                ? 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/30 shadow-sm'
                : 'text-neutral-400 hover:text-white hover:bg-white/5'
            }`}
          >
            <Cloud className="w-4 h-4 shrink-0" />
            <span>Синхронизация и Данные</span>
          </button>

          <button
            type="button"
            onClick={() => setActiveTab('shortcuts')}
            className={`w-full flex items-center gap-2.5 px-3 py-2.5 rounded-xl text-xs font-semibold transition-all cursor-pointer ${
              activeTab === 'shortcuts'
                ? 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/30 shadow-sm'
                : 'text-neutral-400 hover:text-white hover:bg-white/5'
            }`}
          >
            <Command className="w-4 h-4 shrink-0" />
            <span>Горячие клавиши</span>
          </button>

          <div className="pt-8 px-2 text-[11px] text-neutral-500 space-y-1">
            <p className="font-semibold text-neutral-400">BookParadise macOS</p>
            <p>Версия 2.12.0 (Build 20)</p>
            <p className="text-emerald-500 flex items-center gap-1">
              <CheckCircle className="w-3 h-3" /> Нативный движок
            </p>
          </div>
        </div>

        {/* Контент активного таба */}
        <div className="flex-1 overflow-y-auto max-h-[600px] pr-2 space-y-6">
          {/* TAB 1: ОФОРМЛЕНИЕ И ТЕМЫ */}
          {activeTab === 'appearance' && (
            <div className="space-y-6 animate-in fade-in duration-200">
              {/* Цветовая тема */}
              <div>
                <div className="flex items-center gap-2 mb-3">
                  <Palette className="w-4 h-4 text-emerald-400" />
                  <h3 className="text-sm font-bold text-white">Цветовая тема оформления</h3>
                </div>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                  {themeOptions.map((t) => {
                    const isSelected = personalization.theme === t.id;
                    return (
                      <button
                        key={t.id}
                        type="button"
                        onClick={() => updateSetting('theme', t.id)}
                        className={`flex items-start gap-3 p-3.5 rounded-xl border text-left transition-all cursor-pointer ${
                          isSelected
                            ? `bg-gradient-to-br ${t.bgPreview} border-emerald-500 shadow-md ring-1 ring-emerald-500/50`
                            : 'bg-white/[0.02] border-white/10 hover:bg-white/[0.05]'
                        }`}
                      >
                        <span className={`w-4 h-4 rounded-full ${t.dotColor} shrink-0 mt-0.5 shadow-sm`} />
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center justify-between">
                            <span className="text-xs font-bold text-white">{t.title}</span>
                            {isSelected && <Check className="w-3.5 h-3.5 text-emerald-400" />}
                          </div>
                          <span className="text-[11px] text-neutral-400 leading-tight block mt-1">
                            {t.subtitle}
                          </span>
                        </div>
                      </button>
                    );
                  })}
                </div>
              </div>

              {/* Типографика и шрифты */}
              <div className="pt-4 border-t border-white/10">
                <div className="flex items-center gap-2 mb-3">
                  <Type className="w-4 h-4 text-teal-400" />
                  <h3 className="text-sm font-bold text-white">Шрифт и читабельность</h3>
                </div>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-3 mb-4">
                  {fontOptions.map((f) => {
                    const isSelected = personalization.fontFamily === f.id;
                    return (
                      <button
                        key={f.id}
                        type="button"
                        onClick={() => updateSetting('fontFamily', f.id)}
                        className={`p-3 rounded-xl border text-left transition-all cursor-pointer ${
                          isSelected
                            ? 'bg-white/10 border-emerald-500 shadow-sm ring-1 ring-emerald-500/50'
                            : 'bg-white/[0.02] border-white/10 hover:bg-white/[0.05]'
                        }`}
                      >
                        <div className="flex items-center justify-between">
                          <span className="text-xs font-bold text-white">{f.name}</span>
                          {isSelected && <Check className="w-3.5 h-3.5 text-emerald-400" />}
                        </div>
                        <span className="text-sm text-neutral-200 block my-1 font-medium">{f.sample}</span>
                        <span className="text-[10px] text-neutral-400 block">{f.desc}</span>
                      </button>
                    );
                  })}
                </div>

                {/* Размер текста */}
                <div className="flex items-center justify-between p-3 rounded-xl bg-white/[0.02] border border-white/10">
                  <span className="text-xs font-semibold text-white">Размер интерфейса</span>
                  <div className="flex items-center gap-1.5 bg-black/40 p-1 rounded-lg border border-white/5">
                    {sizeOptions.map((s) => (
                      <button
                        key={s.id}
                        type="button"
                        onClick={() => updateSetting('fontSize', s.id)}
                        className={`px-2.5 py-1 rounded-md text-[11px] font-semibold transition-all cursor-pointer ${
                          personalization.fontSize === s.id
                            ? 'bg-emerald-500 text-white shadow-sm'
                            : 'text-neutral-400 hover:text-white'
                        }`}
                      >
                        {s.label} ({s.px})
                      </button>
                    ))}
                  </div>
                </div>
              </div>

              {/* Стиль карточек в библиотеке */}
              <div className="pt-4 border-t border-white/10">
                <div className="flex items-center gap-2 mb-3">
                  <Layers className="w-4 h-4 text-amber-400" />
                  <h3 className="text-sm font-bold text-white">Стиль карточек книг</h3>
                </div>
                <div className="grid grid-cols-2 gap-3">
                  <button
                    type="button"
                    onClick={() => updateSetting('cardStyle', 'bento')}
                    className={`p-3 rounded-xl border text-left transition-all cursor-pointer ${
                      personalization.cardStyle === 'bento'
                        ? 'bg-white/10 border-emerald-500 ring-1 ring-emerald-500/50'
                        : 'bg-white/[0.02] border-white/10 hover:bg-white/[0.05]'
                    }`}
                  >
                    <div className="flex items-center justify-between">
                      <span className="text-xs font-bold text-white">Bento Modern Dashboard</span>
                      {personalization.cardStyle === 'bento' && <Check className="w-3.5 h-3.5 text-emerald-400" />}
                    </div>
                    <span className="text-[11px] text-neutral-400 block mt-1">
                      Минималистичные карточки с прогресс-баром и фокусом на статистику
                    </span>
                  </button>

                  <button
                    type="button"
                    onClick={() => updateSetting('cardStyle', '3d')}
                    className={`p-3 rounded-xl border text-left transition-all cursor-pointer ${
                      personalization.cardStyle === '3d'
                        ? 'bg-white/10 border-emerald-500 ring-1 ring-emerald-500/50'
                        : 'bg-white/[0.02] border-white/10 hover:bg-white/[0.05]'
                    }`}
                  >
                    <div className="flex items-center justify-between">
                      <span className="text-xs font-bold text-white">3D Книжная полка</span>
                      {personalization.cardStyle === '3d' && <Check className="w-3.5 h-3.5 text-emerald-400" />}
                    </div>
                    <span className="text-[11px] text-neutral-400 block mt-1">
                      Объемные обложки с золотистым тиснением корешка и мягкой тенью
                    </span>
                  </button>
                </div>
              </div>

              {/* Иконка приложения */}
              <div className="pt-4 border-t border-white/10">
                <div className="flex items-center gap-2 mb-3">
                  <Sparkles className="w-4 h-4 text-purple-400" />
                  <h3 className="text-sm font-bold text-white">Иконка приложения</h3>
                </div>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                  {iconOptions.map((opt) => {
                    const isSelected = personalization.appIcon === opt.id;
                    return (
                      <button
                        key={opt.id}
                        type="button"
                        onClick={() => updateSetting('appIcon', opt.id)}
                        className={`flex items-center gap-3 p-2.5 rounded-xl border text-left transition-all cursor-pointer ${
                          isSelected
                            ? `bg-white/10 ${opt.border} ring-1 ring-white/20 shadow-sm`
                            : 'bg-white/[0.02] border-white/5 hover:bg-white/[0.05]'
                        }`}
                      >
                        <div className={`w-10 h-10 rounded-xl bg-gradient-to-br ${opt.gradient} border border-white/20 flex items-center justify-center shrink-0 shadow-md`}>
                          <BookOpen className="w-5 h-5 text-white drop-shadow-md" />
                        </div>
                        <div className="flex-1 min-w-0">
                          <span className="text-xs font-bold text-white truncate block">{opt.name}</span>
                          <span className="text-[10px] text-neutral-400 truncate block">{opt.subtitle}</span>
                        </div>
                        {isSelected && <Check className="w-4 h-4 text-emerald-400 shrink-0" />}
                      </button>
                    );
                  })}
                </div>
              </div>
            </div>
          )}

          {/* TAB 2: ЦЕЛИ И ПРИВЫЧКИ */}
          {activeTab === 'habits' && (
            <div className="space-y-6 animate-in fade-in duration-200">
              {/* Годовой вызов */}
              <div className="p-4 rounded-xl bg-white/[0.02] border border-white/10 space-y-4">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <Trophy className="w-5 h-5 text-amber-400" />
                    <div>
                      <h3 className="text-sm font-bold text-white">Книжный вызов {goal.year} года</h3>
                      <span className="text-xs text-neutral-400">Сколько книг вы планируете прочесть за год?</span>
                    </div>
                  </div>
                  <div className="flex items-center gap-2">
                    {[12, 24, 36, 52, 100].map((num) => (
                      <button
                        key={num}
                        type="button"
                        onClick={() => onUpdateGoal({ ...goal, targetBooks: num })}
                        className={`px-2.5 py-1 rounded-lg text-xs font-bold transition-all cursor-pointer ${
                          goal.targetBooks === num
                            ? 'bg-amber-500 text-black shadow-md'
                            : 'bg-white/5 text-neutral-300 hover:bg-white/10'
                        }`}
                      >
                        {num}
                      </button>
                    ))}
                  </div>
                </div>

                <div className="flex items-center gap-4 pt-2">
                  <span className="text-xs text-neutral-400">Произвольная цель:</span>
                  <input
                    type="number"
                    min={1}
                    max={500}
                    value={goal.targetBooks}
                    onChange={(e) => onUpdateGoal({ ...goal, targetBooks: Math.max(1, Number(e.target.value)) })}
                    className="w-24 px-3 py-1.5 bg-neutral-900 border border-white/10 rounded-lg text-xs font-bold text-white focus:outline-none focus:border-amber-500 text-center"
                  />
                  <span className="text-xs text-neutral-400">книг за {goal.year} год</span>
                </div>
              </div>

              {/* Дневная норма чтения */}
              <div className="p-4 rounded-xl bg-white/[0.02] border border-white/10 space-y-4">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <Clock className="w-5 h-5 text-emerald-400" />
                    <div>
                      <h3 className="text-sm font-bold text-white">Дневная норма чтения</h3>
                      <span className="text-xs text-neutral-400">Ежедневная цель для поддержания непрерывного стрика</span>
                    </div>
                  </div>
                  <div className="flex items-center gap-1.5">
                    {[15, 30, 45, 60].map((mins) => (
                      <button
                        key={mins}
                        type="button"
                        onClick={() => updateSetting('dailyGoalMinutes', mins)}
                        className={`px-3 py-1 rounded-lg text-xs font-bold transition-all cursor-pointer ${
                          personalization.dailyGoalMinutes === mins
                            ? 'bg-emerald-500 text-white shadow-md'
                            : 'bg-white/5 text-neutral-300 hover:bg-white/10'
                        }`}
                      >
                        {mins} мин
                      </button>
                    ))}
                  </div>
                </div>
              </div>

              {/* Длительность спринта таймера */}
              <div className="p-4 rounded-xl bg-white/[0.02] border border-white/10 space-y-4">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <Sliders className="w-5 h-5 text-indigo-400" />
                    <div>
                      <h3 className="text-sm font-bold text-white">Спринт концентрации (Pomodoro)</h3>
                      <span className="text-xs text-neutral-400">Длительность непрерывного чтения без отвлечений</span>
                    </div>
                  </div>
                  <div className="flex items-center gap-1.5">
                    {[15, 25, 45, 60].map((mins) => (
                      <button
                        key={mins}
                        type="button"
                        onClick={() => updateSetting('timerSprintMinutes', mins)}
                        className={`px-3 py-1 rounded-lg text-xs font-bold transition-all cursor-pointer ${
                          personalization.timerSprintMinutes === mins
                            ? 'bg-indigo-500 text-white shadow-md'
                            : 'bg-white/5 text-neutral-300 hover:bg-white/10'
                        }`}
                      >
                        {mins} мин
                      </button>
                    ))}
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* TAB 3: АТМОСФЕРА ЗВУКОВ */}
          {activeTab === 'soundscape' && (
            <div className="space-y-6 animate-in fade-in duration-200">
              <div className="p-4 rounded-xl bg-white/[0.02] border border-white/10 space-y-4">
                <div className="flex items-center justify-between">
                  <div>
                    <h3 className="text-sm font-bold text-white">Фоновый звук по умолчанию</h3>
                    <span className="text-xs text-neutral-400">
                      Какой звуковой ландшафт включать при запуске таймера чтения
                    </span>
                  </div>
                  {soundscapePlaying && (
                    <button
                      type="button"
                      onClick={() => onStopSoundscape?.()}
                      className="px-3 py-1 bg-rose-500/20 text-rose-400 border border-rose-500/30 rounded-lg text-xs font-semibold cursor-pointer hover:bg-rose-500/30"
                    >
                      Остановить звук
                    </button>
                  )}
                </div>

                <div className="grid grid-cols-2 gap-3 pt-1">
                  {soundscapes.map((s) => {
                    const isDefault = personalization.soundscapeDefaultMode === s.id;
                    const Icon = s.icon;
                    return (
                      <div
                        key={s.id}
                        className={`p-3.5 rounded-xl border flex items-center justify-between transition-all ${
                          isDefault
                            ? 'bg-white/10 border-emerald-500 ring-1 ring-emerald-500/40 shadow-sm'
                            : 'bg-white/[0.02] border-white/5 hover:bg-white/[0.05]'
                        }`}
                      >
                        <div className="flex items-center gap-3">
                          <Icon className={`w-5 h-5 ${s.color}`} />
                          <div>
                            <span className="text-xs font-bold text-white block">{s.title}</span>
                            <span className="text-[10px] text-neutral-400">Процедурный синтез</span>
                          </div>
                        </div>
                        <div className="flex items-center gap-2">
                          <button
                            type="button"
                            onClick={() => {
                              updateSetting('soundscapeDefaultMode', s.id);
                              onPlaySoundscape?.(s.id);
                            }}
                            className="px-2.5 py-1 bg-white/10 hover:bg-white/20 text-white rounded-lg text-xs font-semibold cursor-pointer transition-colors"
                          >
                            Слушать
                          </button>
                        </div>
                      </div>
                    );
                  })}
                </div>

                {/* Ползунок громкости */}
                <div className="pt-4 border-t border-white/10 space-y-2">
                  <div className="flex items-center justify-between">
                    <span className="text-xs font-semibold text-white">Громкость звукового фона</span>
                    <span className="text-xs font-mono text-emerald-400 font-bold">{Math.round(soundVolume * 100)}%</span>
                  </div>
                  <input
                    type="range"
                    min={0}
                    max={1}
                    step={0.01}
                    value={soundVolume}
                    onChange={(e) => {
                      const v = Number(e.target.value);
                      setSoundVolume(v);
                      soundscape.setVolume(v);
                      updateSetting('soundscapeVolume', v);
                    }}
                    className="w-full accent-emerald-500 cursor-pointer h-2 bg-neutral-800 rounded-lg"
                  />
                </div>
              </div>
            </div>
          )}

          {/* TAB 4: ОТПРАВКА НА KINDLE */}
          {activeTab === 'kindle' && (
            <div className="space-y-6 animate-in fade-in duration-200">
              <div className="p-5 rounded-xl bg-white/[0.02] border border-white/10 space-y-4">
                <div className="flex items-center gap-2">
                  <Smartphone className="w-5 h-5 text-emerald-400" />
                  <h3 className="text-sm font-bold text-white">Настройка Kindle e-Reader</h3>
                </div>
                <p className="text-xs text-neutral-400 leading-relaxed">
                  Укажите ваш персональный почтовый адрес читалки Amazon Kindle (вида <code className="text-neutral-200 bg-black/40 px-1 py-0.5 rounded">username@kindle.com</code>). При нажатии «Отправить на Kindle» в карточке книги подготовленный файл или выжимка отправится прямо на устройство.
                </p>

                <div className="space-y-2">
                  <label className="text-xs font-semibold text-neutral-300 block">Email читалки Kindle:</label>
                  <div className="flex gap-2">
                    <input
                      type="email"
                      placeholder="myname@kindle.com"
                      value={kindleInput}
                      onChange={(e) => setKindleInput(e.target.value)}
                      className="flex-1 px-3.5 py-2 bg-neutral-900 border border-white/10 rounded-lg text-xs text-white focus:outline-none focus:border-emerald-500"
                    />
                    <button
                      type="button"
                      onClick={() => {
                        updateSetting('kindleEmail', kindleInput);
                        setKindleSaved(true);
                        setTimeout(() => setKindleSaved(false), 2000);
                      }}
                      className="px-4 py-2 bg-emerald-600 hover:bg-emerald-500 text-xs font-semibold text-white rounded-lg transition-colors cursor-pointer"
                    >
                      {kindleSaved ? 'Сохранено!' : 'Сохранить'}
                    </button>
                  </div>
                </div>

                {/* Инструкция по белому списку Amazon */}
                <div className="p-3.5 rounded-xl bg-amber-500/10 border border-amber-500/20 text-xs text-amber-200/90 space-y-1.5 leading-relaxed">
                  <div className="font-bold flex items-center gap-1.5 text-amber-400">
                    <HelpCircle className="w-4 h-4" /> Важно для доставки на ридер:
                  </div>
                  <p>
                    В личном кабинете Amazon (раздел <em>Manage Your Content and Devices → Preferences → Personal Document Settings</em>) добавьте вашу личную электронную почту в список <strong>Approved Personal Document E-mail List</strong>, иначе Amazon заблокирует входящие книги.
                  </p>
                </div>

                <div className="pt-2">
                  <button
                    type="button"
                    onClick={() => {
                      if (!kindleInput) {
                        alert('Сначала укажите адрес @kindle.com');
                        return;
                      }
                      setKindleTestSent(true);
                      setTimeout(() => setKindleTestSent(false), 2500);
                    }}
                    className="flex items-center gap-2 px-4 py-2 bg-white/5 hover:bg-white/10 border border-white/10 text-neutral-200 text-xs font-semibold rounded-lg transition-colors cursor-pointer"
                  >
                    <Send className="w-4 h-4 text-emerald-400" />
                    <span>{kindleTestSent ? 'Тестовое письмо сформировано!' : 'Проверить отправку каталога'}</span>
                  </button>
                </div>
              </div>
            </div>
          )}

          {/* TAB 5: СИНХРОНИЗАЦИЯ И ДАННЫЕ */}
          {activeTab === 'sync' && (
            <div className="space-y-6 animate-in fade-in duration-200">
              {/* Экспорт и бэкапы */}
              <div className="p-5 rounded-xl bg-white/[0.02] border border-white/10 space-y-4">
                <div className="flex items-center gap-2">
                  <FileText className="w-5 h-5 text-emerald-400" />
                  <h3 className="text-sm font-bold text-white">Экспорт в Markdown (Obsidian / Notion / PKM)</h3>
                </div>
                <p className="text-xs text-neutral-400 leading-relaxed">
                  Выгрузите весь каталог книг, статус, авторов, цитаты и заметки в один структурированный Markdown-файл для персональной базы знаний.
                </p>
                <div className="flex flex-wrap gap-3">
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
              <div className="p-5 rounded-xl bg-white/[0.02] border border-white/10 space-y-4">
                <div className="flex items-center gap-2">
                  <Sparkles className="w-5 h-5 text-teal-400" />
                  <h3 className="text-sm font-bold text-white">Google Таблицы / Облачная база</h3>
                </div>
                <p className="text-xs text-neutral-400 leading-relaxed">
                  Подключите личную Google Таблицу через Apps Script веб-приложение для синхронизации между мобильным телефоном и компьютером.
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
                      setCopiedSheets(true);
                      setTimeout(() => setCopiedSheets(false), 2000);
                    }}
                    className="px-4 py-2 bg-emerald-600 hover:bg-emerald-500 text-xs font-semibold text-white rounded-lg transition-colors cursor-pointer"
                  >
                    {copiedSheets ? 'Сохранено!' : 'Сохранить'}
                  </button>
                </div>
              </div>
            </div>
          )}

          {/* TAB 6: ГОРЯЧИЕ КЛАВИШИ */}
          {activeTab === 'shortcuts' && (
            <div className="space-y-4 animate-in fade-in duration-200">
              <div className="flex items-center gap-2 mb-2">
                <Command className="w-5 h-5 text-neutral-400" />
                <h3 className="text-sm font-bold text-white">Горячие клавиши macOS</h3>
              </div>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-3 text-xs">
                <div className="flex items-center justify-between p-3 rounded-xl bg-white/[0.02] border border-white/5">
                  <span className="text-neutral-300 font-medium">Быстрый поиск (Command Palette)</span>
                  <kbd className="px-2.5 py-1 rounded-lg bg-white/10 text-white font-mono font-bold shadow-sm">⌘ K</kbd>
                </div>
                <div className="flex items-center justify-between p-3 rounded-xl bg-white/[0.02] border border-white/5">
                  <span className="text-neutral-300 font-medium">Закрыть любое окно / модалку</span>
                  <kbd className="px-2.5 py-1 rounded-lg bg-white/10 text-white font-mono font-bold shadow-sm">Esc</kbd>
                </div>
                <div className="flex items-center justify-between p-3 rounded-xl bg-white/[0.02] border border-white/5">
                  <span className="text-neutral-300 font-medium">Перейти на Дашборд</span>
                  <kbd className="px-2.5 py-1 rounded-lg bg-white/10 text-white font-mono font-bold shadow-sm">⌘ 1</kbd>
                </div>
                <div className="flex items-center justify-between p-3 rounded-xl bg-white/[0.02] border border-white/5">
                  <span className="text-neutral-300 font-medium">Перейти в Библиотеку</span>
                  <kbd className="px-2.5 py-1 rounded-lg bg-white/10 text-white font-mono font-bold shadow-sm">⌘ 2</kbd>
                </div>
                <div className="flex items-center justify-between p-3 rounded-xl bg-white/[0.02] border border-white/5">
                  <span className="text-neutral-300 font-medium">Книжный вызов 2026</span>
                  <kbd className="px-2.5 py-1 rounded-lg bg-white/10 text-white font-mono font-bold shadow-sm">⌘ 3</kbd>
                </div>
                <div className="flex items-center justify-between p-3 rounded-xl bg-white/[0.02] border border-white/5">
                  <span className="text-neutral-300 font-medium">Дневник заметок и цитаты</span>
                  <kbd className="px-2.5 py-1 rounded-lg bg-white/10 text-white font-mono font-bold shadow-sm">⌘ 4</kbd>
                </div>
                <div className="flex items-center justify-between p-3 rounded-xl bg-white/[0.02] border border-white/5">
                  <span className="text-neutral-300 font-medium">Атмосферный саундскейп</span>
                  <kbd className="px-2.5 py-1 rounded-lg bg-white/10 text-white font-mono font-bold shadow-sm">⌘ 5</kbd>
                </div>
                <div className="flex items-center justify-between p-3 rounded-xl bg-white/[0.02] border border-white/5">
                  <span className="text-neutral-300 font-medium">Быстрое добавление книги</span>
                  <kbd className="px-2.5 py-1 rounded-lg bg-white/10 text-white font-mono font-bold shadow-sm">⌘ N</kbd>
                </div>
              </div>
            </div>
          )}
        </div>
      </div>
    </ModalWrapper>
  );
};
