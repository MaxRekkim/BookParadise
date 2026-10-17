/**
 * Процедурный синтезатор звуковых ландшафтов (Web Audio API)
 * Полностью автономен, не требует внешних mp3 файлов, работает на чистом аудио-движке
 */

class SoundscapeEngine {
  private ctx: AudioContext | null = null;
  private currentMode: 'fireplace' | 'rain' | 'library' | 'cafe' | null = null;
  private isPlaying = false;
  private gainNode: GainNode | null = null;
  private noiseNode: AudioNode | null = null;
  private crackleInterval: number | null = null;

  private initContext() {
    if (!this.ctx) {
      const AudioCtx = window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
      this.ctx = new AudioCtx();
    }
    if (this.ctx.state === 'suspended') {
      this.ctx.resume();
    }
  }

  public play(mode: 'fireplace' | 'rain' | 'library' | 'cafe', volume = 0.4) {
    this.stop();
    this.initContext();
    if (!this.ctx) return;

    this.currentMode = mode;
    this.isPlaying = true;

    this.gainNode = this.ctx.createGain();
    this.gainNode.gain.setValueAtTime(volume, this.ctx.currentTime);
    this.gainNode.connect(this.ctx.destination);

    if (mode === 'fireplace') {
      this.startFireplace();
    } else if (mode === 'rain') {
      this.startRain();
    } else if (mode === 'library') {
      this.startLibrary();
    } else if (mode === 'cafe') {
      this.startCafe();
    }
  }

  public setVolume(volume: number) {
    if (this.gainNode && this.ctx) {
      this.gainNode.gain.setValueAtTime(Math.max(0, Math.min(1, volume)), this.ctx.currentTime);
    }
  }

  public stop() {
    if (this.crackleInterval) {
      clearInterval(this.crackleInterval);
      this.crackleInterval = null;
    }
    if (this.noiseNode) {
      try {
        (this.noiseNode as AudioBufferSourceNode).stop();
        this.noiseNode.disconnect();
      } catch (_) {}
      this.noiseNode = null;
    }
    if (this.gainNode) {
      this.gainNode.disconnect();
      this.gainNode = null;
    }
    this.isPlaying = false;
    this.currentMode = null;
  }

  public getState() {
    return {
      isPlaying: this.isPlaying,
      mode: this.currentMode,
    };
  }

  // Генерация коричневого/розового шума
  private createNoiseBuffer(type: 'brown' | 'pink') {
    if (!this.ctx) return null;
    const bufferSize = this.ctx.sampleRate * 2;
    const buffer = this.ctx.createBuffer(1, bufferSize, this.ctx.sampleRate);
    const data = buffer.getChannelData(0);

    let lastOut = 0.0;
    let b0 = 0, b1 = 0, b2 = 0, b3 = 0, b4 = 0, b5 = 0, b6 = 0;

    for (let i = 0; i < bufferSize; i++) {
      const white = Math.random() * 2 - 1;
      if (type === 'brown') {
        data[i] = (lastOut + 0.02 * white) / 1.02;
        lastOut = data[i];
        data[i] *= 3.5;
      } else {
        b0 = 0.99886 * b0 + white * 0.0555179;
        b1 = 0.99332 * b1 + white * 0.0750759;
        b2 = 0.96900 * b2 + white * 0.1538520;
        b3 = 0.86650 * b3 + white * 0.3104856;
        b4 = 0.55000 * b4 + white * 0.5329522;
        b5 = -0.7616 * b5 - white * 0.0168980;
        data[i] = b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362;
        data[i] *= 0.11;
        b6 = white * 0.115926;
      }
    }
    return buffer;
  }

  private startFireplace() {
    if (!this.ctx || !this.gainNode) return;
    const buffer = this.createNoiseBuffer('brown');
    if (!buffer) return;

    const source = this.ctx.createBufferSource();
    source.buffer = buffer;
    source.loop = true;

    const filter = this.ctx.createBiquadFilter();
    filter.type = 'lowpass';
    filter.frequency.setValueAtTime(320, this.ctx.currentTime);

    source.connect(filter);
    filter.connect(this.gainNode);
    source.start();
    this.noiseNode = source;

    // Потрескивание дров
    this.crackleInterval = window.setInterval(() => {
      if (!this.ctx || !this.gainNode) return;
      if (Math.random() > 0.4) {
        const osc = this.ctx.createOscillator();
        const popGain = this.ctx.createGain();
        osc.frequency.setValueAtTime(800 + Math.random() * 1400, this.ctx.currentTime);
        popGain.gain.setValueAtTime(0.08 + Math.random() * 0.15, this.ctx.currentTime);
        popGain.gain.exponentialRampToValueAtTime(0.001, this.ctx.currentTime + 0.03 + Math.random() * 0.04);
        osc.connect(popGain);
        popGain.connect(this.gainNode);
        osc.start();
        osc.stop(this.ctx.currentTime + 0.07);
      }
    }, 180);
  }

  private startRain() {
    if (!this.ctx || !this.gainNode) return;
    const buffer = this.createNoiseBuffer('pink');
    if (!buffer) return;

    const source = this.ctx.createBufferSource();
    source.buffer = buffer;
    source.loop = true;

    const filter = this.ctx.createBiquadFilter();
    filter.type = 'bandpass';
    filter.frequency.setValueAtTime(850, this.ctx.currentTime);
    filter.Q.setValueAtTime(0.6, this.ctx.currentTime);

    source.connect(filter);
    filter.connect(this.gainNode);
    source.start();
    this.noiseNode = source;
  }

  private startLibrary() {
    if (!this.ctx || !this.gainNode) return;
    const buffer = this.createNoiseBuffer('brown');
    if (!buffer) return;

    const source = this.ctx.createBufferSource();
    source.buffer = buffer;
    source.loop = true;

    const filter = this.ctx.createBiquadFilter();
    filter.type = 'lowpass';
    filter.frequency.setValueAtTime(220, this.ctx.currentTime);

    source.connect(filter);
    filter.connect(this.gainNode);
    source.start();
    this.noiseNode = source;
  }

  private startCafe() {
    if (!this.ctx || !this.gainNode) return;
    const buffer = this.createNoiseBuffer('pink');
    if (!buffer) return;

    const source = this.ctx.createBufferSource();
    source.buffer = buffer;
    source.loop = true;

    const filter = this.ctx.createBiquadFilter();
    filter.type = 'lowpass';
    filter.frequency.setValueAtTime(450, this.ctx.currentTime);

    source.connect(filter);
    filter.connect(this.gainNode);
    source.start();
    this.noiseNode = source;
  }
}

export const soundscape = new SoundscapeEngine();
