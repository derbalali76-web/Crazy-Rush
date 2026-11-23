"""أيقونة اللعبة من الملصق الأصلي icon_original_1254.png بأعلى جودة:
- icon_512 / main_192: الملصق كما هو (Lanczos + حدّة خفيفة)
- adaptive_fg_432: الملصق بنسبة 68% في الوسط (يبقى كاملًا داخل القناع الدائري/المدوّر للهاتف)
- adaptive_bg_432: نفس الملصق مكبّرًا ومموّهًا ليملأ ما حول المركز."""
from PIL import Image, ImageFilter, ImageEnhance

src = Image.open('assets/icon/icon_original_1254.png').convert('RGB')


def sharp(im):
    return ImageEnhance.Sharpness(im).enhance(1.25)


sharp(src.resize((512, 512), Image.LANCZOS)).save('assets/icon/icon_512.png', optimize=True)
sharp(src.resize((192, 192), Image.LANCZOS)).save('assets/icon/main_192.png', optimize=True)
sharp(src.resize((1254, 1254), Image.LANCZOS)).save('assets/icon/icon_1254.png', optimize=True)

n = 432
bg = src.resize((n, n), Image.LANCZOS).filter(ImageFilter.GaussianBlur(14))
bg = ImageEnhance.Brightness(bg).enhance(0.85)
bg.save('assets/icon/adaptive_bg_432.png', optimize=True)

fg = Image.new('RGBA', (n, n), (0, 0, 0, 0))
k = int(n * 0.68)
art = sharp(src.resize((k, k), Image.LANCZOS)).convert('RGBA')
fg.alpha_composite(art, ((n - k) // 2, (n - k) // 2))
fg.save('assets/icon/adaptive_fg_432.png', optimize=True)

prev = bg.convert('RGBA'); prev.alpha_composite(fg)
from PIL import ImageDraw
m = Image.new('L', (n, n), 0); ImageDraw.Draw(m).ellipse((72, 72, n - 72, n - 72), fill=255)
out = Image.new('RGBA', (n, n), (40, 60, 40, 255)); out.paste(prev, (0, 0), m); out.save('/tmp/adaptive_circle.png')
