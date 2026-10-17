import React from 'react';
import { Search, Flame, Maximize2 } from 'lucide-react';
import { NavigationTab } from '../types';

interface WindowFrameProps {
  currentTab: NavigationTab;
  onOpenCommandPalette: () => void;
  soundscapeActive: boolean;
  onToggleSoundscape: () => void;
  children: React.ReactNode;
}

export const WindowFrame: React.FC<WindowFrameProps> = ({
  currentTab,
  onOpenCommandPalette,
  soundscapeActive,
  onToggleSoundscape,
  children,
}) => {
  const getTabTitle = (tab: NavigationTab) => {
    switch (tab) {
      case 'dashboard':
        return 'Главный дашборд';
      case 'library':
        return 'Библиотека книг';
      case 'challenge':
        return 'Книжный вызов 2026';
      case 'notes':
        return 'Дневник заметок и цитат';
      case 'soundscape':
        return 'Звуковые ландшафты';
      case 'settings':
        return 'Настройки';
      default:
        return 'Книжный Рай';
    }
  };

  return (
    <div className="flex-1 flex flex-col h-screen overflow-hidden bg-[#121216]">
      {/* Верхний нативный тайтлбар macOS */}
      <header className="h-12 border-b border-white/10 bg-[#16161c]/80 backdrop-blur-md flex items-center justify-between px-4 select-none shrink-0 app-drag-region">
        {/* Кнопки управления окном macOS (Traffic Lights) */}
        <div className="flex items-center gap-2 app-no-drag">
          <div className="flex items-center gap-2 mr-4">
            <button
              type="button"
              onClick={() => {
                // Если запущено в приложении macOS
                if (window.confirm('Закрыть приложение Книжный Рай?')) {
                  window.close();
                }
              }}
              className="w-3 h-3 rounded-full bg-[#ff5f56] border border-[#e0443e] hover:brightness-110 active:brightness-90 transition-all cursor-pointer"
              title="Закрыть"
            />
            <button
              type="button"
              className="w-3 h-3 rounded-full bg-[#ffbd2e] border border-[#dea123] hover:brightness-110 active:brightness-90 transition-all cursor-pointer"
              title="Свернуть"
            />
            <button
              type="button"
              onClick={() => {
                if (!document.fullscreenElement) {
                  document.documentElement.requestFullscreen().catch(() => {});
                } else {
                  document.exitFullscreen().catch(() => {});
                }
              }}
              className="w-3 h-3 rounded-full bg-[#27c93f] border border-[#1aab29] hover:brightness-110 active:brightness-90 transition-all cursor-pointer"
              title="Развернуть на весь экран"
            />
          </div>

          <div className="flex items-center gap-2 text-xs font-medium text-neutral-400">
            <span className="text-white font-semibold">{getTabTitle(currentTab)}</span>
          </div>
        </div>

        {/* Правые действия и строка быстрого поиска */}
        <div className="flex items-center gap-2.5 app-no-drag">
          {/* Индикатор звукового фона */}
          <button
            type="button"
            onClick={onToggleSoundscape}
            className={`flex items-center gap-1.5 px-2.5 py-1 rounded-lg text-xs transition-all cursor-pointer ${
              soundscapeActive
                ? 'bg-amber-500/15 text-amber-300 border border-amber-500/30'
                : 'text-neutral-400 hover:text-white hover:bg-white/5'
            }`}
            title="Переключить атмосферный звук"
          >
            <Flame className={`w-3.5 h-3.5 ${soundscapeActive ? 'text-amber-400 animate-pulse' : ''}`} />
            <span className="hidden md:inline">{soundscapeActive ? 'Камин активен' : 'Звук'}</span>
          </button>

          {/* Быстрый вызов Command Palette (⌘K) */}
          <button
            type="button"
            onClick={onOpenCommandPalette}
            className="flex items-center gap-2 px-3 py-1.5 rounded-lg bg-white/5 hover:bg-white/10 text-neutral-400 hover:text-white text-xs border border-white/5 transition-all cursor-pointer"
          >
            <Search className="w-3.5 h-3.5" />
            <span className="hidden sm:inline">Поиск...</span>
            <kbd className="px-1.5 py-0.5 text-[10px] bg-white/10 rounded text-neutral-300 font-mono">
              ⌘K
            </kbd>
          </button>

          {/* Полноэкранный режим */}
          <button
            type="button"
            onClick={() => {
              if (!document.fullscreenElement) {
                document.documentElement.requestFullscreen().catch(() => {});
              } else {
                document.exitFullscreen().catch(() => {});
              }
            }}
            className="p-1.5 text-neutral-400 hover:text-white hover:bg-white/10 rounded-lg transition-colors cursor-pointer"
            title="Полноэкранный режим"
          >
            <Maximize2 className="w-3.5 h-3.5" />
          </button>
        </div>
      </header>

      {/* Основной контент окна */}
      <main className="flex-1 overflow-y-auto p-8">{children}</main>
    </div>
  );
};
