# سجل مصادر الأصول وتراخيصها (فرع art-premium)

الحالة: **لم يُنزَّل أي أصل بعد.** القائمة المقترحة في `tools/assets/manifest_jungle.json`.

## الرخص (مراجعة صفحات المصدر الرسمية)
| المصدر | الرخصة | استخدام تجاري | الإشارة للمصدر | ملاحظات |
|---|---|---|---|---|
| Poly Haven (textures, models, HDRIs) | CC0 | مسموح | غير مطلوبة (مستحسنة) | الممنوع فقط ادعاء التأليف أو إعادة الترخيص. https://polyhaven.com/license |
| ambientCG (materials, models, HDRIs) | CC0 1.0 | مسموح | غير مطلوبة | https://docs.ambientcg.com/license |

نضع شكرًا اختياريًا في شاشة الاعتمادات داخل اللعبة (Credits) مع رابطي المصدرين.

## قواعد
- لا يُنزَّل أصل إلا إذا كانت صفحته تعرض CC0 وقت التنزيل (تُحفظ لقطة نصية للرخصة مع كل دفعة).
- كل أصل مستخدم يُسجَّل هنا: المعرّف، الرابط، تاريخ التنزيل، الرخصة، ما عُدِّل عليه.
- أي أصل من مصدر آخر (Meshy أو غيره) لا يُدخل قبل تحقق منفصل من رخصته وموافقتك.

## الأصول المستخدمة فعليًا
(لا شيء بعد)

## إضافة: مجسمات الأشجار والخشب (Poly Haven، CC0)
tree_stump_01، tree_stump_02، dead_tree_trunk، dead_tree_trunk_02، root_cluster_01، single_root، dead_quiver_trunk: تُنزَّل في CI (tools/assets/fetch_tree_props.py)، وتُبسَّط وتُخبز في Blender، ويُودَع الناتج الخفيف فقط في assets/art/props. السجل: docs/art/tree_props_lock.json. الشجرتان tree_a وtree_b مولَّدتان إجرائيًا (tools/blender/build_trees.py) من لحاء Bark001 (ambientCG، CC0) وأوراق من مجسم calathea_orbifolia_01 (Poly Haven، CC0). تم استبعاد jacaranda_tree لأن التبسيط أتلف أوراقه.
