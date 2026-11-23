"""يقصّ شخصيات اللعبة من صور العرض (خلفية زرقاء) إلى PNG بشفافية + أيقونة وجه دائرية.
الاستخدام: python3 tools/ui_cut/cut_chars.py <مجلد_المصادر>  — يكتب في assets/characters/"""
import sys, cv2, numpy as np
from PIL import Image, ImageDraw

U = '/mnt/user-data/uploads/'
# id: (ملف, مركز الرأس x, y, حجم قصّ الوجه)
CHARS = {
    'arthur': ('a2b300ac-image.png', 790, 300, 560),
    'sosu':   ('7abebb9f-image.png', 700, 350, 640),
    'kung':   ('c92d4bd7-image.png', 640, 330, 800),
    'zain':   ('962aced5-image.png', 720, 300, 700),
    'bibo':   ('cd984d11-image.png', 690, 400, 780),
    'batboot': ('24e787c2-image.png', 700, 340, 800),
    'dino':   ('b76426a1-image.png', 790, 270, 780),
    'lulu':   ('dd3e9e06-image.png', 640, 380, 780),
    'robo':   ('5b6a0ea3-image.png', 700, 330, 700),
    'ziko':   ('ff50bf13-image.png', 740, 420, 720),
    'bombo':  ('c38e080c-image.png', 680, 330, 700),
}


_SESS = None


def cut(im):
    """قصّ بنموذج rembg (isnet-anime) ثم تنظيف: أكبر مكوّن + إزالة حلقة الأرض."""
    global _SESS
    from rembg import remove, new_session
    if _SESS is None:
        _SESS = new_session('isnet-anime')
    out = remove(Image.fromarray(cv2.cvtColor(im, cv2.COLOR_BGR2RGB)), session=_SESS)
    a = np.array(out)[..., 3]
    a = np.where(a > 128, 255, 0).astype(np.uint8)
    n, lab, st, _ = cv2.connectedComponentsWithStats(a)
    if n > 1:
        k = 1 + np.argmax(st[1:, cv2.CC_STAT_AREA]); a = np.where(lab == k, 255, 0).astype(np.uint8)
    # حلقة الأرض: أقواس رفيعة في أسفل الصورة ⇒ فتح مورفولوجي في الشريط السفلي فقط
    h = a.shape[0]
    k = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (41, 41))
    opened = cv2.morphologyEx(a, cv2.MORPH_OPEN, k)
    opened = cv2.dilate(opened, k)
    band = np.zeros_like(a); band[int(h * 0.78):, :] = 255
    a = np.where((band > 0) & (opened == 0), 0, a).astype(np.uint8)
    n, lab, st, _ = cv2.connectedComponentsWithStats(a)
    if n > 1:
        k2 = 1 + np.argmax(st[1:, cv2.CC_STAT_AREA]); a = np.where(lab == k2, 255, 0).astype(np.uint8)
    a = cv2.GaussianBlur(a, (0, 0), 1.1)
    return a


def cut_old(im):
    h, w = im.shape[:2]
    blur = cv2.GaussianBlur(im, (0, 0), 2)
    ff = np.zeros((h + 2, w + 2), np.uint8)
    work = blur.copy()
    seeds = [(5, 5), (w - 6, 5), (5, h // 2), (w - 6, h // 2), (w // 2, 5), (5, h - 6), (w - 6, h - 6)]
    for sx, sy in seeds:
        cv2.floodFill(work, ff, (sx, sy), (0, 0, 0), (7, 7, 7), (7, 7, 7), cv2.FLOODFILL_MASK_ONLY | (255 << 8))
    bgm = ff[1:-1, 1:-1] > 0
    m = np.full((h, w), cv2.GC_PR_FGD, np.uint8)
    m[bgm] = cv2.GC_BGD
    m[:10, :] = 0; m[-10:, :] = 0; m[:, :10] = 0; m[:, -10:] = 0
    # نواة مؤكدة: مركز الصورة
    cv2.rectangle(m, (int(w * .35), int(h * .30)), (int(w * .65), int(h * .62)), cv2.GC_FGD, -1)
    bg = np.zeros((1, 65)); fg = np.zeros((1, 65))
    cv2.grabCut(im, m, None, bg, fg, 4, cv2.GC_INIT_WITH_MASK)
    a = np.where((m == 1) | (m == 3), 255, 0).astype(np.uint8)
    # أكبر مكوّن فقط + سدّ الثقوب
    n, lab, st, _ = cv2.connectedComponentsWithStats(a)
    if n > 1:
        k = 1 + np.argmax(st[1:, cv2.CC_STAT_AREA]); a = np.where(lab == k, 255, 0).astype(np.uint8)
    cnts, _ = cv2.findContours(a, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    a2 = np.zeros_like(a); cv2.drawContours(a2, cnts, -1, 255, -1)
    a2 = cv2.GaussianBlur(a2, (0, 0), 1.3)
    return a2


def icon(rgba, cx, cy, size, out=256):
    h, w = rgba.shape[:2]
    x0, y0 = int(cx - size / 2), int(cy - size / 2)
    pad = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    pad.alpha_composite(Image.fromarray(rgba), (-x0, -y0))
    pad = pad.resize((out, out), Image.LANCZOS)
    disc = Image.new('RGBA', (out, out), (0, 0, 0, 0))
    d = ImageDraw.Draw(disc)
    for i in range(out // 2, 0, -2):
        t = i / (out / 2)
        c = (int(14 + 40 * (1 - t)), int(40 + 60 * (1 - t)), int(150 + 60 * (1 - t)), 255)
        d.ellipse((out / 2 - i, out / 2 - i, out / 2 + i, out / 2 + i), fill=c)
    disc.alpha_composite(pad)
    mask = Image.new('L', (out * 4, out * 4), 0); ImageDraw.Draw(mask).ellipse((8, 8, out * 4 - 8, out * 4 - 8), fill=255)
    mask = mask.resize((out, out), Image.LANCZOS)
    disc.putalpha(mask)
    rim = ImageDraw.Draw(disc); rim.ellipse((1, 1, out - 2, out - 2), outline=(235, 245, 255, 255), width=4)
    return disc


if __name__ == '__main__':
    only = sys.argv[1:] 
    for cid, (fn, cx, cy, sz) in CHARS.items():
        if only and cid not in only:
            continue
        im = cv2.imread(U + fn)
        a = cut_old(im) if cid == 'bombo' else cut(im)
        rgba = np.dstack([cv2.cvtColor(im, cv2.COLOR_BGR2RGB), a])
        pil = Image.fromarray(rgba)
        bbox = pil.getchannel('A').point(lambda v: 255 if v > 20 else 0).getbbox()
        port = pil.crop(bbox)
        s = 900 / port.height
        port = port.resize((max(1, int(port.width * s)), 900), Image.LANCZOS)
        port.save(f'assets/characters/{cid}_portrait.png', optimize=True)
        icon(rgba, cx, cy, sz).save(f'assets/characters/{cid}_icon.png', optimize=True)
        print(cid, port.size)
