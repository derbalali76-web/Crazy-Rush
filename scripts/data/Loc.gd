class_name Loc
extends RefCounted
## اللغات: المفتاح هو النص العربي نفسه، والقيمة [الإنجليزية، الفرنسية، الإسبانية، الصينية]. ما لا ترجمة له يبقى عربيًا.
## الصور المرجعية: لكل لغة نسخة اختيارية باللاحقة _en / _fr / _es / _zh (مثال menu_ref_en.png)؛ وإن لم توجد تُستعمل العربية.

const LANGS := ["ar", "en", "fr", "es", "zh"]
const NAMES := {"ar": "العربية", "en": "English", "fr": "Français", "es": "Español", "zh": "中文"}
const IDX := {"en": 0, "fr": 1, "es": 2, "zh": 3}

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
	var i: int = IDX.get(lang, 0)
	return e[i] if i < e.size() else e[0]


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
	"المهام": ["Missions", "Missions", "Misiones", "任务"],
	"البطولات": ["Tournaments", "Tournois", "Torneos", "锦标赛"],
	"الأزياء": ["Costumes", "Costumes", "Disfraces", "服装"],
	"المتجر": ["Store", "Boutique", "Tienda", "商店"],
	"ضد الكمبيوتر": ["Vs Computer", "Contre l'ordi", "Contra la CPU", "对战电脑"],
	"تحدي الذكاء الاصطناعي": ["Challenge the AI", "Défie l'IA", "Reta a la IA", "挑战人工智能"],
	"أونلاين": ["Online", "En ligne", "En línea", "在线"],
	"منافسة عالمية": ["Worldwide competition", "Compétition mondiale", "Competencia mundial", "全球竞赛"],
	"غرفة الأصدقاء": ["Friends Room", "Salon d'amis", "Sala de amigos", "好友房间"],
	"العب مع أصدقائك": ["Play with friends", "Joue avec tes amis", "Juega con tus amigos", "和朋友一起玩"],
	"بلوتوث": ["Bluetooth", "Bluetooth", "Bluetooth", "蓝牙"],
	"لعب محلي قريب": ["Local play nearby", "Jeu local à proximité", "Juego local cercano", "附近本地游戏"],
	"العب الآن": ["Play Now", "Jouer", "Jugar", "开始游戏"],
	"الترتيب": ["Ranking", "Classement", "Clasificación", "排名"],
	"المسارات": ["Tracks", "Pistes", "Pistas", "赛道"],
	"الشخصيات": ["Characters", "Personnages", "Personajes", "角色"],
	"متوقف مؤقتًا": ["Paused", "En pause", "En pausa", "已暂停"],
	"إعادة السباق": ["Restart", "Recommencer", "Reiniciar", "重新开始"],
	"الإعدادات": ["Settings", "Paramètres", "Ajustes", "设置"],
	"الرئيسية": ["Home", "Accueil", "Inicio", "主页"],
	# --- الجودة والإعدادات
	"عالية": ["High", "Élevée", "Alta", "高"],
	"متوسطة": ["Medium", "Moyenne", "Media", "中"],
	"منخفضة": ["Low", "Basse", "Baja", "低"],
	"استعادة الافتراضي": ["Restore defaults", "Réinitialiser", "Restablecer", "恢复默认"],
	"تخفيف الرسومات تلقائيًا عند الثقل": ["Auto-lower graphics when slow", "Baisser les graphismes si lent", "Bajar gráficos automáticamente si va lento", "卡顿时自动降低画质"],
	"حلبة التفرعات متعددة الارتفاعات (تجريبي)": ["Multi-level branching track (beta)", "Piste à embranchements (bêta)", "Pista con bifurcaciones (beta)", "多层分叉赛道(测试)"],
	"حلبة الغابة التجريبية (بريميوم)": ["Experimental forest track (premium)", "Piste forêt expérimentale (premium)", "Pista de bosque experimental (premium)", "实验森林赛道(高级)"],
	"خيارات متقدمة": ["Advanced options", "Options avancées", "Opciones avanzadas", "高级选项"],
	"رجوع": ["Back", "Retour", "Atrás", "返回"],
	"عرض عدّاد الأداء (FPS)": ["Show FPS counter", "Afficher le compteur FPS", "Mostrar contador FPS", "显示帧率(FPS)"],
	"متوقف": ["Off", "Désactivé", "Desactivado", "关"],
	"مفعّل": ["On", "Activé", "Activado", "开"],
	"غير متاح حاليًا": ["Not available yet", "Pas encore disponible", "No disponible aún", "暂不可用"],
	"إلغاء": ["Cancel", "Annuler", "Cancelar", "取消"],
	"تغيير الاسم": ["Change name", "Changer le nom", "Cambiar nombre", "修改名字"],
	"حفظ": ["Save", "Enregistrer", "Guardar", "保存"],
	# --- السباق
	"أنت (%s)": ["You (%s)", "Toi (%s)", "Tú (%s)", "你 (%s)"],
	"أوه! اصطدام": ["Oops! Crash!", "Oups ! Collision", "¡Ups! Choque", "哎呀!撞车了"],
	"أُصبتَ بضربة!": ["You got hit!", "Tu es touché !", "¡Te golpearon!", "你被击中了!"],
	"تسارع!": ["Boost!", "Turbo !", "¡Impulso!", "加速!"],
	"سقطت!": ["You fell!", "Tu es tombé !", "¡Te caíste!", "你掉下去了!"],
	"ضربة موفّقة!": ["Nice hit!", "Beau coup !", "¡Buen golpe!", "漂亮一击!"],
	"لم ينهِ": ["DNF", "Abandon", "No terminó", "未完成"],
	"جارٍ تجهيز المسار...": ["Preparing the track...", "Préparation de la piste...", "Preparando la pista...", "正在准备赛道..."],
	"تم تخفيف الرسومات تلقائيًا إلى %s (%.0f إطار/ث)": ["Graphics lowered automatically to %s (%.0f fps)", "Graphismes réduits automatiquement : %s (%.0f im/s)", "Gráficos reducidos automáticamente a %s (%.0f fps)", "已自动降低画质至%s(%.0f帧/秒)"],
	"FPS %d   %.1f ms\nمكالمات الرسم %d   مثلثات %dk\nالذاكرة %.0f MB   الجودة %s  دقة %.0f%%": ["FPS %d   %.1f ms\nDraw calls %d   Triangles %dk\nMemory %.0f MB   Quality %s  Res %.0f%%", "FPS %d   %.1f ms\nAppels de rendu %d   Triangles %dk\nMémoire %.0f Mo   Qualité %s  Rés. %.0f%%", "FPS %d   %.1f ms\nLlamadas de dibujo %d   Triángulos %dk\nMemoria %.0f MB   Calidad %s  Res %.0f%%", "FPS %d   %.1f ms\n绘制调用 %d   三角面 %dk\n内存 %.0f MB   画质 %s  分辨率 %.0f%%"],
	"رقم قياسي جديد!": ["New record!", "Nouveau record !", "¡Nuevo récord!", "新纪录!"],
	"أفضل زمن %.2f ث": ["Best time %.2f s", "Meilleur temps %.2f s", "Mejor tiempo %.2f s", "最佳时间 %.2f 秒"],
	# --- الشخصيات
	"فوكسي الثعلب": ["Foxy the Fox", "Foxy le Renard", "Foxy el Zorro", "狐狸福克西"],
	"بومبو الملاكم": ["Bombo the Boxer", "Bombo le Boxeur", "Bombo el Boxeador", "拳击手邦博"],
	"زيكو النينجا": ["Ziko the Ninja", "Ziko le Ninja", "Ziko el Ninja", "忍者齐科"],
	"روبو الروبوت": ["Robo the Robot", "Robo le Robot", "Robo el Robot", "机器人罗博"],
	"لولو الساحرة": ["Lulu the Witch", "Lulu la Sorcière", "Lulu la Bruja", "女巫露露"],
	"دينو الديناصور": ["Dino the Dinosaur", "Dino le Dinosaure", "Dino el Dinosaurio", "恐龙迪诺"],
	"بيبو الأرنب": ["Bibo the Bunny", "Bibo le Lapin", "Bibo el Conejo", "兔子比博"],
	"بطبوط القبطان": ["Captain Batboot", "Capitaine Batboot", "Capitán Batboot", "船长巴特布特"],
	"كونغ الباندا": ["Kung the Panda", "Kung le Panda", "Kung el Panda", "熊猫功夫"],
	"سوسو العنقاء": ["Sosu the Phoenix", "Sosu le Phénix", "Sosu el Fénix", "凤凰苏苏"],
	"زين البرق": ["Zain the Lightning", "Zain l'Éclair", "Zain el Rayo", "闪电赞恩"],
	"آرثر ملك الجليد": ["Arthur the Ice King", "Arthur le Roi des Glaces", "Arthur el Rey del Hielo", "冰雪之王亚瑟"],
	"فوكسي": ["Foxy", "Foxy", "Foxy", "福克西"],
	"بومبو": ["Bombo", "Bombo", "Bombo", "邦博"],
	"زيكو": ["Ziko", "Ziko", "Ziko", "齐科"],
	"روبو": ["Robo", "Robo", "Robo", "罗博"],
	"لولو": ["Lulu", "Lulu", "Lulu", "露露"],
	"دينو": ["Dino", "Dino", "Dino", "迪诺"],
	"بيبو": ["Bibo", "Bibo", "Bibo", "比博"],
	"بطبوط": ["Batboot", "Batboot", "Batboot", "巴特布特"],
	"كونغ": ["Kung", "Kung", "Kung", "功夫"],
	"سوسو": ["Sosu", "Sosu", "Sosu", "苏苏"],
	"زين": ["Zain", "Zain", "Zain", "赞恩"],
	"آرثر": ["Arthur", "Arthur", "Arthur", "亚瑟"],
	"الخدعة الوهمية": ["Phantom Trick", "Leurre fantôme", "Truco fantasma", "幻影诱饵"],
	"ترك نسخة وهمية تربك المنافسين مع اندفاع سريع": ["Leaves a decoy that confuses rivals, with a quick dash", "Laisse un leurre qui trouble les rivaux, avec un élan rapide", "Deja un señuelo que confunde a los rivales y da un impulso rápido", "留下分身迷惑对手,并快速冲刺"],
	"اللكمة الخارقة": ["Super Punch", "Super coup de poing", "Superpuñetazo", "超级重拳"],
	"لكمة قوية تدفع الخصم بعيدًا": ["A strong punch that sends rivals flying", "Un puissant coup qui repousse l'adversaire", "Un puñetazo fuerte que lanza lejos al rival", "强力一拳把对手打飞"],
	"اندفاع النينجا": ["Ninja Dash", "Élan du ninja", "Carrera ninja", "忍者冲刺"],
	"اندفاع قصير سريع للمراوغة": ["A short, quick dash to dodge", "Un court élan rapide pour esquiver", "Una carrera corta y rápida para esquivar", "短距离快速冲刺用于闪避"],
	"القفزة الصاروخية": ["Rocket Jump", "Saut fusée", "Salto cohete", "火箭跳"],
	"قفزة صاروخية فوق العقبات": ["A rocket jump over obstacles", "Un saut fusée au-dessus des obstacles", "Un salto cohete sobre los obstáculos", "火箭跳跃越过障碍"],
	"الفخ السحري": ["Magic Trap", "Piège magique", "Trampa mágica", "魔法陷阱"],
	"فخ سحري يجعل الأرض زلقة خلفها": ["A magic trap that makes the ground slippery behind her", "Un piège magique qui rend le sol glissant derrière elle", "Una trampa mágica que vuelve resbaladizo el suelo tras ella", "魔法陷阱让她身后的地面变滑"],
	"الدوسة الأرضية": ["Ground Stomp", "Piétinement", "Pisotón", "大地践踏"],
	"دوسة قوية تُبطئ المنافسين القريبين": ["A heavy stomp that slows nearby rivals", "Un piétinement qui ralentit les rivaux proches", "Un pisotón fuerte que ralentiza a los rivales cercanos", "重重一踩,使附近对手减速"],
	"القفزة المزدوجة": ["Double Jump", "Double saut", "Doble salto", "二段跳"],
	"قفزة ثانية أثناء تفعيل القدرة": ["A second jump while the ability is active", "Un second saut pendant la capacité", "Un segundo salto mientras la habilidad está activa", "技能激活时可再跳一次"],
	"الانزلاق الصاروخي": ["Rocket Slide", "Glissade fusée", "Deslizamiento cohete", "火箭滑行"],
	"انزلاق سريع مع مقاومة مؤقتة للدفع": ["A fast slide with brief knockback resistance", "Une glissade rapide, résistante aux chocs un instant", "Un deslizamiento rápido con resistencia breve a los empujones", "快速滑行,短暂抵抗撞击"],
	"الدفاع المضاد": ["Counter Guard", "Contre-garde", "Contraguardia", "反击防御"],
	"يصد الضربة ويردّ الدفع على الخصم": ["Blocks a hit and pushes the rival back", "Bloque le coup et repousse l'adversaire", "Bloquea el golpe y empuja al rival hacia atrás", "挡住攻击并把对手推回去"],
	"الاندفاع الناري": ["Fire Dash", "Élan de feu", "Carrera de fuego", "烈焰冲刺"],
	"اندفاع ناري قصير": ["A short fiery dash", "Un court élan de feu", "Una breve carrera de fuego", "短暂的烈焰冲刺"],
	"التحول البرقي": ["Lightning Shift", "Transformation éclair", "Transformación relámpago", "闪电变身"],
	"تحول برقي قصير يتجاوز عوائق محددة": ["A brief lightning shift that passes certain obstacles", "Une brève transformation éclair qui passe certains obstacles", "Una breve transformación relámpago que atraviesa ciertos obstáculos", "短暂闪电变身,可穿过部分障碍"],
	"العاصفة الجليدية": ["Ice Storm", "Tempête de glace", "Tormenta de hielo", "冰风暴"],
	"عاصفة جليدية تُبطئ المنافسين القريبين": ["An ice storm that slows nearby rivals", "Une tempête de glace qui ralentit les rivaux proches", "Una tormenta de hielo que ralentiza a los rivales cercanos", "冰风暴使附近对手减速"],
	# --- اختيار الشخصية
	"الشخصيات الأساسية (8)": ["Basic characters (8)", "Personnages de base (8)", "Personajes básicos (8)", "基础角色(8)"],
	"الشخصيات الأسطورية (4)": ["Legendary characters (4)", "Personnages légendaires (4)", "Personajes legendarios (4)", "传说角色(4)"],
	"الكل (12)": ["All (12)", "Tous (12)", "Todos (12)", "全部(12)"],
	"المزيد من الأساطير قريبًا": ["More legends coming soon", "Plus de légendes bientôt", "Más leyendas próximamente", "更多传说角色即将推出"],
	"المزيد من الشخصيات قريبًا": ["More characters coming soon", "Plus de personnages bientôt", "Más personajes próximamente", "更多角色即将推出"],
	# --- المهام والبطولات
	"أكمل كل المهام": ["Complete all missions", "Termine toutes les missions", "Completa todas las misiones", "完成所有任务"],
	"ابدأ": ["Start", "Démarrer", "Empezar", "开始"],
	"استلام": ["Claim", "Récupérer", "Reclamar", "领取"],
	"متابعة": ["Resume", "Continuer", "Continuar", "继续"],
	"جاري": ["In progress", "En cours", "En curso", "进行中"],
	"تم ✓": ["Done ✓", "Fait ✓", "Hecho ✓", "完成 ✓"],
	"اضغط لفتح الصندوق!": ["Tap to open the chest!", "Touche pour ouvrir le coffre !", "¡Toca para abrir el cofre!", "点击打开宝箱!"],
	"تم فتح الصندوق ✓": ["Chest opened ✓", "Coffre ouvert ✓", "Cofre abierto ✓", "宝箱已打开 ✓"],
	"حصلت على %d جواهر و%d عملة!": ["You got %d gems and %d coins!", "Tu as gagné %d gemmes et %d pièces !", "¡Obtuviste %d gemas y %d monedas!", "你获得了%d颗宝石和%d枚金币!"],
	"تتجدد المهام بعد ": ["Missions reset in ", "Les missions se renouvellent dans ", "Las misiones se renuevan en ", "任务将在以下时间后刷新:"],
	"يوم": ["day", "jour", "día", "天"],
	"أيام": ["days", "jours", "días", "天"],
	"يومًا": ["days", "jours", "días", "天"],
	"المركز %s · %s نقطة": ["Rank %s · %s pts", "Rang %s · %s pts", "Puesto %s · %s pts", "第%s名 · %s分"],
}
