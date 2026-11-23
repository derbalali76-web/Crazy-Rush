"""يبني لوحة نتائج نظيفة (بدون شخصيات المنصّة الأصلية) من assets/ui/results_v2_ref.png
ليُرسم فوقها منصّة التتويج بشخصياتنا. الناتج: assets/ui/results_v2_plate.png"""
import cv2, numpy as np
from PIL import Image
from rembg import remove, new_session

src = cv2.imread('assets/ui/results_v2_ref.png')
H, W = src.shape[:2]
out = src.copy()

# 1) إزالة شعر/قبضة البطل فوق شريط العنوان (y<165) بالترميم
pil = Image.open('assets/ui/results_v2_ref.png').convert('RGB')
sess = new_session('isnet-general-use')
x0, y0, x1, y1 = 760, 110, 1040, 190
a = np.array(remove(pil.crop((x0, y0, x1, y1)), session=sess))[..., 3]
m = np.zeros((H, W), np.uint8)
m[y0:y1, x0:x1] = (a > 100).astype(np.uint8) * 255
m[165:, :] = 0
m = cv2.dilate(m, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (13, 13)))
out = cv2.inpaint(out, m, 7, cv2.INPAINT_TELEA)

# 2) خلفية اصطناعية للمنصّة: تدرّج أزرق + وهج ذهبي + أشعة
yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
# لون اللوحة الأزرق (BGR) تدرّجًا من الأعلى للأسفل من نقاط نظيفة
top = np.array([175, 24, 0], np.float32); bot = np.array([200, 50, 8], np.float32)
tv = np.clip((yy - 160) / 240.0, 0, 1)[..., None]
base = top * (1 - tv) + bot * tv
cx, cy = 905.0, 300.0
dx, dy = xx - cx, yy - cy
r = np.sqrt(dx * dx + dy * dy)
ang = np.arctan2(dy, dx)
rays = 0.5 + 0.5 * np.cos(ang * 13.0 + 0.3)
glow = np.exp(-(r / 230.0) ** 2) * 0.62 + np.exp(-(r / 520.0) ** 2) * 0.16 * rays
glow = np.clip(glow, 0, 0.95)[..., None]
warm = np.array([70, 215, 255], np.float32)    # BGR (ذهبي دافئ)
bg = base * (1 - glow) + warm * glow

def rect(x0, y0, x1, y1):
    mm = np.zeros((H, W), np.float32)
    mm[y0:y1, x0:x1] = 1
    return mm
mask = np.maximum.reduce([rect(540, 192, 796, 384), rect(734, 153, 1072, 362), rect(1082, 194, 1336, 398)])
mask = cv2.GaussianBlur(mask, (0, 0), 9)[..., None]
res = out.astype(np.float32) * (1 - mask) + bg * mask
cv2.imwrite('assets/ui/results_v2_plate.png', np.clip(res, 0, 255).astype(np.uint8))
cv2.imwrite('/tmp/plate_prev.png', np.clip(res, 0, 255).astype(np.uint8)[110:440, 520:1400])
