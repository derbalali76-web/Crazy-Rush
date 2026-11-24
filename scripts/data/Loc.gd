class_name Loc
extends RefCounted
## اللغات: المفتاح هو النص العربي نفسه، والقيمة [الإنجليزية، الفرنسية]. ما لا ترجمة له يبقى عربيًا.
## الصور المرجعية: لكل لغة نسخة اختيارية باللاحقة _en / _fr (مثال menu_ref_en.png)؛ وإن لم توجد تُستعمل العربية.

const LANGS := ["ar", "en", "fr"]
const NAMES := {"ar": "العربية", "en": "English", "fr": "Français"}

static var lang := "ar"


static func set_lang(l: String) -> void:
	lang = l if LANGS.has(l) else "ar"


## لغة الجهاز عند أول تشغيل
static func guess() -> String:
	var l := OS.get_locale_language()
	return l if LANGS.has(l) else "en"


static func rtl() -> bool:
	return lang == "ar"


static func t(ar: String) -> String:
	if lang == "ar":
		return ar
	var e: Array = T.get(ar, [])
	if e.is_empty():
		return ar
	return e[0] if lang == "en" else e[1]


## يعيد الصورة المرجعية بلغة اللعبة إن وُجدت، وإلا العربية
static func tex(path: String) -> Texture2D:
	if lang != "ar":
		var alt := path.get_basename() + "_" + lang + "." + path.get_extension()
		if ResourceLoader.exists(alt):
			return load(alt) as Texture2D
	return load(path) as Texture2D


## هل النسخة المرجعية بهذه اللغة موجودة؟ (وإلا تبقى نصوص الصورة بالعربية)
static func has_ref(path: String) -> bool:
	return lang == "ar" or ResourceLoader.exists(path.get_basename() + "_" + lang + "." + path.get_extension())


## أرقام عربية-هندية في العربية فقط
static func digits(s: String) -> String:
	if lang != "ar":
		return s
	var out := ""
	for ch in s:
		out += "٠١٢٣٤٥٦٧٨٩"[int(ch)] if ch >= "0" and ch <= "9" else ch
	return out


const T := {
	# --- الرئيسية
	"المهام": ["Missions", "Missions"],
	"البطولات": ["Tournaments", "Tournois"],
	"الأزياء": ["Costumes", "Costumes"],
	"المتجر": ["Store", "Boutique"],
	"ضد الكمبيوتر": ["Vs Computer", "Contre l'ordi"],
	"تحدي الذكاء الاصطناعي": ["Challenge the AI", "Défie l'IA"],
	"أونلاين": ["Online", "En ligne"],
	"منافسة عالمية": ["Worldwide competition", "Compétition mondiale"],
	"غرفة الأصدقاء": ["Friends Room", "Salon d'amis"],
	"العب مع أصدقائك": ["Play with friends", "Joue avec tes amis"],
	"بلوتوث": ["Bluetooth", "Bluetooth"],
	"لعب محلي قريب": ["Local play nearby", "Jeu local à proximité"],
	"العب الآن": ["Play Now", "Jouer"],
	"الترتيب": ["Ranking", "Classement"],
	"المسارات": ["Tracks", "Pistes"],
	"الشخصيات": ["Characters", "Personnages"],
	"الرئيسية": ["Home", "Accueil"],
	# --- الجودة والإعدادات
	"عالية": ["High", "Élevée"],
	"متوسطة": ["Medium", "Moyenne"],
	"منخفضة": ["Low", "Basse"],
	"استعادة الافتراضي": ["Restore defaults", "Réinitialiser"],
	"تخفيف الرسومات تلقائيًا عند الثقل": ["Auto-lower graphics when slow", "Baisser les graphismes si lent"],
	"حلبة التفرعات متعددة الارتفاعات (تجريبي)": ["Multi-level branching track (beta)", "Piste à embranchements (bêta)"],
	"حلبة الغابة التجريبية (بريميوم)": ["Experimental forest track (premium)", "Piste forêt expérimentale (premium)"],
	"خيارات متقدمة": ["Advanced options", "Options avancées"],
	"رجوع": ["Back", "Retour"],
	"عرض عدّاد الأداء (FPS)": ["Show FPS counter", "Afficher le compteur FPS"],
	"متوقف": ["Off", "Désactivé"],
	"مفعّل": ["On", "Activé"],
	"غير متاح حاليًا": ["Not available yet", "Pas encore disponible"],
	"إلغاء": ["Cancel", "Annuler"],
	"تغيير الاسم": ["Change name", "Changer le nom"],
	"حفظ": ["Save", "Enregistrer"],
	# --- السباق
	"أنت (%s)": ["You (%s)", "Toi (%s)"],
	"أوه! اصطدام": ["Oops! Crash!", "Oups ! Collision"],
	"أُصبتَ بضربة!": ["You got hit!", "Tu es touché !"],
	"تسارع!": ["Boost!", "Turbo !"],
	"سقطت!": ["You fell!", "Tu es tombé !"],
	"ضربة موفّقة!": ["Nice hit!", "Beau coup !"],
	"لم ينهِ": ["DNF", "Abandon"],
	"جارٍ تجهيز المسار...": ["Preparing the track...", "Préparation de la piste..."],
	"تم تخفيف الرسومات تلقائيًا إلى %s (%.0f إطار/ث)": ["Graphics lowered automatically to %s (%.0f fps)", "Graphismes réduits automatiquement : %s (%.0f im/s)"],
	"FPS %d   %.1f ms\nمكالمات الرسم %d   مثلثات %dk\nالذاكرة %.0f MB   الجودة %s  دقة %.0f%%": ["FPS %d   %.1f ms\nDraw calls %d   Triangles %dk\nMemory %.0f MB   Quality %s  Res %.0f%%", "FPS %d   %.1f ms\nAppels de rendu %d   Triangles %dk\nMémoire %.0f Mo   Qualité %s  Rés. %.0f%%"],
	"رقم قياسي جديد!": ["New record!", "Nouveau record !"],
	"أفضل زمن %.2f ث": ["Best time %.2f s", "Meilleur temps %.2f s"],
	# --- الشخصيات
	"فوكسي الثعلب": ["Foxy the Fox", "Foxy le Renard"],
	"بومبو الملاكم": ["Bombo the Boxer", "Bombo le Boxeur"],
	"زيكو النينجا": ["Ziko the Ninja", "Ziko le Ninja"],
	"روبو الروبوت": ["Robo the Robot", "Robo le Robot"],
	"لولو الساحرة": ["Lulu the Witch", "Lulu la Sorcière"],
	"دينو الديناصور": ["Dino the Dinosaur", "Dino le Dinosaure"],
	"بيبو الأرنب": ["Bibo the Bunny", "Bibo le Lapin"],
	"بطبوط القبطان": ["Captain Batboot", "Capitaine Batboot"],
	"كونغ الباندا": ["Kung the Panda", "Kung le Panda"],
	"سوسو العنقاء": ["Sosu the Phoenix", "Sosu le Phénix"],
	"زين البرق": ["Zain the Lightning", "Zain l'Éclair"],
	"آرثر ملك الجليد": ["Arthur the Ice King", "Arthur le Roi des Glaces"],
	"فوكسي": ["Foxy", "Foxy"],
	"بومبو": ["Bombo", "Bombo"],
	"زيكو": ["Ziko", "Ziko"],
	"روبو": ["Robo", "Robo"],
	"لولو": ["Lulu", "Lulu"],
	"دينو": ["Dino", "Dino"],
	"بيبو": ["Bibo", "Bibo"],
	"بطبوط": ["Batboot", "Batboot"],
	"كونغ": ["Kung", "Kung"],
	"سوسو": ["Sosu", "Sosu"],
	"زين": ["Zain", "Zain"],
	"آرثر": ["Arthur", "Arthur"],
	"الخدعة الوهمية": ["Phantom Trick", "Leurre fantôme"],
	"ترك نسخة وهمية تربك المنافسين مع اندفاع سريع": ["Leaves a decoy that confuses rivals, with a quick dash", "Laisse un leurre qui trouble les rivaux, avec un élan rapide"],
	"اللكمة الخارقة": ["Super Punch", "Super coup de poing"],
	"لكمة قوية تدفع الخصم بعيدًا": ["A strong punch that sends rivals flying", "Un puissant coup qui repousse l'adversaire"],
	"اندفاع النينجا": ["Ninja Dash", "Élan du ninja"],
	"اندفاع قصير سريع للمراوغة": ["A short, quick dash to dodge", "Un court élan rapide pour esquiver"],
	"القفزة الصاروخية": ["Rocket Jump", "Saut fusée"],
	"قفزة صاروخية فوق العقبات": ["A rocket jump over obstacles", "Un saut fusée au-dessus des obstacles"],
	"الفخ السحري": ["Magic Trap", "Piège magique"],
	"فخ سحري يجعل الأرض زلقة خلفها": ["A magic trap that makes the ground slippery behind her", "Un piège magique qui rend le sol glissant derrière elle"],
	"الدوسة الأرضية": ["Ground Stomp", "Piétinement"],
	"دوسة قوية تُبطئ المنافسين القريبين": ["A heavy stomp that slows nearby rivals", "Un piétinement qui ralentit les rivaux proches"],
	"القفزة المزدوجة": ["Double Jump", "Double saut"],
	"قفزة ثانية أثناء تفعيل القدرة": ["A second jump while the ability is active", "Un second saut pendant la capacité"],
	"الانزلاق الصاروخي": ["Rocket Slide", "Glissade fusée"],
	"انزلاق سريع مع مقاومة مؤقتة للدفع": ["A fast slide with brief knockback resistance", "Une glissade rapide, résistante aux chocs un instant"],
	"الدفاع المضاد": ["Counter Guard", "Contre-garde"],
	"يصد الضربة ويردّ الدفع على الخصم": ["Blocks a hit and pushes the rival back", "Bloque le coup et repousse l'adversaire"],
	"الاندفاع الناري": ["Fire Dash", "Élan de feu"],
	"اندفاع ناري قصير": ["A short fiery dash", "Un court élan de feu"],
	"التحول البرقي": ["Lightning Shift", "Transformation éclair"],
	"تحول برقي قصير يتجاوز عوائق محددة": ["A brief lightning shift that passes certain obstacles", "Une brève transformation éclair qui passe certains obstacles"],
	"العاصفة الجليدية": ["Ice Storm", "Tempête de glace"],
	"عاصفة جليدية تُبطئ المنافسين القريبين": ["An ice storm that slows nearby rivals", "Une tempête de glace qui ralentit les rivaux proches"],
	# --- اختيار الشخصية
	"الشخصيات الأساسية (8)": ["Basic characters (8)", "Personnages de base (8)"],
	"الشخصيات الأسطورية (4)": ["Legendary characters (4)", "Personnages légendaires (4)"],
	"الكل (12)": ["All (12)", "Tous (12)"],
	"المزيد من الأساطير قريبًا": ["More legends coming soon", "Plus de légendes bientôt"],
	"المزيد من الشخصيات قريبًا": ["More characters coming soon", "Plus de personnages bientôt"],
	# --- المهام والبطولات
	"أكمل كل المهام": ["Complete all missions", "Termine toutes les missions"],
	"ابدأ": ["Start", "Démarrer"],
	"استلام": ["Claim", "Récupérer"],
	"متابعة": ["Resume", "Continuer"],
	"جاري": ["In progress", "En cours"],
	"تم ✓": ["Done ✓", "Fait ✓"],
	"اضغط لفتح الصندوق!": ["Tap to open the chest!", "Touche pour ouvrir le coffre !"],
	"تم فتح الصندوق ✓": ["Chest opened ✓", "Coffre ouvert ✓"],
	"حصلت على %d جواهر و%d عملة!": ["You got %d gems and %d coins!", "Tu as gagné %d gemmes et %d pièces !"],
	"تتجدد المهام بعد ": ["Missions reset in ", "Les missions se renouvellent dans "],
	"يوم": ["day", "jour"],
	"أيام": ["days", "jours"],
	"يومًا": ["days", "jours"],
	"المركز %s · %s نقطة": ["Rank %s · %s pts", "Rang %s · %s pts"],
}
