import React, { useEffect } from 'react';
import { X, Check } from 'lucide-react';

interface ModalWrapperProps {
  isOpen: boolean;
  onClose: () => void;
  title: string;
  subtitle?: string;
  children: React.ReactNode;
  maxWidth?: string; // e.g. 'max-w-3xl', 'max-w-4xl'
  showDoneButton?: boolean;
  onDone?: () => void;
}

export const ModalWrapper: React.FC<ModalWrapperProps> = ({
  isOpen,
  onClose,
  title,
  subtitle,
  children,
  maxWidth = 'max-w-3xl',
  showDoneButton = true,
  onDone,
}) => {
  // ESC шорткат для гарантированного мгновенного выхода
  useEffect(() => {
    if (!isOpen) return;

    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        e.preventDefault();
        e.stopPropagation();
        onClose();
      }
    };

    window.addEventListener('keydown', handleKeyDown, { capture: true });
    return () => window.removeEventListener('keydown', handleKeyDown, { capture: true });
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  const handleDone = () => {
    if (onDone) {
      onDone();
    }
    onClose();
  };

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/65 backdrop-blur-md animate-in fade-in duration-150"
      onClick={onClose} // Клик вне окна закрывает модалку
    >
      <div
        className={`w-full ${maxWidth} bg-[#1a1a22] border border-white/10 rounded-2xl shadow-mac-modal flex flex-col max-h-[90vh] overflow-hidden animate-in zoom-in-95 duration-150`}
        onClick={(e) => e.stopPropagation()} // Клик внутри окна не закрывает его
      >
        {/* Шапка модального окна в стиле macOS */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-white/10 bg-[#20202a]/80">
          <div>
            <h2 className="text-lg font-semibold text-white tracking-tight">{title}</h2>
            {subtitle && <p className="text-xs text-neutral-400 mt-0.5">{subtitle}</p>}
          </div>
          <div className="flex items-center gap-2">
            {showDoneButton && (
              <button
                type="button"
                onClick={handleDone}
                className="flex items-center gap-1.5 px-3.5 py-1.5 text-xs font-semibold text-emerald-400 bg-emerald-500/15 hover:bg-emerald-500/25 border border-emerald-500/30 rounded-lg transition-colors active:scale-95 cursor-pointer"
                title="Закрыть окно (Esc)"
              >
                <Check className="w-3.5 h-3.5" />
                <span>Готово</span>
              </button>
            )}
            <button
              type="button"
              onClick={onClose}
              className="p-1.5 text-neutral-400 hover:text-white hover:bg-white/10 rounded-lg transition-colors cursor-pointer"
              title="Закрыть (Esc)"
            >
              <X className="w-4 h-4" />
            </button>
          </div>
        </div>

        {/* Содержимое окна с плавной прокруткой */}
        <div className="flex-1 overflow-y-auto p-6 space-y-6">
          {children}
        </div>
      </div>
    </div>
  );
};
