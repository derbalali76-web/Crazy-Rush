"""يقصّ عناصر واجهة السباق الثابتة من المرجع assets/ui/hud_ref.png إلى PNG بشفافية.
الاستخدام: python3 tools/ui_cut/cut_hud.py  (يكتب في assets/ui/hud/)"""
import cv2, numpy as np
from PIL import Image, ImageDraw

SRC = cv2.imread('assets/ui/hud_ref.png')
H, W = SRC.shape[:2]


def patch_cols(x0, x1, y0, y1, xl, xr):
    for y in range(y0, y1):
        a = SRC[y, xl].astype(np.float32); b = SRC[y, xr].astype(np.float32)
        for x in range(x0, x1):
            t = (x - x0) / max(1, x1 - x0 - 1)
            SRC[y, x] = (a * (1 - t) + b * t).astype(np.uint8)


patch_cols(1312, 1510, 28, 73, 1310, 1513)   # أرقام المؤقت
patch_cols(1394, 1478, 96, 138, 1391, 1480)  # أرقام اللفة (1/3)


def shape_mask(draw_fn):
    im = Image.new('L', (W, H), 0)
    draw_fn(ImageDraw.Draw(im))
    return np.array(im)


def cut(name, bbox, draw_fn, grab=True, feather=0.8):
    x0, y0, x1, y1 = bbox
    m = shape_mask(draw_fn)
    if grab:
        k = np.ones((3, 3), np.uint8)
        fg = cv2.erode(m, k, iterations=3) > 0
        maybe = cv2.dilate(m, k, iterations=3) > 0
        gm = np.full((H, W), cv2.GC_BGD, np.uint8)
        gm[maybe] = cv2.GC_PR_BGD
        gm[m > 0] = cv2.GC_PR_FGD
        gm[fg] = cv2.GC_FGD
        bg = np.zeros((1, 65), np.float64); fgm = np.zeros((1, 65), np.float64)
        sub = (slice(y0, y1), slice(x0, x1))
        g = gm[sub].copy()
        cv2.grabCut(SRC[sub], g, None, bg, fgm, 4, cv2.GC_INIT_WITH_MASK)
        a = np.where((g == cv2.GC_FGD) | (g == cv2.GC_PR_FGD), 255, 0).astype(np.uint8)
        # لا نخرج عن الشكل الهندسي الموسَّع
        a = cv2.bitwise_and(a, cv2.dilate(m, k, iterations=2)[sub])
    else:
        a = m[y0:y1, x0:x1]
    a = cv2.GaussianBlur(a, (0, 0), feather)
    rgb = cv2.cvtColor(SRC[y0:y1, x0:x1], cv2.COLOR_BGR2RGB)
    out = np.dstack([rgb, a])
    Image.fromarray(out).save(f'assets/ui/hud/{name}.png')
    print(name, out.shape)


def rr(d, box, r, fill=255):
    d.rounded_rectangle(box, r, fill=fill)


# ---- المؤقّت (كبسولة + ساعة إيقاف)
def timer(d):
    rr(d, (1290, 22, 1522, 80), 28)
    d.ellipse((1250, 18, 1312, 82), fill=255)
    d.rectangle((1268, 12, 1290, 24), fill=255)
cut('timer', (1236, 6, 1532, 92), timer)

# ---- اللفة (كبسولة + علم)
def lap(d):
    rr(d, (1290, 90, 1502, 145), 27)
    d.polygon([(1484, 90), (1552, 100), (1548, 132), (1490, 140), (1480, 150), (1480, 120)], fill=255)
cut('lap', (1280, 80, 1560, 156), lap)

# ---- زر الإيقاف
def pause(d):
    rr(d, (1556, 12, 1658, 108), 24)
cut('pause', (1546, 2, 1668, 118), pause)

# ---- الشعار
def logo(d):
    d.rectangle((246, 6, 468, 126), fill=255)
cut('logo', (236, 0, 478, 134), logo)

# ---- علامة اللاعب على شريط التقدّم (ثعلب داخل معيّن)
def marker(d):
    d.polygon([(755, 12), (800, 55), (755, 98), (712, 55)], fill=255)
cut('marker', (700, 4, 812, 106), marker)

# ---- علم النهاية
def flag(d):
    d.rectangle((1100, 20, 1160, 90), fill=255)
cut('flag', (1092, 14, 1166, 96), flag)

# ---- ميداليات المراكز 1..3
cents = [(38, 162), (38, 215), (38, 266)]
for i, (cx, cy) in enumerate(cents, 1):
    def med(d, cx=cx, cy=cy):
        d.ellipse((cx - 27, cy - 27, cx + 27, cy + 27), fill=255)
    cut(f'medal{i}', (cx - 30, cy - 30, cx + 30, cy + 30), med, grab=False, feather=0.6)

# ---- شريط التقدّم الفارغ (من المرجع: نُفرِّغ الجزء الأخضر ومنطقة العلامة)
bar = SRC[40:82, 524:1100].copy()
bh, bw = bar.shape[:2]
# عمود المسار الفارغ عند x=900 (مرجع) ⇒ ‏900-524
empty_cols = bar[:, 900 - 524 - 60: 900 - 524 + 60].copy()    # 120 عمودًا فارغًا
# املأ الداخل (من x=36 إلى x=bw-14) بأعمدة المسار الفارغ المكرّرة
for x in range(30, bw - 10):
    bar[:, x] = empty_cols[:, (x - 30) % empty_cols.shape[1]]
for x in range(0, 30):
    col = bar[:, x].astype(int)
    green = (col[:, 1] > col[:, 2] + 25) & (col[:, 1] > col[:, 0] + 25)
    bar[green, x] = empty_cols[green, 5]
rgb = cv2.cvtColor(bar, cv2.COLOR_BGR2RGB)
a = np.zeros((bh, bw), np.uint8)
im = Image.new('L', (bw, bh), 0); ImageDraw.Draw(im).rounded_rectangle((5, 6, bw - 2, bh - 7), 14, fill=255)
a = np.array(im)
Image.fromarray(np.dstack([rgb, a])).save('assets/ui/hud/bar_empty.png')
# شريحة التعبئة الخضراء: عمود من منتصف الجزء الأخضر
fill = SRC[40:82, 600:604]
Image.fromarray(cv2.cvtColor(fill, cv2.COLOR_BGR2RGB)).save('assets/ui/hud/bar_fill.png')
print('bar', bar.shape)


# ================= إصلاح الشعار وعلم النهاية بالمفتاح اللوني =================
def keyed(name, bbox, mask_fn, close=9):
    x0, y0, x1, y1 = bbox
    sub = SRC[y0:y1, x0:x1]
    hsv = cv2.cvtColor(sub, cv2.COLOR_BGR2HSV)
    m = mask_fn(sub, hsv).astype(np.uint8) * 255
    m = cv2.morphologyEx(m, cv2.MORPH_CLOSE, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (close, close)))
    cnts, _ = cv2.findContours(m, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    big = max(cnts, key=cv2.contourArea)
    a = np.zeros_like(m); cv2.drawContours(a, [big], -1, 255, -1)
    a = cv2.GaussianBlur(a, (0, 0), 0.9)
    rgb = cv2.cvtColor(sub, cv2.COLOR_BGR2RGB)
    Image.fromarray(np.dstack([rgb, a])).save(f'assets/ui/hud/{name}.png')
    print(name, 'keyed', a.shape)

# العلم: أبيض/أسود/رمادي (إشباع منخفض) + عمود فضي
keyed('flag', (1092, 14, 1166, 96), lambda s, h: (h[..., 1] < 70) | (h[..., 2] < 60), close=5)
# الشعار: مخطَّط أزرق داكن + ذهبي/برتقالي/أبيض
def logo_mask(s, h):
    b, g, r = s[..., 0].astype(int), s[..., 1].astype(int), s[..., 2].astype(int)
    outline = (b > r + 25) & (b > g) & (h[..., 2] < 150)
    gold = (r > 200) & (g > 120) & (b < 120)
    white = (h[..., 1] < 60) & (h[..., 2] > 200)
    dark = (h[..., 2] < 70)
    flag = np.zeros_like(outline); flag[0:75, 170:240] = True
    return outline | ((white | (h[..., 2] < 70)) & flag)
keyed('logo', (236, 0, 478, 134), logo_mask, close=17)
