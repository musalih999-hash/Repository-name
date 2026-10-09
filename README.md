# NOVA VPN

تطبيق Flutter بواجهة Dark Luxury، يدعم خوادم WireGuard المدارة وخوادم VPNGate العامة عبر OpenVPN.

## تشغيل محلي سريع

```bash
flutter pub get
flutter analyze --no-fatal-infos
flutter test
flutter run
```

## بناء APK محلياً

```bash
flutter build apk --debug
flutter build apk --release
```

الملفات الناتجة:

```text
build/app/outputs/flutter-apk/app-debug.apk
build/app/outputs/flutter-apk/app-release.apk
```

## GitHub Actions

يوجد Workflow في:

```text
.github/workflows/build.yml
```

يعمل تلقائياً عند كل `push` أو `pull_request`، ويمكن تشغيله يدوياً من تبويب **Actions** عبر **Run workflow**. يقوم بـ:

1. تثبيت Flutter وJava.
2. تشغيل `flutter pub get` و`flutter analyze` و`flutter test`.
3. بناء Debug APK وRelease APK.
4. رفعهما كـ Artifacts باسم:
   - `nova-vpn-debug-apk`
   - `nova-vpn-release-apk`
5. رفع ملف `SHA256SUMS.txt`.

بعد انتهاء التشغيل افتح:

```text
GitHub → Actions → Build NOVA VPN APK → آخر Run → Artifacts
```

ثم اختر Artifact المطلوب واضغط Download. روابط Artifacts في GitHub تتطلب صلاحية الوصول للمستودع وتنتهي حسب مدة الاحتفاظ المحددة في Workflow.

> نسخة Release الحالية تستخدم إعداد التوقيع الموجود في المشروع. قبل النشر على Google Play أضف Keystore سرياً إلى GitHub Secrets واربط signing config بدلاً من debug signing.

## VPNGate وOpenVPN

يتطلب الاتصال الحقيقي إضافة إعدادات `openvpn_flutter` الأصلية وNetwork Extension على iOS. راجع [OPENVPN_BUILD.md](OPENVPN_BUILD.md).

## ملاحظات أمنية

- لا تضع مفاتيح WireGuard أو Keystore أو Firebase Service Account داخل Git.
- خوادم VPNGate عامة ومتغيرة؛ لا تقدم ضمان خصوصية أو استقرار تجارياً.
- يفضل استخدام مصدر HTTPS موثوق لخدمات الإنتاج.
