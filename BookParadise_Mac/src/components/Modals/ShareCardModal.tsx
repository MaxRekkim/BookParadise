import React, { useState, useRef } from 'react';
import { Book, Quote, Goal } from '../../types';
import { ModalWrapper } from './ModalWrapper';
import { Download, Copy, Check, Palette, Trophy, Quote as QuoteIcon, BookOpen } from 'lucide-react';

interface ShareCardModalProps {
  isOpen: boolean;
  onClose: () => void;
  book?: Book | null;
  quote?: Quote | null;
  goal?: Goal | null;
  books?: Book[];
}

type CardTheme = 'emerald' | 'sunset' | 'midnight' | 'cyberpunk' | 'monochrome' | 'parchment';
type CardStyle = 'spotify-player' | 'spotify-lyrics' | 'wrapped-stats' | 'vintage-ticket';
type AspectRatio = 'story' | 'square';

export const ShareCardModal: React.FC<ShareCardModalProps> = ({
  isOpen,
  onClose,
  book,
  quote,
  goal,
  books = [],
}) => {
  const [cardStyle, setCardStyle] = useState<CardStyle>(
    quote ? 'spotify-lyrics' : goal ? 'wrapped-stats' : 'spotify-player'
  );
  const [theme, setTheme] = useState<CardTheme>('emerald');
  const [aspectRatio, setAspectRatio] = useState<AspectRatio>('story');
  const [isCopied, setIsCopied] = useState(false);
  const [isRendering, setIsRendering] = useState(false);

  const previewCardRef = useRef<HTMLDivElement>(null);

  // Дефолтная книга если не выбрана
  const activeBook = book || books[0] || {
    id: 'default',
    title: 'Мастер и Маргарита',
    author: 'Михаил Булгаков',
    genre: 'Классика',
    totalPages: 480,
    readPages: 360,
    rating: 5,
    isFinished: false,
    coverURL: 'https://images.unsplash.com/photo-1544947950-fa07a98d237f?q=80&w=600&auto=format&fit=crop',
  };

  const activeQuote = quote || {
    id: 'default-q',
    text: 'Рукописи не горят.',
    bookTitle: activeBook.title,
    author: activeBook.author,
    bookId: activeBook.id,
    date: '2026',
  };

  const finishedBooksCount = books.filter((b) => b.isFinished).length;
  const totalPagesRead = books.reduce((sum, b) => sum + b.readPages, 0);

  // Цветовые градиенты
  const getThemeGradient = (t: CardTheme) => {
    switch (t) {
      case 'emerald':
        return 'from-emerald-950 via-teal-900 to-[#0e1715]';
      case 'sunset':
        return 'from-rose-950 via-amber-900 to-[#1a0f0d]';
      case 'midnight':
        return 'from-indigo-950 via-purple-950 to-[#0a0a14]';
      case 'cyberpunk':
        return 'from-fuchsia-950 via-cyan-950 to-[#0d091a]';
      case 'monochrome':
        return 'from-neutral-900 via-neutral-950 to-black';
      case 'parchment':
        return 'from-[#2c2217] via-[#1f170f] to-[#120d09]';
      default:
        return 'from-emerald-950 to-neutral-950';
    }
  };

  const getAccentColor = (t: CardTheme) => {
    switch (t) {
      case 'emerald':
        return '#10b981';
      case 'sunset':
        return '#f59e0b';
      case 'midnight':
        return '#818cf8';
      case 'cyberpunk':
        return '#06b6d4';
      case 'monochrome':
        return '#e5e5e5';
      case 'parchment':
        return '#d97706';
      default:
        return '#10b981';
    }
  };

  // Рендеринг карточки в Canvas для скачивания или копирования
  const renderCardToCanvas = async (): Promise<HTMLCanvasElement | null> => {
    const cardEl = previewCardRef.current;
    if (!cardEl) return null;

    // Ширина и высота для идеального качества Retina (@2x)
    const width = aspectRatio === 'story' ? 1080 : 1080;
    const height = aspectRatio === 'story' ? 1920 : 1080;

    const canvas = document.createElement('canvas');
    canvas.width = width;
    canvas.height = height;
    const ctx = canvas.getContext('2d');
    if (!ctx) return null;

    // Отрисовка фона
    const gradient = ctx.createLinearGradient(0, 0, width, height);
    if (theme === 'emerald') {
      gradient.addColorStop(0, '#042f2e');
      gradient.addColorStop(0.5, '#134e4a');
      gradient.addColorStop(1, '#020617');
    } else if (theme === 'sunset') {
      gradient.addColorStop(0, '#4c0519');
      gradient.addColorStop(0.5, '#78350f');
      gradient.addColorStop(1, '#1c1917');
    } else if (theme === 'midnight') {
      gradient.addColorStop(0, '#1e1b4b');
      gradient.addColorStop(0.5, '#2e1065');
      gradient.addColorStop(1, '#09090b');
    } else if (theme === 'cyberpunk') {
      gradient.addColorStop(0, '#500724');
      gradient.addColorStop(0.5, '#083344');
      gradient.addColorStop(1, '#09090b');
    } else if (theme === 'parchment') {
      gradient.addColorStop(0, '#2e1f13');
      gradient.addColorStop(0.5, '#1c130b');
      gradient.addColorStop(1, '#0d0905');
    } else {
      gradient.addColorStop(0, '#171717');
      gradient.addColorStop(1, '#000000');
    }
    ctx.fillStyle = gradient;
    ctx.fillRect(0, 0, width, height);

    // Добавляем шум/фактуру
    ctx.fillStyle = 'rgba(255, 255, 255, 0.03)';
    for (let x = 0; x < width; x += 4) {
      for (let y = 0; y < height; y += 4) {
        if (Math.random() > 0.6) {
          ctx.fillRect(x, y, 2, 2);
        }
      }
    }

    // Декоративные круги свечения
    const radial = ctx.createRadialGradient(width * 0.5, height * 0.4, 50, width * 0.5, height * 0.4, width * 0.6);
    radial.addColorStop(0, `${getAccentColor(theme)}33`);
    radial.addColorStop(1, 'transparent');
    ctx.fillStyle = radial;
    ctx.fillRect(0, 0, width, height);

    // Отрисовка логотипа вверху
    ctx.fillStyle = '#ffffff';
    ctx.font = 'bold 36px -apple-system, sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('К Н И Ж Н Ы Й   Р А Й', width / 2, 140);
    ctx.fillStyle = 'rgba(255, 255, 255, 0.5)';
    ctx.font = '22px -apple-system, sans-serif';
    ctx.fillText('READING MEMORIES • 2026', width / 2, 180);

    if (cardStyle === 'spotify-player') {
      // 1. Отрисовка обложки книги (квадратная с тенью)
      const coverSize = 540;
      const coverX = (width - coverSize) / 2;
      const coverY = 320;

      // Тень обложки
      ctx.shadowColor = 'rgba(0, 0, 0, 0.7)';
      ctx.shadowBlur = 50;
      ctx.shadowOffsetY = 25;

      ctx.fillStyle = '#1c1c24';
      ctx.beginPath();
      ctx.roundRect(coverX, coverY, coverSize, coverSize * 1.3, 30);
      ctx.fill();

      // Сброс тени
      ctx.shadowColor = 'transparent';

      // Загрузка обложки
      try {
        if (activeBook.coverURL) {
          const img = new Image();
          img.crossOrigin = 'anonymous';
          await new Promise((resolve, reject) => {
            img.onload = resolve;
            img.onerror = reject;
            img.src = activeBook.coverURL!;
          });
          ctx.save();
          ctx.beginPath();
          ctx.roundRect(coverX, coverY, coverSize, coverSize * 1.3, 30);
          ctx.clip();
          ctx.drawImage(img, coverX, coverY, coverSize, coverSize * 1.3);
          ctx.restore();
        }
      } catch (_) {
        // Фолбэк если картинка не загрузилась
        ctx.fillStyle = '#0f172a';
        ctx.beginPath();
        ctx.roundRect(coverX, coverY, coverSize, coverSize * 1.3, 30);
        ctx.fill();
      }

      // Текст названия и автора
      const textY = coverY + coverSize * 1.3 + 120;
      ctx.fillStyle = '#ffffff';
      ctx.font = 'bold 54px -apple-system, sans-serif';
      ctx.fillText(activeBook.title, width / 2, textY);

      ctx.fillStyle = 'rgba(255, 255, 255, 0.7)';
      ctx.font = '36px -apple-system, sans-serif';
      ctx.fillText(activeBook.author, width / 2, textY + 60);

      // Прогресс-бар плеера
      const barY = textY + 140;
      const barW = 720;
      const barX = (width - barW) / 2;
      ctx.fillStyle = 'rgba(255, 255, 255, 0.15)';
      ctx.beginPath();
      ctx.roundRect(barX, barY, barW, 14, 7);
      ctx.fill();

      const progress = Math.min(1, activeBook.readPages / Math.max(1, activeBook.totalPages));
      ctx.fillStyle = getAccentColor(theme);
      ctx.beginPath();
      ctx.roundRect(barX, barY, barW * progress, 14, 7);
      ctx.fill();

      // Кружок ползунка
      ctx.fillStyle = '#ffffff';
      ctx.beginPath();
      ctx.arc(barX + barW * progress, barY + 7, 14, 0, Math.PI * 2);
      ctx.fill();

      // Номера страниц (таймкоды плеера)
      ctx.font = '26px monospace';
      ctx.fillStyle = 'rgba(255, 255, 255, 0.6)';
      ctx.textAlign = 'left';
      ctx.fillText(`${activeBook.readPages} стр.`, barX, barY + 50);
      ctx.textAlign = 'right';
      ctx.fillText(`${activeBook.totalPages} стр.`, barX + barW, barY + 50);
    } else if (cardStyle === 'spotify-lyrics') {
      // 2. Отрисовка стиля Цитаты (Spotify Lyrics)
      ctx.fillStyle = getAccentColor(theme);
      ctx.font = 'bold 32px -apple-system, sans-serif';
      ctx.textAlign = 'center';
      ctx.fillText('Ц И Т А Т А   И З   К Н И Г И', width / 2, 380);

      ctx.fillStyle = '#ffffff';
      ctx.font = 'italic bold 64px serif';
      ctx.textAlign = 'center';

      // Разделение цитаты на строки
      const words = activeQuote.text.split(' ');
      let line = '';
      let y = 520;
      for (const w of words) {
        const testLine = line + w + ' ';
        const metrics = ctx.measureText(testLine);
        if (metrics.width > 820 && line !== '') {
          ctx.fillText(`«${line.trim()}»`, width / 2, y);
          line = w + ' ';
          y += 90;
        } else {
          line = testLine;
        }
      }
      ctx.fillText(`«${line.trim()}»`, width / 2, y);

      // Карточка книги внизу
      const cardY = y + 160;
      const cW = 760;
      const cX = (width - cW) / 2;
      ctx.fillStyle = 'rgba(255, 255, 255, 0.08)';
      ctx.beginPath();
      ctx.roundRect(cX, cardY, cW, 160, 24);
      ctx.fill();

      ctx.textAlign = 'left';
      ctx.fillStyle = '#ffffff';
      ctx.font = 'bold 38px -apple-system, sans-serif';
      ctx.fillText(activeQuote.bookTitle, cX + 40, cardY + 70);

      ctx.fillStyle = 'rgba(255, 255, 255, 0.6)';
      ctx.font = '28px -apple-system, sans-serif';
      ctx.fillText(activeQuote.author, cX + 40, cardY + 115);
    } else if (cardStyle === 'wrapped-stats') {
      // 3. Отрисовка стиля Spotify Wrapped / Итоги года
      ctx.fillStyle = getAccentColor(theme);
      ctx.font = '900 48px -apple-system, sans-serif';
      ctx.fillText('КНИЖНЫЕ ИТОГИ ГОДА', width / 2, 340);

      // Большой блок цифры
      ctx.fillStyle = '#ffffff';
      ctx.font = '900 160px -apple-system, sans-serif';
      ctx.fillText(`${finishedBooksCount}`, width / 2, 540);
      ctx.font = 'bold 36px -apple-system, sans-serif';
      ctx.fillStyle = 'rgba(255, 255, 255, 0.7)';
      ctx.fillText('ПРОЧИТАННЫХ КНИГ', width / 2, 600);

      // Плашки статистики
      const stats = [
        { label: 'СТРАНИЦ ПРОЧИТАНО', val: `${totalPagesRead.toLocaleString()}` },
        { label: 'ЦЕЛЬ ГОДА', val: `${Math.round((finishedBooksCount / Math.max(1, goal?.targetBooks || 35)) * 100)}% ВЫПОЛНЕНО` },
        { label: 'ГЛАВНЫЙ АРХЕТИП', val: 'НЕУТОМИМЫЙ ЧИТАТЕЛЬ' },
      ];

      let sy = 740;
      for (const s of stats) {
        ctx.fillStyle = 'rgba(255, 255, 255, 0.08)';
        ctx.beginPath();
        ctx.roundRect((width - 780) / 2, sy, 780, 140, 24);
        ctx.fill();

        ctx.textAlign = 'center';
        ctx.fillStyle = getAccentColor(theme);
        ctx.font = 'bold 22px -apple-system, sans-serif';
        ctx.fillText(s.label, width / 2, sy + 50);

        ctx.fillStyle = '#ffffff';
        ctx.font = '900 42px -apple-system, sans-serif';
        ctx.fillText(s.val, width / 2, sy + 105);

        sy += 170;
      }
    }

    // Нижняя плашка брендинга (Spotify Bar)
    ctx.textAlign = 'center';
    ctx.fillStyle = 'rgba(255, 255, 255, 0.4)';
    ctx.font = '24px -apple-system, sans-serif';
    ctx.fillText('Создано в приложении Книжный Рай', width / 2, height - 120);

    return canvas;
  };

  const handleCopyImage = async () => {
    setIsRendering(true);
    try {
      const canvas = await renderCardToCanvas();
      if (!canvas) throw new Error('Canvas render failed');

      canvas.toBlob(async (blob) => {
        if (!blob) return;
        try {
          await navigator.clipboard.write([
            new ClipboardItem({ 'image/png': blob })
          ]);
          setIsCopied(true);
          setTimeout(() => setIsCopied(false), 2500);
        } catch (_) {
          // Если буфер обмена браузера не поддерживает картинки напрямую
          handleDownloadImage();
        }
      });
    } catch (e) {
      alert('Не удалось скопировать. Нажмите "Скачать PNG".');
    } finally {
      setIsRendering(false);
    }
  };

  const handleDownloadImage = async () => {
    setIsRendering(true);
    try {
      const canvas = await renderCardToCanvas();
      if (!canvas) throw new Error('Canvas render failed');

      const url = canvas.toDataURL('image/png');
      const a = document.createElement('a');
      a.href = url;
      a.download = `BookParadise_${cardStyle}_${Date.now()}.png`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
    } catch (_) {
      alert('Ошибка при генерации изображения');
    } finally {
      setIsRendering(false);
    }
  };

  return (
    <ModalWrapper
      isOpen={isOpen}
      onClose={onClose}
      title="Поделиться книжными итогами (Spotify Card)"
      subtitle="Генерация стильной карточки для Stories, Telegram и соцсетей"
      maxWidth="max-w-5xl"
    >
      <div className="grid grid-cols-1 md:grid-cols-12 gap-8 items-start">
        {/* Левая колонка: Интерактивное превью карточки */}
        <div className="md:col-span-7 flex flex-col items-center">
          <div
            ref={previewCardRef}
            className={`relative rounded-3xl overflow-hidden shadow-2xl border border-white/10 bg-gradient-to-br ${getThemeGradient(
              theme
            )} p-6 flex flex-col justify-between transition-all duration-300 select-none ${
              aspectRatio === 'story' ? 'w-72 h-[480px]' : 'w-80 h-80'
            }`}
          >
            {/* Верхний брендинг */}
            <div className="text-center space-y-0.5">
              <span className="text-[10px] font-black tracking-widest text-white/90 uppercase block">
                К н и ж н ы й   Р а й
              </span>
              <span className="text-[9px] text-white/40 tracking-wider uppercase block">
                Reading Memories • 2026
              </span>
            </div>

            {/* Контент в зависимости от стиля */}
            {cardStyle === 'spotify-player' && (
              <div className="flex flex-col items-center my-auto space-y-4">
                {/* 3D Обложка */}
                <div className="w-36 h-48 rounded-xl overflow-hidden shadow-2xl border border-white/10 bg-neutral-900 transition-transform hover:scale-105">
                  {activeBook.coverURL ? (
                    <img src={activeBook.coverURL} alt="" className="w-full h-full object-cover" />
                  ) : (
                    <div className="w-full h-full flex items-center justify-center bg-neutral-900 text-emerald-400">
                      <BookOpen className="w-8 h-8" />
                    </div>
                  )}
                </div>

                {/* Название и автор в стиле трека Spotify */}
                <div className="text-center w-full px-2">
                  <h4 className="text-sm font-bold text-white truncate">{activeBook.title}</h4>
                  <p className="text-xs text-white/70 truncate mt-0.5">{activeBook.author}</p>
                </div>

                {/* Прогресс-бар плеера */}
                <div className="w-full px-2 space-y-1.5">
                  <div className="w-full h-1.5 bg-white/20 rounded-full overflow-hidden">
                    <div
                      className="h-full rounded-full transition-all"
                      style={{
                        width: `${Math.min(100, (activeBook.readPages / activeBook.totalPages) * 100)}%`,
                        backgroundColor: getAccentColor(theme),
                      }}
                    />
                  </div>
                  <div className="flex justify-between text-[9px] font-mono text-white/60">
                    <span>{activeBook.readPages} стр.</span>
                    <span>{activeBook.totalPages} стр.</span>
                  </div>
                </div>
              </div>
            )}

            {cardStyle === 'spotify-lyrics' && (
              <div className="flex flex-col items-center justify-center my-auto space-y-4 text-center px-2">
                <span className="text-[10px] font-bold tracking-wider uppercase" style={{ color: getAccentColor(theme) }}>
                  Цитата из книги
                </span>
                <blockquote className="text-sm font-bold text-white italic leading-relaxed line-clamp-6">
                  «{activeQuote.text}»
                </blockquote>
                <div className="p-2.5 rounded-xl bg-white/10 w-full text-left border border-white/5">
                  <span className="text-[11px] font-bold text-white block truncate">{activeQuote.bookTitle}</span>
                  <span className="text-[10px] text-white/60 block truncate">{activeQuote.author}</span>
                </div>
              </div>
            )}

            {cardStyle === 'wrapped-stats' && (
              <div className="flex flex-col items-center justify-center my-auto space-y-3 text-center w-full">
                <span className="text-[10px] font-black uppercase tracking-wider" style={{ color: getAccentColor(theme) }}>
                  Книжные итоги 2026
                </span>
                <div>
                  <span className="text-4xl font-black text-white">{finishedBooksCount}</span>
                  <span className="text-[10px] text-white/70 block font-semibold">ПРОЧИТАННЫХ КНИГ</span>
                </div>
                <div className="w-full space-y-1.5 pt-1">
                  <div className="p-2 rounded-xl bg-white/10 text-center">
                    <span className="text-[9px] text-white/60 block">СТРАНИЦ ПРОЧИТАНО</span>
                    <span className="text-xs font-bold text-white">{totalPagesRead.toLocaleString()}</span>
                  </div>
                  <div className="p-2 rounded-xl bg-white/10 text-center">
                    <span className="text-[9px] text-white/60 block">ЦЕЛЬ ГОДА</span>
                    <span className="text-xs font-bold" style={{ color: getAccentColor(theme) }}>
                      {Math.round((finishedBooksCount / Math.max(1, goal?.targetBooks || 35)) * 100)}% ВЫПОЛНЕНО
                    </span>
                  </div>
                </div>
              </div>
            )}

            {/* Нижний колонтитул */}
            <div className="text-center pt-2 border-t border-white/5">
              <span className="text-[9px] text-white/40">app.bookparadise.ru</span>
            </div>
          </div>

          <span className="text-xs text-neutral-400 mt-3">
            Превью карточки (экспорт в Retina @2x HD)
          </span>
        </div>

        {/* Правая колонка: Настройки стиля, темы и кнопки экспорта */}
        <div className="md:col-span-5 space-y-6">
          {/* 1. Выбор стиля карточки */}
          <div>
            <label className="block text-xs font-semibold text-neutral-300 mb-2">
              Стиль карточки
            </label>
            <div className="grid grid-cols-3 gap-2">
              <button
                type="button"
                onClick={() => setCardStyle('spotify-player')}
                className={`p-2.5 rounded-xl border text-left transition-all cursor-pointer ${
                  cardStyle === 'spotify-player'
                    ? 'bg-emerald-500/20 border-emerald-500/50 text-white font-semibold'
                    : 'bg-white/5 border-white/10 text-neutral-400 hover:text-white'
                }`}
              >
                <BookOpen className="w-4 h-4 mb-1 text-emerald-400" />
                <span className="text-xs block">Плеер</span>
              </button>
              <button
                type="button"
                onClick={() => setCardStyle('spotify-lyrics')}
                className={`p-2.5 rounded-xl border text-left transition-all cursor-pointer ${
                  cardStyle === 'spotify-lyrics'
                    ? 'bg-emerald-500/20 border-emerald-500/50 text-white font-semibold'
                    : 'bg-white/5 border-white/10 text-neutral-400 hover:text-white'
                }`}
              >
                <QuoteIcon className="w-4 h-4 mb-1 text-amber-400" />
                <span className="text-xs block">Цитата</span>
              </button>
              <button
                type="button"
                onClick={() => setCardStyle('wrapped-stats')}
                className={`p-2.5 rounded-xl border text-left transition-all cursor-pointer ${
                  cardStyle === 'wrapped-stats'
                    ? 'bg-emerald-500/20 border-emerald-500/50 text-white font-semibold'
                    : 'bg-white/5 border-white/10 text-neutral-400 hover:text-white'
                }`}
              >
                <Trophy className="w-4 h-4 mb-1 text-purple-400" />
                <span className="text-xs block">Итоги года</span>
              </button>
            </div>
          </div>

          {/* 2. Цветовая палитра */}
          <div>
            <label className="block text-xs font-semibold text-neutral-300 mb-2 flex items-center gap-1.5">
              <Palette className="w-3.5 h-3.5 text-emerald-400" />
              <span>Градиентный фон</span>
            </label>
            <div className="grid grid-cols-3 gap-2">
              {(
                [
                  { id: 'emerald', label: 'Изумруд', color: 'bg-emerald-500' },
                  { id: 'sunset', label: 'Закат', color: 'bg-amber-500' },
                  { id: 'midnight', label: 'Полночь', color: 'bg-indigo-500' },
                  { id: 'cyberpunk', label: 'Неон', color: 'bg-cyan-500' },
                  { id: 'parchment', label: 'Винтаж', color: 'bg-amber-800' },
                  { id: 'monochrome', label: 'Монохром', color: 'bg-neutral-600' },
                ] as const
              ).map((th) => (
                <button
                  key={th.id}
                  type="button"
                  onClick={() => setTheme(th.id)}
                  className={`flex items-center gap-2 p-2 rounded-xl border text-xs transition-all cursor-pointer ${
                    theme === th.id
                      ? 'bg-white/15 border-white/30 text-white font-semibold'
                      : 'bg-white/5 border-white/10 text-neutral-400 hover:text-white'
                  }`}
                >
                  <span className={`w-3 h-3 rounded-full ${th.color}`} />
                  <span>{th.label}</span>
                </button>
              ))}
            </div>
          </div>

          {/* 3. Формат соотношения сторон */}
          <div>
            <label className="block text-xs font-semibold text-neutral-300 mb-2">
              Формат картинки
            </label>
            <div className="flex gap-2">
              <button
                type="button"
                onClick={() => setAspectRatio('story')}
                className={`flex-1 py-2 px-3 rounded-xl border text-xs font-medium transition-all cursor-pointer ${
                  aspectRatio === 'story'
                    ? 'bg-emerald-500/20 border-emerald-500/40 text-emerald-400 font-semibold'
                    : 'bg-white/5 border-white/10 text-neutral-400 hover:text-white'
                }`}
              >
                9:16 (Stories / Telegram)
              </button>
              <button
                type="button"
                onClick={() => setAspectRatio('square')}
                className={`flex-1 py-2 px-3 rounded-xl border text-xs font-medium transition-all cursor-pointer ${
                  aspectRatio === 'square'
                    ? 'bg-emerald-500/20 border-emerald-500/40 text-emerald-400 font-semibold'
                    : 'bg-white/5 border-white/10 text-neutral-400 hover:text-white'
                }`}
              >
                1:1 (Квадрат / Пост)
              </button>
            </div>
          </div>

          {/* 4. Кнопки сохранения и копирования */}
          <div className="pt-4 border-t border-white/10 space-y-3">
            <button
              type="button"
              disabled={isRendering}
              onClick={handleCopyImage}
              className="w-full flex items-center justify-center gap-2 py-3 px-4 bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-500 hover:to-teal-500 text-white rounded-xl text-xs font-bold shadow-lg shadow-emerald-950/50 active:scale-95 transition-all cursor-pointer"
            >
              {isCopied ? (
                <>
                  <Check className="w-4 h-4 text-white" />
                  <span>Картинка скопирована в буфер!</span>
                </>
              ) : (
                <>
                  <Copy className="w-4 h-4" />
                  <span>Скопировать картинку (для вставки)</span>
                </>
              )}
            </button>

            <button
              type="button"
              disabled={isRendering}
              onClick={handleDownloadImage}
              className="w-full flex items-center justify-center gap-2 py-3 px-4 bg-white/5 hover:bg-white/10 border border-white/10 text-neutral-200 rounded-xl text-xs font-semibold active:scale-95 transition-all cursor-pointer"
            >
              <Download className="w-4 h-4" />
              <span>Скачать в формате PNG (Retina HD)</span>
            </button>
          </div>
        </div>
      </div>
    </ModalWrapper>
  );
};
