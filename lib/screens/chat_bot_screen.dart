// lib/screens/chatbot_screen.dart
//
// pubspec.yaml (add):
// dependencies:
//   http: ^1.2.2
//   flutter_html: ^3.0.0-beta.2
//   url_launcher: ^6.3.0

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/colors.dart';
import '../constants/styles.dart';
import '../localization/language_constants.dart';
import '../widgets/reused_appbar.dart';

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({super.key});

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  /// Your backend endpoint that returns `{ ok: boolean, answer: "<html>" }`.
  /// Example: https://YOUR-DOMAIN/Help/Ask
  static const String kHelpAskUrl =
      'https://YOUR-DOMAIN/Help/Ask'; // <-- CHANGE ME

  /// Support phone (clickable)
  static const String kSupportPhone = '920031542';

  final _controller = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _inputFocus = FocusNode();

  final List<_Msg> _msgs = <_Msg>[];
  int _pairCounter = 0;
  bool _sending = false;
  bool _seededGreeting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_seededGreeting) {
      final isAr = Localizations.localeOf(context).languageCode == 'ar';
      _msgs.add(
        _Msg.ai(
          isAr
              ? 'مرحبًا! اسألني أي شيء عن التطبيق. جرّب: <i>“كيف أنشئ منشورًا؟”</i> أو اضغط <b>الدعم</b> للاتصال بنا.'
              : 'Hi! Ask me anything about the app. Try: <i>“How do I create a post?”</i> or tap <b>Support</b> to contact us.',
          pairId: -1,
        ),
      );
      _seededGreeting = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollCtrl.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  // -------------------- Helpers --------------------

  void _append(_Msg m) {
    setState(() => _msgs.add(m));
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  bool _containsArabic(String s) => RegExp(r'[\u0600-\u06FF]').hasMatch(s);

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  bool _isSupportQuery(String text) {
    final s = text.toLowerCase().trim();
    final hasAr = _containsArabic(text);
    return s == 'support' ||
        s.contains('help') ||
        s.contains('call center') ||
        s.contains('customer support') ||
        (hasAr &&
            (text.contains('الدعم') ||
                text.contains('مركز الاتصال') ||
                text.contains('خدمة العملاء') ||
                text.contains('اتصال') ||
                text.contains('مساعدة')));
  }

  // Whitelist-based in-scope detector (edit any time)
  bool _isInScope(String text) {
    final t = text.toLowerCase();
    final ar = _containsArabic(text);

    // EN topics
    final en = [
      'post',
      'create post',
      'new post',
      'accepted',
      'estate',
      'add estate',
      'edit estate', // NEW
      'update estate', // NEW
      'edit', // NEW (paired with other checks)
      'pencil', // NEW
      'hotel',
      'room',
      'single',
      'suite',
      'map',
      'location',
      'gps',
      'coordinates',
      'upload',
      'media',
      'pdf',
      'scope',
      'change scope',
      'pin',
      'pins',
      'access pin',
      'team access',
      'delete account',
      'account deletion',
      'login',
      'log in',
      'sign in',
      'register',
      'signup',
      'sign up',
    ];

    // AR topics
    final arList = [
      'منشور',
      'إضافة منشور',
      'مقبول',
      'منشأة',
      'إضافة منشأة',
      'منشاة',
      'تعديل معلومات المنشأة', // NEW
      'تعديل المنشأة', // NEW
      'تعديل', // NEW
      'قلم', // NEW (pencil)
      'فندق',
      'غرفة',
      'سنجل',
      'سويت',
      'خريطة',
      'الموقع',
      'إحداثيات',
      'تحميل',
      'رفع',
      'ملفات',
      'pdf',
      'النطاق',
      'تغيير الفروع',
      'أكواد',
      'رمز',
      'الوصول',
      'حذف الحساب',
      'تسجيل',
      'تسجيل دخول',
      'حساب'
    ];

    final hitEn = en.any((k) => t.contains(k));
    final hitAr = ar && arList.any((k) => text.contains(k));

    // Support is considered in-scope
    final support = _isSupportQuery(text);

    return hitEn || hitAr || support;
  }

  String _supportHtml(bool ar) {
    final telLink = '<a href="tel:$kSupportPhone">$kSupportPhone</a>';
    return ar
        ? "<b>الدعم الفني</b><br>يمكنك التواصل معنا على هذا الرقم: $telLink<br>"
        : "<b>Support</b><br>You can reach us at this number: $telLink<br>";
  }

  String _outOfScopeHtml(bool ar) {
    final tel = '<a href="tel:$kSupportPhone">$kSupportPhone</a>';
    return ar
        ? "<b>عذرًا، هذا السؤال خارج نطاق المساعد.</b><br>"
            "أستطيع مساعدتك فقط في أمور التطبيق مثل: <i>المنشورات، المنشآت، غرف الفندق، الخريطة/الموقع، الرفع، تغيير الفروع، أكواد الوصول، حذف الحساب</i>.<br>"
            "إن احتجت مساعدة إضافية، تواصل مع الدعم: $tel."
        : "<b>Sorry—this question is outside the assistant’s scope.</b><br>"
            "I can help with app topics only: <i>posts, estates, hotel rooms, map/location, uploads, scope changes, access PINs, account deletion</i>.<br>"
            "For further assistance, contact support: $tel.";
  }

  // -------------------- Send flow --------------------

  Future<void> _send() async => _sendText(_controller.text.trim());

  Future<void> _sendText(String text) async {
    if (text.isEmpty || _sending) return;

    final pairId = _pairCounter++;
    final isArLocale = Localizations.localeOf(context).languageCode == 'ar';
    final isArabic = _containsArabic(text) || isArLocale;

    // Add user message
    final userMsg = _Msg.me(text, pairId: pairId, createdAt: DateTime.now());
    _append(userMsg);

    // Placeholder AI
    _append(
        _Msg.ai(_loadingHtml(isArabic), pairId: pairId, isPlaceholder: true));

    // If this came from the input field, clear it
    if (_controller.text.trim() == text) {
      _controller.clear();
    }
    _inputFocus.requestFocus();

    await _answerFor(text, isArabic, pairId: pairId);
  }

  Future<void> _answerFor(String text, bool isArabic,
      {required int pairId}) async {
    if (_sending) return;
    setState(() => _sending = true);

    // 1) Built-in Support intent
    if (_isSupportQuery(text)) {
      final aiIndex =
          _msgs.lastIndexWhere((m) => !m.isMe && m.pairId == pairId);
      if (aiIndex != -1) {
        setState(() {
          _msgs[aiIndex] = _msgs[aiIndex].copyWith(
            html: _supportHtml(isArabic),
            isPlaceholder: false,
            createdAt: DateTime.now(),
          );
        });
      }
      setState(() => _sending = false);
      _scrollToEnd();
      return;
    }

    // 2) Scope guard: if not in scope, apologize (no backend call)
    if (!_isInScope(text)) {
      final aiIndex =
          _msgs.lastIndexWhere((m) => !m.isMe && m.pairId == pairId);
      if (aiIndex != -1) {
        setState(() {
          _msgs[aiIndex] = _msgs[aiIndex].copyWith(
            html: _outOfScopeHtml(isArabic),
            isPlaceholder: false,
            createdAt: DateTime.now(),
          );
        });
      }
      setState(() => _sending = false);
      _scrollToEnd();
      return;
    }

    // 3) In-scope → call backend
    try {
      final hintedText = isArabic
          ? 'رجاءً أجب بالعربية بشكل موجز وخطوات واضحة:\n$text'
          : 'Please answer in concise, step-by-step English:\n$text';

      final r = await http.post(
        Uri.parse(kHelpAskUrl),
        headers: const {
          'X-Requested-With': 'XMLHttpRequest',
          'Content-Type': 'application/x-www-form-urlencoded; charset=utf-8',
        },
        body: {'q': hintedText},
      );

      String html;
      if (r.statusCode == 200) {
        final data = json.decode(r.body) as Map<String, dynamic>;
        if (data['ok'] == true) {
          html = (data['answer'] ?? '').toString();
          if (html.isEmpty) html = _fallbackHtml(text, isArabic);
        } else {
          html = _fallbackHtml(text, isArabic);
        }
      } else {
        html = _fallbackHtml(text, isArabic);
      }

      // Replace placeholder
      final aiIndex =
          _msgs.lastIndexWhere((m) => !m.isMe && m.pairId == pairId);
      if (aiIndex != -1) {
        setState(() {
          _msgs[aiIndex] = _msgs[aiIndex].copyWith(
            html: html,
            isPlaceholder: false,
            createdAt: DateTime.now(),
          );
        });
      }
    } catch (_) {
      final aiIndex =
          _msgs.lastIndexWhere((m) => !m.isMe && m.pairId == pairId);
      if (aiIndex != -1) {
        setState(() {
          _msgs[aiIndex] = _msgs[aiIndex].copyWith(
            html: _fallbackHtml(text, isArabic),
            isPlaceholder: false,
            createdAt: DateTime.now(),
          );
        });
      }
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToEnd();
    }
  }

  // -------------------- Edit flow --------------------

  Future<void> _editUserMessage(_Msg userMsg) async {
    if (_sending) return;
    HapticFeedback.selectionClick();
    final initial = userMsg.text ?? '';
    final controller = TextEditingController(text: initial);

    final isArEnv = _containsArabic(initial) ||
        Localizations.localeOf(context).languageCode == 'ar';

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (ctx) {
        final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isArEnv ? 'تحرير الرسالة' : 'Edit message',
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  autofocus: true,
                  maxLines: 6,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText:
                        isArEnv ? 'اكتب رسالتك...' : 'Type your message...',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(isArEnv ? 'إلغاء' : 'Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () =>
                            Navigator.pop(ctx, controller.text.trim()),
                        child: Text(isArEnv ? 'حفظ' : 'Save'),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );

    if (result == null) return;

    final newText = result.trim();
    if (newText.isEmpty) {
      _snack(isArEnv
          ? 'لا يمكن حفظ رسالة فارغة.'
          : 'Cannot save an empty message.');
      return;
    }
    if (newText == initial) return;

    final userIndex = _msgs.indexOf(userMsg);
    if (userIndex == -1) return;

    final newIsArabic = _containsArabic(newText) ||
        Localizations.localeOf(context).languageCode == 'ar';

    setState(() {
      _msgs[userIndex] = _msgs[userIndex].copyWith(text: newText);
    });

    // Update paired AI to a loading placeholder, then re-answer
    final aiIndex =
        _msgs.indexWhere((m) => !m.isMe && m.pairId == userMsg.pairId);
    if (aiIndex != -1) {
      setState(() {
        _msgs[aiIndex] = _msgs[aiIndex].copyWith(
          html: _loadingHtml(newIsArabic),
          isPlaceholder: true,
          createdAt: DateTime.now(),
        );
      });
    } else {
      _append(_Msg.ai(_loadingHtml(newIsArabic),
          pairId: userMsg.pairId,
          isPlaceholder: true,
          createdAt: DateTime.now()));
    }

    await _answerFor(newText, newIsArabic, pairId: userMsg.pairId);
  }

  // -------------------- Content helpers --------------------

  String _loadingHtml(bool ar) => ar ? '… جارٍ التحميل' : '… loading';

  String _fallbackHtml(String q, bool ar) {
    // If user asked for support but backend failed, still show support.
    if (_isSupportQuery(q)) return _supportHtml(ar);

    final qq = q.toLowerCase();

    // ---- NEW: Edit Estate explicit answer (Profile Estate → pencil → Edit → Save)
    if (qq.contains('edit estate') ||
        (qq.contains('edit') && qq.contains('estate')) ||
        qq.contains('update estate') ||
        qq.contains('pencil') ||
        (_containsArabic(q) &&
            (q.contains('تعديل معلومات المنشأة') ||
                q.contains('تعديل المنشأة') ||
                (q.contains('تعديل') &&
                    (q.contains('منشأة') || q.contains('منشاة'))) ||
                q.contains('قلم')))) {
      return ar
          ? "<b>تعديل المنشأة</b><br>"
              "للتحرير اذهب إلى <b>ملف المنشأة</b> (Profile Estate) ثم اختر منشأتك واضغط على <b>أيقونة القلم ✏️</b>.<br>"
              "سيتم نقلك إلى شاشة <b>تعديل المنشأة</b> — حدّث البيانات المطلوبة ثم اضغط <b>حفظ</b>."
          : "<b>Edit your estate</b><br>"
              "Go to <b>Profile Estate</b>, pick your estate, then tap the <b>pencil icon ✏️</b>.<br>"
              "You’ll be taken to the <b>Edit Estate</b> screen — update the fields and press <b>Save</b>.";
    }

    if (qq.contains('create post') ||
        qq.contains('new post') ||
        qq.contains('post') ||
        _containsArabic(q) &&
            (q.contains('منشور') || q.contains('إضافة منشور'))) {
      return ar
          ? "<b>إضافة منشور</b><br>"
              "اذهب إلى <b>المنشورات → منشور جديد</b>، أضف الوصف/الصور أو الفيديو، ثم <b>حفظ</b>. "
              "فقط <b>المقبول (1)</b> يظهر في القائمة."
          : "<b>Create a Post</b><br>"
              "In main screen, go to <b>Posts → New Post</b>, add a description/media, then <b>Save</b>. "
              "Only <b>Accepted (1)</b> appear in the list.";
    }

    // ---- UPDATED: Add Estate with custom drawer icon ☰ from Main Screen
    if (qq.contains('add estate') ||
        qq.contains('create estate') ||
        qq.contains('add an estate') ||
        qq.contains('create an estate') ||
        qq.contains('estate') ||
        _containsArabic(q) &&
            (q.contains('إضافة منشأة') ||
                q.contains('منشأة') ||
                q.contains('منشاة'))) {
      return ar
          ? "<b>إضافة منشأة</b>"
              "<ul style='margin:6px 0 0 16px'>"
              "<li>من <b>الشاشة الرئيسية</b> اضغط <b>قائمة السحب ☰</b> (Custom Drawer).</li>"
              "<li>اختر <b>إضافة منشأة</b>.</li>"
              "<li>اختر <b>النوع (مطعم، مقهى، فندق)</b> واملأ بيانات منشأتك.</li>"
              "<li>حدد <b>موقعك</b>.</li>"
              "<li>قم <b>برفع صور منشأتك</b> و/أو ملفات PDF (اختياري).</li>"
              "<li><b>حفظ</b>.</li>"
              "</ul>"
          : "<b>Add an Estate</b>"
              "<ul style='margin:6px 0 0 16px'>"
              "<li>From the <b>Main Screen</b>, tap the <b>custom drawer ☰</b>.</li>"
              "<li>Choose <b>Add Estate</b>.</li>"
              "<li>Select the <b>Type (Restaurant, Coffee, Hotel)</b> and fill your estate details.</li>"
              "<li>Set your <b>Location</b>.</li>"
              "<li>Upload your <b>images</b> and/or optional <b>PDFs</b>.</li>"
              "<li><b>Save</b>.</li>"
              "</ul>";
    }

    if ((qq.contains('hotel') &&
            (qq.contains('room') ||
                qq.contains('single') ||
                qq.contains('suite'))) ||
        qq.contains('entry field') ||
        _containsArabic(q) &&
            (q.contains('غرفة') ||
                q.contains('فندق') ||
                q.contains('سنجل') ||
                q.contains('سويت'))) {
      return ar
          ? "<b>غرف الفندق</b><br>"
              "عند <b>النوع = فندق</b> أضف أنواع الغرف (سنجل/سويت…). "
              "حقل <i>Entry</i> يسرد الأنواع التي أدخلتها (مثل <code>single,suite</code>)."
          : "<b>Hotel Rooms</b><br>"
              "When Type=Hotel, add room types (Single/Suite…). "
              "The <i>Entry</i> field auto-lists selected types (e.g., <code>single,suite</code>).";
    }

    if (qq.contains('map') ||
        qq.contains('location') ||
        qq.contains('gps') ||
        qq.contains('coordinates') ||
        _containsArabic(q) &&
            (q.contains('خريطة') ||
                q.contains('الموقع') ||
                q.contains('إحداثيات'))) {
      return ar
          ? "<b>الخريطة والموقع</b><br>"
              "استخدم <b>استخدام موقعي</b> (يتطلب الإذن عبر HTTPS)، حرّك الدبوس، أو أدخل خط الطول/العرض ثم <b>تمركز</b>."
          : "<b>Map & Location</b><br>"
              "Use <b>Use my location</b> (HTTPS permission), drag the pin, or enter Lat/Lon then <b>Center</b>.";
    }

    if ((qq.contains('provider') && qq.contains('login')) ||
        qq.contains('typeuser') ||
        _containsArabic(q) && q.contains('مزود')) {
      return ar
          ? "<b>وصول المزوّد</b><br>"
              "فقط <b>المزوّدون (TypeUser=2)</b> يمكنهم استخدام لوحة التحكم. المستخدمون العاديون يستخدمون تطبيق Redak."
          : "<b>Provider Access</b><br>"
              "Only <b>providers (TypeUser=2)</b> can use the Dashboard. Regular users use the Redak app.";
    }

    if (qq.contains('pdf') ||
        qq.contains('upload') ||
        qq.contains('media') ||
        _containsArabic(q) &&
            (q.contains('تحميل') || q.contains('رفع') || q.contains('ملفات'))) {
      return ar
          ? "<b>الرفع</b><br>"
              "يمكنك رفع الصور وملفات PDF الاختيارية في إضافة/تعديل المنشأة. تُحفظ الملفات في Firebase Storage."
          : "<b>Uploads</b><br>"
              "Upload images and optional PDFs on Add/Edit Estate. Files are stored in Firebase Storage.";
    }

    if (qq.contains('change scope') ||
        qq.contains('switch scope') ||
        qq.contains('scope') ||
        _containsArabic(q) && q.contains('النطاق')) {
      return ar
          ? "<b>تغيير الفروع</b>"
              "<ul style='margin:6px 0 0 16px'>"
              "<li>من الشاشة الرئيسية <b>الوصول → تغيير الفروع</b>.</li>"
              "<li>اختر <b>الكل</b> أو منشأة محددة.</li>"
              "<li>اضغط <b>تطبيق</b>.</li>"
              "</ul>"
          : "<b>Change Branch</b>"
              "<ul style='margin:6px 0 0 16px'>"
              "<li>From Main Screen <b>→ Change Branch</b>.</li>"
              "<li>Select <b>ALL</b> or a specific estate.</li>"
              "<li>Click <b>Apply</b>.</li>"
              "</ul>";
    }

    if (qq.contains('pin') ||
        qq.contains('pins') ||
        qq.contains('access pin') ||
        qq.contains('team access') ||
        _containsArabic(q) &&
            (q.contains('رمز') ||
                q.contains('أكواد') ||
                q.contains('الوصول'))) {
      return ar
          ? "<b>إدارة أكواد الوصول</b>"
              "<ul style='margin:6px 0 0 16px'>"
              "<li>اذهب إلى <b>الوصول → أكواد الوصول</b>.</li>"
              "<li>أضف كودًا واختر <b>النطاق</ب>.</li>"
              "<li>حدد الأذونات ثم <b>حفظ</b>.</li>"
              "</ul>"
          : "<b>Manage PINs</b>"
              "<ul style='margin:6px 0 0 16px'>"
              "<li>Go to <b>Access → Access PINs</b>.</li>"
              "<li>Add a PIN & choose <b>scope</b>.</li>"
              "<li>Set permissions and <b>Save</b>.</li>"
              "</ul>";
    }

    if (qq.contains('delete account') ||
        qq.contains('remove account') ||
        qq.contains('account deletion') ||
        _containsArabic(q) && q.contains('حذف الحساب')) {
      return ar
          ? "<b>حذف الحساب</ب>"
              "<ul style='margin:6px 0 0 16px'>"
              "<li>افتح <b>الإعدادات</b>.</li>"
              "<li>اضغط <b>حذف حسابي</ب> ثم أكد.</li>"
              "<li>للمساعدة: <a href='mailto:acc@dhtechs.net'>acc@dhtechs.net</a>.</li>"
              "</ul>"
          : "<b>Delete Account</b>"
              "<ul style='margin:6px 0 0 16px'>"
              "<li>Open <b>Settings</b>.</li>"
              "<li>Click <b>Delete my account</b> and confirm.</li>"
              "<li>Or email <a href='mailto:acc@dhtechs.net'>acc@dhtechs.net</a>.</li>"
              "</ul>";
    }

    // Default (still in-scope unknown): brief capabilities + support.
    return ar
        ? "مرحبا أستطيع مساعدتك في إضافة المنشآات، إضافة المنشورات، غرف الفندق، الخريطة/الموقع، الرفع، تغيير الفروع، أكواد الوصول، وحذف الحساب. وللدعم اتصل على <a href='tel:$kSupportPhone'>$kSupportPhone</a>."
        : "Hi! I can help with adding estates, posts, hotel rooms, map/location, uploads, scope, PINs, and account deletion. For support call <a href='tel:$kSupportPhone'>$kSupportPhone</a>.";
  }

  // -------------------- Quick actions --------------------

  List<_QuickItem> _quickPrompts(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return [
      _QuickItem(
        label: isAr ? 'الدعم' : 'Support',
        text: isAr ? 'الدعم' : 'support',
      ),
      _QuickItem(
        label: isAr ? 'إضافة منشور' : 'Create Post',
        text: isAr ? 'إضافة منشور' : 'create post',
      ),
      _QuickItem(
        label: isAr ? 'إضافة منشأة' : 'Add Estate',
        text: isAr ? 'إضافة منشأة' : 'add estate',
      ),
      // _QuickItem(
      //   label: isAr ? 'غرف الفندق' : 'Hotel Rooms',
      //   text: isAr ? 'غرف الفندق' : 'hotel rooms',
      // ),
      // _QuickItem(
      //   label: isAr ? 'الخريطة/الموقع' : 'Map & Location',
      //   text: isAr ? 'الخريطة الموقع' : 'map location',
      // ),
      _QuickItem(
        label: isAr ? 'تغيير الفروع' : 'Change Branch',
        text: isAr ? 'تغيير الفروع' : 'change scope',
      ),
      _QuickItem(
        label: isAr ? 'أكواد الوصول' : 'Access PINs',
        text: isAr ? 'أكواد الوصول' : 'access pin',
      ),
      _QuickItem(
        label: isAr ? 'حذف الحساب' : 'Delete Account',
        text: isAr ? 'حذف الحساب' : 'delete account',
      ),
      // NEW quick action for Edit Estate
      _QuickItem(
        label: isAr ? 'تعديل معلومات المنشأة' : 'Edit Estate',
        text: isAr ? 'تعديل معلومات المنشأة' : 'edit estate',
      ),
    ];
  }

  Widget _quickBar(double horizontalPadding, double maxWidth) {
    final items = _quickPrompts(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 8),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth), // <- fix here
        child: SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (ctx, i) {
              final it = items[i];
              return ActionChip(
                label: Text(it.label),
                onPressed: () => _sendText(it.text),
                backgroundColor: Colors.grey.shade200,
                labelStyle: Theme.of(context).textTheme.bodyMedium,
                side: BorderSide(color: Colors.grey.shade300),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // -------------------- UI --------------------

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isWide = media.size.width >= 900;

    // Bubble width scales nicely across phones/tablets/desktops
    final maxBubbleWidth =
        isWide ? 720.0 : media.size.width.clamp(320.0, 600.0) * 0.9;
    final horizPad = isWide ? (media.size.width - maxBubbleWidth) / 2 : 12.0;

    return Scaffold(
      appBar: ReusedAppBar(title: getTranslated(context, "Chat Bot")),
      body: Column(
        children: [
          Expanded(
            child: ScrollConfiguration(
              behavior: const _NoGlowBehavior(),
              child: ListView.builder(
                controller: _scrollCtrl,
                padding:
                    EdgeInsets.symmetric(horizontal: horizPad, vertical: 16),
                itemCount: _msgs.length,
                itemBuilder: (context, i) {
                  final m = _msgs[i];
                  final isMe = m.isMe;

                  // Bubble widget
                  final bubble = Container(
                    constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isMe
                          ? kPrimaryColor.withOpacity(.10)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isMe
                            ? kPrimaryColor.withOpacity(.25)
                            : Colors.grey.shade300,
                      ),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                          color: Colors.black.withOpacity(0.04),
                        ),
                      ],
                    ),
                    child: isMe
                        ? Text(
                            m.text!,
                            style: kSecondaryStyle.copyWith(fontSize: 15),
                            textDirection: _containsArabic(m.text!)
                                ? TextDirection.rtl
                                : TextDirection.ltr,
                          )
                        : Html(
                            data: m.html ?? '',
                            style: {
                              "body": Style(
                                margin: Margins.zero,
                                padding: HtmlPaddings.zero,
                                fontSize: FontSize(15),
                              ),
                              "ul": Style(margin: Margins.only(left: 12)),
                              "ol": Style(margin: Margins.only(left: 12)),
                              "code": Style(
                                backgroundColor: Colors.black.withOpacity(0.05),
                                padding: HtmlPaddings.all(4),
                                fontFamily: 'monospace',
                              ),
                            },
                            onLinkTap: (url, attrs, element) async {
                              if (url == null) return;
                              final uri = Uri.parse(url);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri,
                                    mode: LaunchMode.externalApplication);
                              } else {
                                _snack('Could not open: $url');
                              }
                            },
                          ),
                  );

                  final timestamp = m.createdAt != null
                      ? Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            _formatTime(m.createdAt!),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: Colors.grey.shade600),
                          ),
                        )
                      : const SizedBox.shrink();

                  if (isMe) {
                    return Align(
                      alignment: Alignment.centerRight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Tappable bubble (long-press / double-tap to edit)
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onLongPress: () => _showMessageMenu(m),
                              onDoubleTap: () => _editUserMessage(m),
                              child: bubble,
                            ),
                          ),
                          timestamp,
                        ],
                      ),
                    );
                  } else {
                    // AI bubble (no kebab)
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [bubble, timestamp],
                      ),
                    );
                  }
                },
              ),
            ),
          ),

          // Quick actions bar
          _quickBar(horizPad, maxBubbleWidth),

          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(horizPad, 6, horizPad, 12),
              child: _InputBar(
                controller: _controller,
                focusNode: _inputFocus,
                sending: _sending,
                hintText: getTranslated(context, "Ask a question..."),
                onSend: _send,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Bottom-sheet menu (alternative access via long-press)
  Future<void> _showMessageMenu(_Msg m) async {
    final isAr = _containsArabic(m.text ?? '') ||
        Localizations.localeOf(context).languageCode == 'ar';

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MenuTile(
                icon: Icons.edit,
                label: isAr ? 'تحرير' : 'Edit',
                onTap: () {
                  Navigator.pop(ctx);
                  _editUserMessage(m);
                },
              ),
              _MenuTile(
                icon: Icons.copy,
                label: isAr ? 'نسخ' : 'Copy',
                onTap: () {
                  Navigator.pop(ctx);
                  Clipboard.setData(ClipboardData(text: m.text ?? ''));
                  _snack(isAr ? 'تم النسخ' : 'Copied');
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dt) {
    final timeOfDay = TimeOfDay.fromDateTime(dt);
    final h = timeOfDay.hourOfPeriod == 0 ? 12 : timeOfDay.hourOfPeriod;
    final m = timeOfDay.minute.toString().padLeft(2, '0');
    final ampm = timeOfDay.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }
}

// -------------------- Widgets --------------------

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.hintText,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final String? hintText;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                focusNode: focusNode,
                controller: controller,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: hintText ?? 'Type…',
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 6),
            IconButton.filled(
              onPressed: sending ? null : onSend,
              tooltip: getTranslated(context, "Send") ?? "Send",
              icon: sending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: onTap,
      dense: true,
      minLeadingWidth: 24,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}

// Removes overscroll glow for a cleaner, professional look
class _NoGlowBehavior extends ScrollBehavior {
  const _NoGlowBehavior();
  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

// -------------------- Model --------------------

class _Msg {
  final bool isMe;
  final int pairId; // groups user + ai
  final String? text; // user's plain text (if isMe)
  final String? html; // assistant's HTML (if !isMe)
  final bool isPlaceholder;
  final DateTime? createdAt;

  _Msg.me(this.text, {required this.pairId, this.createdAt})
      : isMe = true,
        html = null,
        isPlaceholder = false;

  _Msg.ai(this.html,
      {required this.pairId, this.isPlaceholder = false, this.createdAt})
      : isMe = false,
        text = null;

  _Msg copyWith({
    String? text,
    String? html,
    bool? isPlaceholder,
    DateTime? createdAt,
  }) {
    if (isMe) {
      return _Msg.me(text ?? this.text,
          pairId: pairId, createdAt: createdAt ?? this.createdAt);
    } else {
      return _Msg.ai(
        html ?? this.html,
        pairId: pairId,
        isPlaceholder: isPlaceholder ?? this.isPlaceholder,
        createdAt: createdAt ?? this.createdAt,
      );
    }
  }
}

class _QuickItem {
  final String label;
  final String text;
  _QuickItem({required this.label, required this.text});
}
