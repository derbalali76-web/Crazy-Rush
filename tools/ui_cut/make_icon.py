"""يولّد أيقونة اللعبة: فوكسي كبير بحافة ملصق على خلفية متوهجة بأشعة. الخرج: assets/icon/*"""
import numpy as np, cv2
from PIL import Image, ImageFilter, ImageEnhance


def backdrop(n):
    yy, xx = np.mgrid[0:n, 0:n].astype(np.float32)
    cx, cy = n * 0.5, n * 0.46
    r = np.hypot(xx - cx, yy - cy) / (n * 0.72)
    ang = np.arctan2(yy - cy, xx - cx)
    rays = 0.5 + 0.5 * np.sin(ang * 12)
    inner = np.array([70, 215, 255], np.float32); mid = np.array([28, 80, 215], np.float32); outer = np.array([70, 20, 140], np.float32)
    t = np.clip(r, 0, 1)[..., None]
    col = np.where(t < 0.45, inner + (mid - inner) * (t / 0.45), mid + (outer - mid) * ((t - 0.45) / 0.55))
    col = col * (0.88 + 0.12 * rays[..., None] * (1 - t * 0.6))
    glow = np.exp(-((r) ** 2) * 6)[..., None] * 60
    return Image.fromarray(np.clip(col + glow, 0, 255).astype(np.uint8)).convert('RGBA')


def clean_fox():
    """يزيل بقايا الهالة الزرقاء يسار الجسم من صورة فوكسي ثم يُبقي أكبر مكوّن."""
    a = np.array(Image.open('assets/characters/fox_portrait.png').convert('RGBA'))
    h, w = a.shape[:2]
    r, g, b = a[..., 0].astype(int), a[..., 1].astype(int), a[..., 2].astype(int)
    yy, xx = np.mgrid[0:h, 0:w]
    a[(xx < 115) & (yy > 220) & (yy < 440) & (b > g + 15) & (b > r + 30) & (xx < 85 + (yy - 330) * 0 + 30), 3] = 0
    m = cv2.morphologyEx((a[..., 3] > 40).astype(np.uint8), cv2.MORPH_OPEN, np.ones((3, 3), np.uint8))
    n, lab, st, _ = cv2.connectedComponentsWithStats(m)
    k = 1 + np.argmax(st[1:, cv2.CC_STAT_AREA])
    a[..., 3] = np.where(lab == k, a[..., 3], 0)
    return Image.fromarray(a)


def fox_layer(n, height_frac, cy_frac):
    f = clean_fox()
    f = f.crop((0, 0, f.width, int(f.height * 0.75)))
    h = int(n * height_frac)
    w = int(f.width * h / f.height)
    f = f.resize((w, h), Image.LANCZOS)
    f = ImageEnhance.Sharpness(f).enhance(1.6)
    a = np.array(f)[..., 3]
    # حافة ملصق بيضاء + ظل
    k = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (int(n * 0.03) | 1,) * 2)
    edge = cv2.dilate(a, k)
    pad = n // 2
    layer = Image.new('RGBA', (n + 2 * pad, n + 2 * pad), (0, 0, 0, 0))
    x0, y0 = pad + (n - w) // 2, pad + int(n * cy_frac - h / 2)
    white = np.zeros((h, w, 4), np.uint8); white[..., :3] = 255; white[..., 3] = cv2.GaussianBlur(edge, (0, 0), 1.2)
    shadow = np.zeros((h, w, 4), np.uint8); shadow[..., 3] = (cv2.GaussianBlur(edge, (0, 0), n * 0.02) * 0.55).astype(np.uint8)
    layer.alpha_composite(Image.fromarray(shadow), (x0 + int(n * 0.012), y0 + int(n * 0.022)))
    layer.alpha_composite(Image.fromarray(white), (x0, y0))
    layer.alpha_composite(f, (x0, y0))
    return layer.crop((pad, pad, pad + n, pad + n))


if __name__ == '__main__':
    big = backdrop(1024)
    full = big.copy(); full.alpha_composite(fox_layer(1024, 1.06, 0.58))
    full.convert('RGB').resize((512, 512), Image.LANCZOS).save('assets/icon/icon_512.png', optimize=True)
    full.convert('RGB').resize((192, 192), Image.LANCZOS).save('assets/icon/main_192.png', optimize=True)
    backdrop(1024).resize((432, 432), Image.LANCZOS).save('assets/icon/adaptive_bg_432.png', optimize=True)
    fg = fox_layer(1024, 0.72, 0.52).resize((432, 432), Image.LANCZOS)
    fg.save('assets/icon/adaptive_fg_432.png', optimize=True)
    prev = backdrop(432); prev.alpha_composite(fg); prev.save('/tmp/adaptive_prev.png')
