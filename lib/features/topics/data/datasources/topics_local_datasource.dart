import 'package:injectable/injectable.dart';

import '../../../../core/error/global_error_handler.dart';
import '../models/topic_model.dart';

/// The paper's twelve topics, their theory and their tours.
///
/// Content ships with the app: no network, nothing to fail. The text follows
/// Chris Nagy, «Embedded Systems Design using the TI MSP430 Series» (Newnes,
/// 2003) and the MSP430F149 datasheet; page numbers are the book's.
///
/// A tour step names what the scene does (`action`) and where the camera
/// goes (`focus`) by the lab's own names (`presentation/labs/`).
@lazySingleton
class TopicsLocalDataSource {
  const TopicsLocalDataSource();

  Future<List<TopicPartModel>> getParts() {
    return rethrowAsAppException(() async => _parts);
  }

  Future<List<TopicModel>> getTopics() {
    return rethrowAsAppException(() async => _topics);
  }

  static const List<TopicPartModel> _parts = <TopicPartModel>[
    TopicPartModel(0, 'المعمارية', 0xFF2D5BA8),
    TopicPartModel(1, 'الأطراف والتوقيت', 0xFF1B7350),
    TopicPartModel(2, 'التحليل والاتصال', 0xFFAD5C17),
  ];

  static const List<TopicModel> _topics = <TopicModel>[
    // ───────────────────────────── part 1
    TopicModel(
      id: 1,
      part: 0,
      indexInPart: 1,
      title: 'بنية MSP430',
      shortTitle: 'البنية',
      bookRef: 'الفصل 2 · ص 11',
      intro:
          'MSP430 متحكم 16 بت بمعمارية RISC. كل وحداته مبنية على قطعة سيليكون واحدة ويربطها ناقلان.',
      theory: <String>[
        'المعالج نفسه في كل أفراد العائلة: خط أنابيب من 3 مراحل، وفك تعليمات، ووحدة ALU بـ 16 بت، و4 مسجلات خاصة و12 مسجل عمل.',
        'يتصل المعالج بالذاكرة عبر ناقلين بـ 16 بت: MAB للعناوين و MDB للبيانات.',
        'الذاكرة كلها والطرفيات في فضاء عناوين واحد متصل.',
        'الـ ALU تجمع وتطرح وتقارن وتنفّذ AND و OR و XOR، وتحدّث الأعلام V و Z و N و C.',
        'المضاعف ليس جزءاً من الـ ALU، بل طرفية مستقلة.',
      ],
      tour: <TourStepModel>[
        TourStepModel(
          'هذا هو القالب',
          'كل ما في الشريحة مبني على قطعة سيليكون واحدة.',
          action: 'hl:none',
          focus: 'home',
        ),
        TourStepModel(
          'المعالج CPU',
          '16 مسجلاً ووحدة حساب ALU، وينفّذ 27 تعليمة فقط.',
          action: 'hl:cpu',
          focus: 'cpu',
        ),
        TourStepModel(
          'ذاكرة Flash',
          '60 KB تحفظ البرنامج ولا تُمحى بانقطاع الكهرباء.',
          action: 'hl:flash',
          focus: 'flash',
        ),
        TourStepModel(
          'ذاكرة RAM',
          '2 KB للمتغيرات والمكدس.',
          action: 'hl:ram',
          focus: 'ram',
        ),
        TourStepModel(
          'الناقلان MAB و MDB',
          'الأول ينقل العناوين والثاني ينقل البيانات، 16 بت لكل منهما.',
          action: 'hl:bus',
          focus: 'bus',
        ),
        TourStepModel(
          'الطرفيات',
          'المؤقتات وADC وUSART والساعة متصلة بالناقلين نفسيهما.',
          action: 'hl:peri',
          focus: 'peri',
        ),
      ],
    ),
    TopicModel(
      id: 2,
      part: 0,
      indexInPart: 2,
      title: 'تنظيم الذاكرة',
      shortTitle: 'الذاكرة',
      bookRef: 'الفصل 2 · ص 19–22',
      intro:
          'كل الذاكرة في فضاء عناوين واحد من 0x0000 إلى 0xFFFF: البرنامج والبيانات والطرفيات معاً.',
      theory: <String>[
        '0x0000–0x000F: مسجلات الوظائف الخاصة SFR، والستة الأولى فقط مستعملة.',
        '0x0010–0x00FF: مسجلات طرفيات تُقرأ بايتاً (المنافذ، الساعة، USART).',
        '0x0100–0x01FF: مسجلات طرفيات تُقرأ كلمة (Timer_A، ADC، المضاعف، WDT).',
        'RAM تبدأ دائماً من 0x0200، وفي F149 تنتهي عند 0x09FF (2 KB).',
        '0x0C00–0x0FFF: ذاكرة الإقلاع BSL، و0x1000–0x10FF: ذاكرة المعلومات (قطاعان من 128 بايت).',
        '0x1100–0xFFDF: ذاكرة البرنامج Flash، و0xFFE0–0xFFFF: جدول المتجهات.',
        'نصيحة الكتاب: المكدس في نهاية RAM، والمتغيرات الأكثر استعمالاً في بدايتها.',
      ],
      tour: <TourStepModel>[
        TourStepModel(
          'البرنامج في Flash',
          'يبدأ البرنامج من العنوان 0x1100.',
          action: 'go:flash',
          focus: 'flash',
        ),
        TourStepModel(
          'المتغيرات في RAM',
          'تبدأ RAM من العنوان 0x0200.',
          action: 'go:vars',
          focus: 'vars',
        ),
        TourStepModel(
          'المكدس',
          'في أعلى RAM عند 0x09FE، وينمو نزولاً.',
          action: 'go:stack',
          focus: 'stack',
        ),
        TourStepModel(
          'الطرفيات مسجلات في الذاكرة',
          'مثلاً P1OUT في العنوان 0x0021.',
          action: 'go:ports',
          focus: 'ports',
        ),
        TourStepModel(
          'جدول المتجهات',
          'آخر 32 بايت. عند التشغيل يقرأ المعالج العنوان من 0xFFFE.',
          action: 'go:reset',
          focus: 'reset',
        ),
      ],
    ),
    TopicModel(
      id: 3,
      part: 0,
      indexInPart: 3,
      title: 'المسجلات',
      shortTitle: 'المسجلات',
      bookRef: 'الفصل 2 · ص 12–18',
      intro:
          'داخل المعالج 16 مسجلاً، كل منها 16 بت. العمل على المسجلات أسرع من العمل على الذاكرة.',
      theory: <String>[
        'R0 = PC عداد البرنامج: يشير إلى التعليمة التالية، ويبقى زوجياً دائماً.',
        'R1 = SP مؤشر المكدس: يبدأ من أعلى RAM. push ينقصه 2، و pop يزيده 2.',
        'R2 = SR مسجل الحالة: C (0)، Z (1)، N (2)، GIE (3)، CPUOFF (4)، OSCOFF (5)، SCG0 (6)، SCG1 (7)، V (8).',
        'R3 = CG مولّد الثوابت: يعطي 0 و1 و2 و0xFFFF دون قراءة الذاكرة، وR2 يعطي أيضاً 4 و8.',
        'R4–R15: 12 مسجل عمل داخل المعالج.',
      ],
      tour: <TourStepModel>[
        TourStepModel(
          '16 مسجلاً',
          'R0 إلى R3 لها وظائف خاصة، وR4 إلى R15 للعمل.',
          action: 'reset',
          focus: 'home',
        ),
        TourStepModel(
          'R1 مؤشر المكدس',
          'التعليمة الأولى تضع 0x0A00 في SP.',
          action: 'step',
        ),
        TourStepModel('R4 = 5', 'mov.w #5, R4', action: 'step'),
        TourStepModel('R5 = 0', 'clr.w R5', action: 'step'),
        TourStepModel('جمع', 'add.w R4, R5 فيصبح R5 = 5.', action: 'step'),
        TourStepModel(
          'إنقاص',
          'dec.w R4 فيصبح R4 = 4 والعلم Z = 0.',
          action: 'step',
        ),
        TourStepModel(
          'حتى النهاية',
          'تتكرر الحلقة حتى R4 = 0، فيصبح R5 = 15.',
          action: 'toEnd',
        ),
      ],
    ),
    TopicModel(
      id: 4,
      part: 0,
      indexInPart: 4,
      title: 'أنماط العنونة',
      shortTitle: 'العنونة',
      bookRef: 'الفصل 8 · ص 103',
      intro:
          'نمط العنونة يحدد من أين يأخذ المعالج القيمة. في MSP430 سبعة أنماط.',
      theory: <String>[
        'المسجل R4: القيمة داخل المسجل، دورة واحدة.',
        'المفهرس 2(R4): العنوان = محتوى المسجل + إزاحة.',
        'الرمزي VAR: العنوان = PC + إزاحة يحسبها المجمّع.',
        'المطلق ‎&0x0206‎: العنوان مكتوب كاملاً في التعليمة.',
        'غير المباشر ‎@R4‎: المسجل يحمل العنوان.',
        'مع زيادة ‎@R4+‎: مثل السابق ثم يزيد المسجل 2، مفيد للمصفوفات.',
        'الفوري ‎#0x1234‎: القيمة بعد التعليمة، للمصدر فقط.',
      ],
      tour: <TourStepModel>[
        TourStepModel(
          'نمط المسجل',
          'القيمة داخل R4 نفسه. دورة واحدة فقط.',
          action: 'run:reg',
          focus: 'home',
          seconds: 4.2,
        ),
        TourStepModel(
          'النمط المفهرس',
          'العنوان = R4 + 2، فيقرأ من 0x0202.',
          action: 'run:idx',
          seconds: 5.2,
        ),
        TourStepModel(
          'النمط المطلق',
          'العنوان مكتوب كاملاً داخل التعليمة.',
          action: 'run:abs',
          seconds: 4.6,
        ),
        TourStepModel(
          'غير المباشر',
          'R4 يحمل عنوان القيمة لا القيمة نفسها.',
          action: 'run:ind',
          seconds: 4.6,
        ),
        TourStepModel(
          'مع زيادة تلقائية',
          'يقرأ ثم يزيد R4 بمقدار 2، مفيد للمصفوفات.',
          action: 'run:inc',
          seconds: 4.6,
        ),
        TourStepModel(
          'النمط الفوري',
          'القيمة مكتوبة بعد التعليمة مباشرة.',
          action: 'run:imm',
          seconds: 4.2,
        ),
      ],
    ),
    // ───────────────────────────── part 2
    TopicModel(
      id: 5,
      part: 1,
      indexInPart: 1,
      title: 'مخطط الأطراف ووصفها',
      shortTitle: 'الأطراف',
      bookRef: 'الفصل 13 · ص 198',
      intro:
          'MSP430F149 في غلاف بـ 64 طرفاً، منها 48 طرف دخل وخرج موزعة على 6 منافذ.',
      theory: <String>[
        'الغلاف QFP بـ 64 طرفاً، 10 × 10 mm. الترقيم يبدأ من الطرف 1 عند النقطة، عكس عقارب الساعة.',
        'P1: الأطراف 12–19، و P2: 20–27، وكلاهما يدعم المقاطعة.',
        'P3: 28–35، و P4: 36–43، و P5: 44–51، و P6: 2–6 و 59–61 (مداخل ADC).',
        'الكريستالة على 8 و9 (XIN، XOUT)، و XT2 على 52 و53.',
        'التغذية على 1 و62 و63 و64، والبرمجة JTAG وإعادة التشغيل على 54–58.',
      ],
      tour: <TourStepModel>[
        TourStepModel(
          '64 طرفاً',
          'الطرف 1 في الزاوية عند النقطة، والترقيم عكس عقارب الساعة.',
          action: 'port:all',
          focus: 'home',
        ),
        TourStepModel(
          'المنفذ P1',
          'الأطراف 12–19، ويدعم المقاطعة.',
          action: 'port:P1',
          focus: 'P1',
        ),
        TourStepModel(
          'المنفذ P2',
          'الأطراف 20–27، ويدعم المقاطعة أيضاً.',
          action: 'port:P2',
          focus: 'P2',
        ),
        TourStepModel(
          'المنفذ P4',
          'الأطراف 36–43. في مشروع الكتاب يشغّل 8 مرحّلات.',
          action: 'port:P4',
          focus: 'P4',
        ),
        TourStepModel(
          'المنفذ P6',
          'مداخل المحول ADC.',
          action: 'port:P6',
          focus: 'P6',
        ),
        TourStepModel(
          'الكريستالة',
          'XIN و XOUT على الطرفين 8 و9.',
          action: 'port:clk',
          focus: 'clk',
        ),
      ],
    ),
    TopicModel(
      id: 6,
      part: 1,
      indexInPart: 2,
      title: 'الدخل والخرج العام GPIO',
      shortTitle: 'GPIO',
      bookRef: 'الفصل 5 · ص 69–72',
      intro:
          'كل طرف يمكن أن يكون دخلاً أو خرجاً، ونتحكم به بثلاثة مسجلات: DIR و OUT و IN.',
      theory: <String>[
        'كل المنافذ 8 بت، وتُتحكم بمسجلات في الذاكرة.',
        'PxDIR: البت 1 = خرج و0 = دخل، ويُصفّر عند التشغيل.',
        'PxOUT: القيمة التي تخرج على الطرف إذا كان خرجاً.',
        'PxIN: للقراءة فقط، ويعكس حالة الطرف الفعلية.',
        'PxSEL: يحوّل الطرف إلى وظيفة خاصة مثل USART أو ADC.',
        'P1 و P2 فيهما مسجلات المقاطعة PxIE و PxIES و PxIFG.',
      ],
      tour: <TourStepModel>[
        TourStepModel(
          'الطرف دخل',
          'عند التشغيل P1DIR = 0، فكل الأطراف دخل.',
          action: 'set:0:0',
          focus: 'led',
        ),
        TourStepModel(
          'نجعله خرجاً',
          'P1DIR.0 = 1 يجعل الطرف P1.0 خرجاً.',
          action: 'set:1:0',
        ),
        TourStepModel(
          'نكتب 1',
          'P1OUT.0 = 1 فيصبح الطرف 3.3 V ويضيء الـ LED.',
          action: 'set:1:1',
        ),
        TourStepModel(
          'نكتب 0',
          'P1OUT.0 = 0 فينطفئ الـ LED.',
          action: 'set:1:0',
        ),
        TourStepModel(
          'قراءة زر',
          'الزر على P1.1 دخل. عند ضغطه يصبح P1IN = 0x02.',
          action: 'press',
          focus: 'btn',
        ),
      ],
    ),
    TopicModel(
      id: 7,
      part: 1,
      indexInPart: 3,
      title: 'نظام الساعة',
      shortTitle: 'الساعة',
      bookRef: 'الفصل 4 · ص 39 · الفصل 12 · ص 190',
      intro:
          'داخل الشريحة ثلاث ساعات: MCLK للمعالج، و SMCLK للطرفيات السريعة، و ACLK البطيئة التي تبقى في النوم.',
      theory: <String>[
        'LFXT1: كريستالة ساعة 32.768 kHz، دقيقة وبطيئة.',
        'DCO: مذبذب داخلي سريع يتغير تردده، لكنه أقل دقة ويتأثر بالحرارة.',
        'XT2: كريستالة سريعة اختيارية حتى 8 MHz.',
        'MCLK للمعالج، و SMCLK للطرفيات السريعة، و ACLK من LFXT1.',
        'LPM0 يوقف المعالج فقط. LPM3 يبقي ACLK وحدها. LPM4 يوقف كل الساعات.',
        'المقاطعة توقظ المعالج، ويجب أن يكون GIE = 1 وإلا لن يستيقظ.',
      ],
      tour: <TourStepModel>[
        TourStepModel(
          'الوضع النشط',
          'كل الساعات تعمل، والتيار نحو 280 µA.',
          action: 'mode:am',
          focus: 'home',
        ),
        TourStepModel(
          'LPM0',
          'يتوقف المعالج، وتبقى SMCLK و ACLK.',
          action: 'mode:lpm0',
        ),
        TourStepModel(
          'LPM3',
          'تبقى ACLK فقط، والتيار 1.6 µA.',
          action: 'mode:lpm3',
        ),
        TourStepModel(
          'LPM4',
          'كل الساعات متوقفة. يستيقظ بمقاطعة خارجية فقط.',
          action: 'mode:lpm4',
        ),
        TourStepModel(
          'المقاطعة توقظه',
          'أي مقاطعة تعيد المعالج إلى الوضع النشط.',
          action: 'mode:am',
        ),
      ],
    ),
    TopicModel(
      id: 8,
      part: 1,
      indexInPart: 4,
      title: 'المؤقتات ووظائفها',
      shortTitle: 'المؤقتات',
      bookRef: 'الفصل 4 · ص 58 · الفصل 11 · ص 184',
      intro:
          'Timer_A يعدّ من 0 حتى TACCR0 ثم يعود. بهذا يولّد إشارة PWM دون تدخل المعالج.',
      theory: <String>[
        'Timer_A عداد بـ 16 بت اسمه TAR، يعدّ مع نبضات ACLK أو SMCLK.',
        'أنماط العدّ: Stop، و Up حتى TACCR0، و Continuous حتى 0xFFFF، و Up/Down.',
        'المقارنة TACCRx: عندما يساوي TAR قيمتها يرتفع علم ويتغير طرف الخرج.',
        'OUTMOD 7: الخرج يُصفّر عند TACCR1 ويُرفع عند TACCR0، فيتولد PWM.',
        'نسبة التشغيل = TACCR1 / TACCR0، والمعالج لا يتدخل ويمكنه أن ينام.',
        'PWM بديل عن DAC غير الموجود، وأشهر استعمال له التحكم بسرعة المحركات.',
      ],
      tour: <TourStepModel>[
        TourStepModel(
          'العداد TAR',
          'يصعد مع كل نبضة ساعة حتى 1000 ثم يعود إلى 0.',
          action: 'duty:40',
          focus: 'bar',
        ),
        TourStepModel(
          'نسبة 25%',
          'الخرج 1 حتى TACCR1 = 250 ثم 0. المحرك بطيء.',
          action: 'duty:25',
        ),
        TourStepModel(
          'نسبة 50%',
          'نصف الوقت 1 ونصفه 0.',
          action: 'duty:50',
        ),
        TourStepModel(
          'نسبة 75%',
          'المحرك أسرع.',
          action: 'duty:75',
          focus: 'motor',
        ),
        TourStepModel(
          'نسبة 100%',
          'الخرج دائماً 1 والمحرك بأقصى سرعة.',
          action: 'duty:100',
        ),
      ],
    ),
    // ───────────────────────────── part 3
    TopicModel(
      id: 9,
      part: 2,
      indexInPart: 1,
      title: 'مزايا وعيوب MSP430',
      shortTitle: 'المزايا والعيوب',
      bookRef: 'الفصول 2 · 4 · 12 · 13',
      intro: 'لكل متحكم مزايا وعيوب. هذه المزايا والعيوب مأخوذة من الكتاب نفسه.',
      theory: <String>[
        'ميزة: استهلاك منخفض جداً، نحو 1 mW لكل MIPS (ص 189).',
        'ميزة: معالج 16 بت و16 مسجلاً (ص 11–12)، وتعليمات قليلة وبسيطة (ص 103).',
        'ميزة: فضاء عناوين واحد (ص 11)، وطرفيات كثيرة، وينام ويستيقظ بالمقاطعة (ص 191).',
        'عيب: حساسية طرف RST للتشويش (ص 26)، و DCO أقل دقة (ص 43).',
        'عيب: تيار الطرف محدود (ص 197)، وسرعة محدودة (ص 190).',
        'عيب: لا DAC ولا I2C بالعتاد في F149 (ص 184).',
      ],
      tour: <TourStepModel>[
        TourStepModel(
          'مزايا وعيوب',
          'الكرات الخضراء مزايا والحمراء عيوب.',
          action: 'filter:all',
          focus: 'home',
        ),
        TourStepModel(
          'استهلاك منخفض جداً',
          'نحو 1 mW لكل MIPS، و1.6 µA فقط في LPM3.',
          action: 'open:pro:0',
          focus: 'pro:0',
        ),
        TourStepModel(
          'معالج 16 بت و16 مسجلاً',
          '12 مسجل عمل تقلّل الوصول للذاكرة.',
          action: 'open:pro:1',
          focus: 'pro:1',
        ),
        TourStepModel(
          'طرفيات كثيرة',
          'ADC12 ومؤقتان و USART عدد 2 ومضاعف.',
          action: 'open:pro:4',
          focus: 'pro:4',
        ),
        TourStepModel(
          'ينام ويستيقظ بالمقاطعة',
          'يعود للنوم تلقائياً بعد RETI.',
          action: 'open:pro:5',
          focus: 'pro:5',
        ),
        TourStepModel(
          'حساسية طرف RST للتشويش',
          'التشويش على RST/NMI قد يعيد تشغيل الشريحة.',
          action: 'open:con:0',
          focus: 'con:0',
        ),
        TourStepModel(
          'تيار الطرف محدود',
          'بضعة mA فقط، فالمرحّل يحتاج ترانزستوراً.',
          action: 'open:con:2',
          focus: 'con:2',
        ),
        TourStepModel(
          'لا DAC ولا I2C بالعتاد',
          'يُستعمل PWM بدل DAC، و I2C برمجياً في F149.',
          action: 'open:con:4',
          focus: 'con:4',
        ),
      ],
    ),
    TopicModel(
      id: 10,
      part: 2,
      indexInPart: 2,
      title: 'المحول التناظري الرقمي ADC',
      shortTitle: 'ADC',
      bookRef: 'الفصل 6 · ص 82',
      intro:
          'المحول ADC12 يحوّل الجهد إلى رقم من 0 إلى 4095 بالنسبة إلى جهد مرجعي.',
      theory: <String>[
        'ADC12 محول واحد بدقة 12 بت، فيه دائرة أخذ عينة وحفظها.',
        'أمامه مُبدّل يختار واحداً من 8 أطراف خارجية أو 4 مصادر داخلية، منها حساس حرارة.',
        'النتيجة N = 4095 × Vin / VREF+ وتُخزّن في ADC12MEMx.',
        'الجهد المرجعي الداخلي 1.5 V أو 2.5 V (البت 2_5V في ADC12CTL0).',
        'جهد أكبر من المرجع يعطي 4095 دائماً: هذا تشبّع.',
        'التحويل 13 دورة من ساعة المحول، وفيه مذبذب خاص يعمل والمعالج نائم.',
      ],
      tour: <TourStepModel>[
        TourStepModel('0 V', 'الجهد صفر، فالرقم 0.', action: 'set:0:2.5'),
        TourStepModel(
          'نصف المرجع',
          '1.25 V من 2.5 V، فالرقم 2048.',
          action: 'set:1.25:2.5',
        ),
        TourStepModel(
          'يساوي المرجع',
          'عند 2.5 V يصل الرقم إلى 4095.',
          action: 'set:2.5:2.5',
        ),
        TourStepModel(
          'تشبّع',
          'الجهد أكبر من المرجع، فيبقى الرقم 4095.',
          action: 'set:3:2.5',
        ),
        TourStepModel(
          'مرجع أصغر',
          'مع VREF+ = 1.5 V يصبح كل رقم أدق لكن المدى أصغر.',
          action: 'set:1:1.5',
        ),
      ],
    ),
    TopicModel(
      id: 11,
      part: 2,
      indexInPart: 3,
      title: 'واجهات الاتصال التسلسلي',
      shortTitle: 'الاتصال',
      bookRef: 'USART0 و USART1',
      intro: 'الاتصال التسلسلي يرسل البايت بتاً بعد بت على سلك واحد أو أكثر.',
      theory: <String>[
        'في F149 وحدتا USART، وكل واحدة تعمل UART أو SPI.',
        'UART غير متزامن على سلكين TX و RX: بت بداية، 8 بتات من الأصغر أولاً، بت توقف.',
        'SPI متزامن: SCLK للساعة، و MOSI و MISO للبيانات، و CS لاختيار الجهاز. من الأكبر أولاً.',
        'I2C على سلكين SCL و SDA: البداية، ثم العنوان (7 بت) و R/W، ثم ACK، ثم البيانات.',
        'لا يوجد I2C بالعتاد في F149، فيُنفَّذ برمجياً.',
      ],
      tour: <TourStepModel>[
        TourStepModel(
          'UART',
          'سلكان TX و RX: بت بداية، ثم 8 بتات، ثم بت توقف.',
          action: 'proto:uart',
          focus: 'home',
          seconds: 7.5,
        ),
        TourStepModel(
          'SPI',
          'سلك الساعة SCLK يحدد متى يُقرأ كل بت على MOSI.',
          action: 'proto:spi',
          seconds: 6.5,
        ),
        TourStepModel(
          'I2C',
          'سلكان فقط: SCL و SDA. يُرسل العنوان أولاً ثم البيانات.',
          action: 'proto:i2c',
          seconds: 9,
        ),
      ],
    ),
    TopicModel(
      id: 12,
      part: 2,
      indexInPart: 4,
      title: 'المقاطعات',
      shortTitle: 'المقاطعات',
      bookRef: 'الفصل 3 · ص 27–29',
      intro:
          'المقاطعة توقف البرنامج مؤقتاً لخدمة حدث، ثم يعود كل شيء كما كان.',
      theory: <String>[
        'كل المقاطعات القابلة للحجب تتوقف إذا كان GIE = 0، ولكل مصدر بت تمكين خاص.',
        'تكتمل التعليمة الحالية، ثم يُدفع PC ثم SR إلى المكدس.',
        'يُصفّر SR، فيتوقف GIE ويستيقظ المعالج من LPM.',
        'يُقرأ عنوان الروتين من جدول المتجهات حسب الأولوية، ثم يُنفَّذ ISR.',
        'reti يسحب SR ثم PC، فيعود المعالج إلى النوم إذا كان نائماً.',
        'جدول المتجهات 16 خانة من 0xFFE0 إلى 0xFFFE، والأعلى عنواناً أعلى أولوية.',
      ],
      tour: <TourStepModel>[
        TourStepModel(
          'المعالج نائم',
          'في LPM3 ينتظر حدثاً.',
          action: 'none',
          focus: 'home',
          seconds: 2.5,
        ),
        TourStepModel(
          'ضغطة زر',
          'الزر على Port 1 يولّد مقاطعة. تابع المكدس وجدول المتجهات.',
          action: 'fire:p1',
          seconds: 9,
        ),
        TourStepModel(
          'مقاطعة من المؤقت',
          'Timer_A يوقظ المعالج بالطريقة نفسها ثم يعود للنوم.',
          action: 'fire:ta',
          seconds: 9,
        ),
      ],
    ),
  ];
}
