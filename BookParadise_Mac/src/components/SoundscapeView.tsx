import React, { useState } from 'react';
import { soundscape } from '../services/soundscape';
import { Flame, CloudRain, BookOpen, Coffee, Volume2, Play, Square } from 'lucide-react';

interface SoundscapeViewProps {
  activeMode: 'fireplace' | 'rain' | 'library' | 'cafe' | null;
  isPlaying: boolean;
  onPlayMode: (mode: 'fireplace' | 'rain' | 'library' | 'cafe') => void;
  onStop: () => void;
}

export const SoundscapeView: React.FC<SoundscapeViewProps> = ({
  activeMode,
  isPlaying,
  onPlayMode,
  onStop,
}) => {
  const [volume, setVolume] = useState(0.4);

  const handleVolumeChange = (v: number) => {
    setVolume(v);
    soundscape.setVolume(v);
  };

  const landscapes = [
    {
      id: 'fireplace' as const,
      title: 'Треск камина',
      description: 'Уютный очаг, легкий гул пламени и потрескивание сухих березовых поленьев',
      icon: Flame,
      color: 'from-amber-600/30 to-orange-950/20 border-amber-500/30 text-amber-400',
    },
    {
      id: 'rain' as const,
      title: 'Шум дождя за окном',
      description: 'Мерный шелест капель по крыше и листве, создающий идеальную атмосферу для погружения',
      icon: CloudRain,
      color: 'from-blue-600/30 to-cyan-950/20 border-blue-500/30 text-blue-400',
    },
    {
      id: 'library' as const,
      title: 'Старинная библиотека',
      description: 'Глубокий медитативный коричневый шум, шорох страниц и ощущение бесконечной тишины',
      icon: BookOpen,
      color: 'from-emerald-600/30 to-teal-950/20 border-emerald-500/30 text-emerald-400',
    },
    {
      id: 'cafe' as const,
      title: 'Уютная кофейня',
      description: 'Приглушенный фоновый рокот, мягкий теплый шум и настроение неспешного утреннего чтения',
      icon: Coffee,
      color: 'from-amber-700/30 to-stone-950/20 border-stone-500/30 text-amber-200',
    },
  ];

  return (
    <div className="max-w-4xl mx-auto space-y-8 animate-in fade-in duration-200">
      <div>
        <h2 className="text-2xl font-bold text-white tracking-tight flex items-center gap-2">
          <Volume2 className="w-6 h-6 text-emerald-400" />
          <span>Атмосферные звуковые ландшафты</span>
        </h2>
        <p className="text-xs text-neutral-400 mt-1">
          Процедурный аудио-движок Web Audio API для глубокой концентрации и изоляции от внешнего шума
        </p>
      </div>

      {/* Панель громкости */}
      <div className="p-6 rounded-2xl bg-[#191922] border border-white/10 flex items-center justify-between gap-6 shadow-mac-card">
        <div className="flex items-center gap-3">
          <Volume2 className="w-5 h-5 text-neutral-400" />
          <span className="text-xs font-semibold text-white">Громкость звука</span>
        </div>
        <div className="flex items-center gap-4 flex-1 max-w-xs">
          <input
            type="range"
            min={0}
            max={1}
            step={0.01}
            value={volume}
            onChange={(e) => handleVolumeChange(Number(e.target.value))}
            className="w-full accent-emerald-500 cursor-pointer h-2 bg-neutral-700 rounded-lg"
          />
          <span className="text-xs font-mono text-neutral-400 w-10 text-right">
            {Math.round(volume * 100)}%
          </span>
        </div>
        {isPlaying && (
          <button
            type="button"
            onClick={onStop}
            className="flex items-center gap-1.5 px-3.5 py-1.5 rounded-xl bg-rose-500/20 text-rose-400 hover:bg-rose-500/30 border border-rose-500/30 text-xs font-semibold transition-all cursor-pointer"
          >
            <Square className="w-3.5 h-3.5 fill-rose-400" />
            <span>Остановить</span>
          </button>
        )}
      </div>

      {/* Сетка вариантов ландшафтов */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {landscapes.map((land) => {
          const isThisActive = isPlaying && activeMode === land.id;
          const Icon = land.icon;
          return (
            <div
              key={land.id}
              className={`p-6 rounded-2xl bg-gradient-to-br ${land.color} border transition-all duration-200 flex flex-col justify-between ${
                isThisActive
                  ? 'ring-2 ring-emerald-400 shadow-lg shadow-emerald-950/50 scale-[1.02]'
                  : 'hover:scale-[1.01]'
              }`}
            >
              <div>
                <div className="flex items-center justify-between mb-4">
                  <div className="w-12 h-12 rounded-xl bg-black/40 flex items-center justify-center border border-white/10">
                    <Icon className="w-6 h-6" />
                  </div>
                  {isThisActive && (
                    <span className="flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-emerald-500 text-black text-[10px] font-bold">
                      <span className="w-1.5 h-1.5 rounded-full bg-black animate-ping" />
                      Играет
                    </span>
                  )}
                </div>
                <h3 className="text-base font-bold text-white">{land.title}</h3>
                <p className="text-xs text-neutral-300 mt-1 leading-relaxed">
                  {land.description}
                </p>
              </div>

              <div className="pt-6">
                <button
                  type="button"
                  onClick={() => (isThisActive ? onStop() : onPlayMode(land.id))}
                  className={`w-full py-2.5 px-4 rounded-xl text-xs font-semibold flex items-center justify-center gap-2 transition-all cursor-pointer ${
                    isThisActive
                      ? 'bg-neutral-800 text-white hover:bg-neutral-700'
                      : 'bg-white/10 hover:bg-white/20 text-white'
                  }`}
                >
                  {isThisActive ? (
                    <>
                      <Square className="w-3.5 h-3.5 fill-white" />
                      <span>Остановить воспроизведение</span>
                    </>
                  ) : (
                    <>
                      <Play className="w-3.5 h-3.5 fill-white" />
                      <span>Включить ландшафт</span>
                    </>
                  )}
                </button>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};
