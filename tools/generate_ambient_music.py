#!/usr/bin/env python3
"""Generate original Christian-elevator ambient loops (I-IV-V-I) for Infidel Crusader.
No copyrighted hymns -- original soft pad chords only.
Requires: Python 3, then ffmpeg for OGG (optional but preferred).
Usage: python3 tools/generate_ambient_music.py
"""
import math, wave, struct, os, subprocess, shutil

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
os.makedirs(OUT, exist_ok=True)

def soft_pad(freq, t, amp=0.09):
    w = math.sin(2 * math.pi * freq * t)
    w += 0.35 * math.sin(2 * math.pi * freq * 1.5 * t)
    w += 0.25 * math.sin(2 * math.pi * freq * 2.0 * t)
    w += 0.12 * math.sin(2 * math.pi * freq * 0.5 * t)
    tri = 2.0 * abs(2.0 * ((freq * t) % 1.0) - 1.0) - 1.0
    w += 0.08 * tri
    return amp * w

def write_loop(path, duration, chords, bpm=42, sample_rate=22050, swell=False, master=0.55, pad_amp=0.09):
    n = int(duration * sample_rate)
    beat = 60.0 / bpm
    plan = []
    t_acc = 0.0
    while t_acc < duration + 0.01:
        for freqs, beats in chords:
            plan.append((t_acc, t_acc + beats * beat, freqs))
            t_acc += beats * beat
            if t_acc >= duration:
                break
    samples = []
    edge = 0.08
    for i in range(n):
        t = i / sample_rate
        env = 1.0
        if t < edge:
            env = t / edge
        elif t > duration - edge:
            env = (duration - t) / edge
        val = 0.0
        for a, b, freqs in plan:
            if a <= t < b:
                local = (t - a) / max(b - a, 1e-6)
                cenv = 0.55 + 0.45 * (math.sin(math.pi * min(max(local, 0), 1)) ** 0.6)
                for f in freqs:
                    val += soft_pad(f, t, amp=pad_amp)
                val *= cenv
                break
        val *= 1.0 + 0.025 * math.sin(2 * math.pi * 0.12 * t)
        val += 0.012 * math.sin(2 * math.pi * 0.07 * t)
        if swell:
            lift = 0.55 + 0.45 * math.sin(math.pi * (t / duration))
            val += 0.075 * math.sin(2 * math.pi * 523.25 * t) * lift
            val += 0.055 * math.sin(2 * math.pi * 659.25 * t) * lift
            val += 0.035 * math.sin(2 * math.pi * 783.99 * t) * (lift ** 1.2)
            val += 0.02 * math.sin(2 * math.pi * 987.77 * t) * (lift ** 1.4)
        val = math.tanh(val * (1.05 if not swell else 1.35) * env) * master
        samples.append(val)
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sample_rate)
        w.writeframes(b"".join(struct.pack("<h", max(-32767, min(32767, int(s * 32767)))) for s in samples))

I = [130.81, 164.81, 196.00, 261.63]
IV = [174.61, 220.00, 261.63, 349.23]
V = [196.00, 246.94, 293.66, 392.00]
chords = [(I, 4), (IV, 4), (V, 4), (I, 4)]
bed_wav = os.path.join(OUT, "ambient_bed.wav")
swell_wav = os.path.join(OUT, "ambient_swell.wav")
# Softer quieter ambient bed while roaming
write_loop(bed_wav, 4.0, chords, bpm=42, swell=False, master=0.38, pad_amp=0.065)
# Bigger clearer swell near miracles
write_loop(swell_wav, 4.0, chords, bpm=46, swell=True, master=0.72, pad_amp=0.095)
for name in ("ambient_bed", "ambient_swell"):
    wav = os.path.join(OUT, name + ".wav")
    ogg = os.path.join(OUT, name + ".ogg")
    if shutil.which("ffmpeg"):
        subprocess.check_call(["ffmpeg", "-y", "-i", wav, "-c:a", "libvorbis", "-q:a", "0", ogg])
        os.remove(wav)
        with open(ogg, "rb") as f, open(ogg + ".b64", "w") as o:
            import base64
            o.write(base64.b64encode(f.read()).decode("ascii"))
        print("wrote", ogg, "and", ogg + ".b64")
    else:
        print("wrote", wav, "(install ffmpeg for OGG)")
print("Done. Drop custom OGG loops as ambient_bed.ogg / ambient_swell.ogg to replace.")
