import 'dart:math' as math;
import 'dart:ui';

import '../../../../core/scene3d/orbit_camera.dart';
import '../../../../core/scene3d/scene_builder.dart';
import '../../../../core/scene3d/vec3.dart';
import 'chip_parts.dart';
import 'topic_lab.dart';

class _Point {
  const _Point(this.title, this.text, this.page);

  final String title;
  final String text;
  final String page;
}

/// 3.1 · Six green balls (advantages) and five red ones (disadvantages)
/// around the chip, each from the book.
class ProsConsLab extends TopicLab {
  static const List<_Point> _pros = <_Point>[
    _Point('استهلاك منخفض جداً', 'نحو 1 mW لكل MIPS، و1.6 µA فقط في LPM3.', 'ص 189'),
    _Point('معالج 16 بت و16 مسجلاً', '12 مسجل عمل تقلّل الوصول للذاكرة.', 'ص 11–12'),
    _Point('تعليمات قليلة وبسيطة', '27 تعليمة أساسية و7 أنماط عنونة.', 'ص 103'),
    _Point('فضاء عناوين واحد', 'البرنامج والبيانات والطرفيات في ذاكرة واحدة.', 'ص 11'),
    _Point('طرفيات كثيرة', 'ADC12 ومؤقتان و USART عدد 2 ومضاعف.', 'ورقة البيانات'),
    _Point('ينام ويستيقظ بالمقاطعة', 'يعود للنوم تلقائياً بعد RETI.', 'ص 191–192'),
  ];
  static const List<_Point> _cons = <_Point>[
    _Point('حساسية طرف RST للتشويش', 'التشويش على RST/NMI قد يعيد تشغيل الشريحة.', 'ص 26'),
    _Point('DCO أقل دقة', 'يتأثر بالحرارة والتقادم، والكريستالة أدق.', 'ص 43'),
    _Point('تيار الطرف محدود', 'بضعة mA فقط، فالمرحّل يحتاج ترانزستوراً.', 'ص 197'),
    _Point('سرعة محدودة', 'نحو 4 MHz عند 2.2 V، و8 MHz تحتاج 3.6 V.', 'ص 190'),
    _Point('لا DAC ولا I2C بالعتاد', 'يُستعمل PWM بدل DAC، و I2C برمجياً في F149.', 'ص 184'),
  ];

  static const Color _green = Color(0xFF2FA36B);
  static const Color _red = Color(0xFFD0503F);

  String _filter = 'all';
  String? _open;
  double _t = 0;

  @override
  CameraPose get home => const CameraPose(theta: 0, phi: 1.02, radius: 34, target: Vec3(0, 2, 0));

  @override
  double get focusCloseness => 0.5;

  Vec3 _base(bool good, int i) {
    final n = good ? _pros.length : _cons.length;
    final ang = 0.35 + i / (n - 1) * 2.4;
    final x = math.sin(ang).abs() * 11;
    return Vec3(good ? x : -x, 3, math.cos(ang) * 7);
  }

  Vec3 _pos(bool good, int i) =>
      _base(good, i) + Vec3(0, math.sin(_t * 1.2 + i + (good ? 0 : 6)) * 0.35, 0);

  @override
  void tick(double dt) => _t += dt;

  @override
  void build(SceneBuilder b) {
    buildBoard(b, 30, 22);
    buildChip(b, pickPins: false);
    void add(bool good, List<_Point> list) {
      if (_filter != 'all' && (_filter == 'pro') != good) return;
      for (var i = 0; i < list.length; i++) {
        final id = '${good ? 'pro' : 'con'}:$i';
        final open = _open == id;
        final p = _pos(good, i);
        b.sphere(open ? 1.3 : 0.95, good ? _green : _red, p,
            id: id, glow: open ? (good ? _green : _red) : null);
        b.label(p + Vec3(0, open ? 1.7 : 1.3, 0), list[i].title,
            open ? LabelStyle.hot : LabelStyle.small);
      }
    }

    add(true, _pros);
    add(false, _cons);
  }

  _Point? _point(String id) {
    final p = id.split(':');
    if (p.length != 2) return null;
    final i = int.tryParse(p[1]);
    if (i == null) return null;
    return p[0] == 'pro' ? _pros[i] : (p[0] == 'con' ? _cons[i] : null);
  }

  @override
  String? describe(String id) {
    final p = _point(id);
    if (p == null) return id == 'chip' ? 'MSP430F149' : null;
    return '${id.startsWith('pro') ? 'ميزة' : 'عيب'}: ${p.title}\n${p.text}\n${p.page}';
  }

  @override
  void onTap(String id) {
    if (_point(id) == null) return;
    userDid();
    _open = id;
    changed();
  }

  @override
  void runAction(String action) {
    if (action.startsWith('filter:')) {
      _filter = action.substring(7);
      _open = null;
      changed();
    } else if (action.startsWith('open:')) {
      _filter = 'all';
      _open = action.substring(5);
      changed();
    }
  }

  @override
  Vec3? focusOf(String id) {
    final p = id.split(':');
    if (p.length != 2) return null;
    return _base(p[0] == 'pro', int.parse(p[1]));
  }

  @override
  List<LabControl> get controls => <LabControl>[
    LabChoice(
      options: const <(String, String)>[('all', 'الكل'), ('pro', 'المزايا'), ('con', 'العيوب')],
      value: _filter,
      onChanged: (v) {
        userDid();
        _filter = v;
        changed();
      },
    ),
  ];

  @override
  List<String> get values {
    final open = _open;
    final p = open == null ? null : _point(open);
    return <String>[
      if (p != null) '${open!.startsWith('pro') ? 'ميزة' : 'عيب'}: ${p.title}' else '6 مزايا · 5 عيوب',
      if (p != null) '${p.text} (${p.page})' else 'الأخضر ميزة والأحمر عيب. اضغط أي كرة.',
    ];
  }
}
