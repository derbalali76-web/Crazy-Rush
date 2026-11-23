"""قصّ تأثيرات العدّ التنازلي (خلفية خضراء) وبانر خط النهاية إلى PNG شفاف."""
import cv2, numpy as np
from PIL import Image
U='/mnt/user-data/uploads/'
G={'cd_3':'4a8d3aaa','cd_2':'744ecd47','cd_1':'30106d6e','cd_go':'927cf5c6'}
def key(src,dst):
    im=cv2.imread(U+src+'-image.png').astype(np.float32)
    b,g,r=im[...,0],im[...,1],im[...,2]
    spill=g-np.maximum(r,b)
    a=1-np.clip((spill-30)/120,0,1)
    a=np.where(spill<30,1,a)
    g2=np.minimum(g,np.maximum(r,b)+8)
    # إعادة بناء اللون الأمامي بعد إزالة الخلفية
    fa=np.maximum(a,1e-3)[...,None]
    out=np.dstack([r,g2,b])
    bgc=np.array([0,255,0],np.float32)
    fg=(out-(1-a)[...,None]*bgc*0)/1
    fg=np.clip(fg,0,255)
    rgba=np.dstack([fg,(a*255)[...,None]]).astype(np.uint8)
    im2=Image.fromarray(rgba)
    bb=im2.getchannel('A').point(lambda v:255 if v>8 else 0).getbbox()
    im2=im2.crop(bb); im2.save(dst,optimize=True); print(dst,im2.size)
for k,v in G.items(): key(v,f'assets/ui/fx/{k}.png')
