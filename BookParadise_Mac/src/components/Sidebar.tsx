import React from 'react';
import { NavigationTab } from '../types';
import { LayoutDashboard, BookMarked, Trophy, BookOpen, Volume2, Settings, Plus, Sparkles } from 'lucide-react';

interface SidebarProps {
  currentTab: NavigationTab;
  onSelectTab: (tab: NavigationTab) => void;
  booksCount: number;
  readingCount: number;
  finishedCount: number;
  onOpenAddModal: () => void;
  soundscapeActive: boolean;
}

export const Sidebar: React.FC<SidebarProps> = ({
  currentTab,
  onSelectTab,
  booksCount,
  readingCount,
  finishedCount,
  onOpenAddModal,
  soundscapeActive,
}) => {
  const menuItems = [
    {
      id: 'dashboard' as NavigationTab,
      label: 'Дашборд',
      icon: LayoutDashboard,
      shortcut: '⌘1',
      badge: readingCount > 0 ? `${readingCount} в фокусе` : undefined,
    },
    {
      id: 'library' as NavigationTab,
      label: 'Библиотека',
      icon: BookMarked,
      shortcut: '⌘2',
      badge: `${booksCount}`,
    },
    {
      id: 'challenge' as NavigationTab,
      label: 'Вызов 2026',
      icon: Trophy,
      shortcut: '⌘3',
      badge: `${finishedCount} проч.`,
    },
    {
      id: 'notes' as NavigationTab,
      label: 'Дневник и цитаты',
      icon: BookOpen,
      shortcut: '⌘4',
    },
    {
      id: 'soundscape' as NavigationTab,
      label: 'Атмосфера звуков',
      icon: Volume2,
      shortcut: '⌘5',
      indicator: soundscapeActive,
    },
  ];

  return (
    <aside className="w-64 bg-[#16161c]/95 border-r border-white/10 flex flex-col justify-between shrink-0 select-none">
      <div className="p-4 space-y-6">
        {/* Шапка сайдбара с отступом под Traffic Lights */}
        <div className="pt-6 px-2 flex items-center gap-2.5">
          <div className="w-8 h-8 rounded-xl bg-gradient-to-tr from-emerald-600 to-teal-400 flex items-center justify-center shadow-lg shadow-emerald-900/30">
            <Sparkles className="w-4 h-4 text-white" />
          </div>
          <div>
            <h1 className="text-sm font-bold text-white tracking-tight">Книжный Рай</h1>
            <span className="text-[10px] text-neutral-400 block font-medium">macOS Studio v2.12</span>
          </div>
        </div>

        {/* Кнопка добавления новой книги */}
        <button
          type="button"
          onClick={onOpenAddModal}
          className="w-full flex items-center justify-center gap-2 py-2.5 px-3 bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-500 hover:to-teal-500 text-white rounded-xl text-xs font-semibold shadow-lg shadow-emerald-950/50 active:scale-95 transition-all cursor-pointer"
        >
          <Plus className="w-4 h-4" />
          <span>Новая книга</span>
        </button>

        {/* Навигационное меню в стиле Linear */}
        <nav className="space-y-1">
          <span className="px-2.5 text-[10px] font-semibold text-neutral-500 uppercase tracking-wider block mb-2">
            Разделы
          </span>
          {menuItems.map((item) => {
            const isActive = currentTab === item.id;
            const Icon = item.icon;
            return (
              <button
                key={item.id}
                type="button"
                onClick={() => onSelectTab(item.id)}
                className={`w-full flex items-center justify-between px-3 py-2 rounded-xl text-xs font-medium transition-all cursor-pointer ${
                  isActive
                    ? 'bg-white/10 text-white shadow-sm font-semibold'
                    : 'text-neutral-400 hover:text-white hover:bg-white/5'
                }`}
              >
                <div className="flex items-center gap-2.5">
                  <Icon className={`w-4 h-4 ${isActive ? 'text-emerald-400' : 'text-neutral-400'}`} />
                  <span>{item.label}</span>
                  {item.indicator && (
                    <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />
                  )}
                </div>
                <div className="flex items-center gap-1.5">
                  {item.badge && (
                    <span className="text-[10px] px-2 py-0.5 rounded-full bg-white/5 text-neutral-400 border border-white/5">
                      {item.badge}
                    </span>
                  )}
                  <span className="text-[10px] text-neutral-600 font-mono hidden group-hover:inline">
                    {item.shortcut}
                  </span>
                </div>
              </button>
            );
          })}
        </nav>
      </div>

      {/* Нижняя плашка с настройками */}
      <div className="p-4 border-t border-white/10 bg-[#141418]">
        <button
          type="button"
          onClick={() => onSelectTab('settings')}
          className={`w-full flex items-center justify-between px-3 py-2 rounded-xl text-xs font-medium transition-colors cursor-pointer ${
            currentTab === 'settings'
              ? 'bg-white/10 text-white font-semibold'
              : 'text-neutral-400 hover:text-white hover:bg-white/5'
          }`}
        >
          <div className="flex items-center gap-2.5">
            <Settings className="w-4 h-4 text-neutral-400" />
            <span>Настройки</span>
          </div>
          <span className="text-[10px] text-neutral-500 font-mono">⌘,</span>
        </button>
      </div>
    </aside>
  );
};
