# OpenVPN build and device test

تم اختيار `openvpn_flutter: ^1.3.4` بدلاً من `flutter_openvpn` لأن `flutter_openvpn 0.2.0` قديمة ومعلّمة بأنها غير متوافقة مع Dart 3، كما أن `flutter_v2ray` مخصصة لبروتوكول V2Ray وليست لملفات `.ovpn`.

## المتطلبات

- Flutter stable
- Android SDK + platform tools
- JDK 11 أو 17 أو 21
- هاتف Android حقيقي، وليس محاكيًا، لتجربة VPN
- تفعيل Developer options وUSB debugging

## بناء APK Debug

من جذر المشروع:

```bash
export FLUTTER_HOME=/path/to/flutter
export ANDROID_HOME=$HOME/Android/Sdk
export JAVA_HOME=/path/to/jdk
chmod +x scripts/build_apk.sh
./scripts/build_apk.sh
```

الملف الناتج:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

أو بالأوامر المباشرة:

```bash
flutter pub get
flutter analyze --no-fatal-infos
flutter test
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

## تثبيت وتشغيل على الهاتف

```bash
adb devices
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb shell am start -n com.example.vpn_luxe/.MainActivity
adb logcat | grep -i -E 'openvpn|nova|vpn'
```

عند أول اتصال سيظهر طلب Android لإنشاء اتصال VPN؛ وافق عليه يدوياً.

## Release APK

لا تستخدم debug في الإنتاج. أنشئ keystore خاصاً ثم اربطه في `android/key.properties` و`android/app/build.gradle.kts`:

```bash
flutter build apk --release --split-per-abi
```

## iOS

حزمة `openvpn_flutter` تحتاج App Groups وNetwork Extension وTarget من نوع Packet Tunnel Provider. كما يجب ضبط:

- `groupIdentifier: group.com.nova.vpn`
- `providerBundleIdentifier: com.example.vpn_luxe.VPNExtension`
- OpenVPNAdapter داخل Target الخاص بالـ Network Extension

لا يمكن اختبار VPN iOS على Simulator؛ استخدم جهاز iPhone حقيقياً.

## ملاحظات VPNGate

- ملفات VPNGate العامة غير مضمونة الخصوصية أو الاستقرار.
- يفضل استخدام HTTPS proxy خاص بك بدلاً من جلب ملف API عبر HTTP مباشرة.
- لا تحفظ ملفات `.ovpn` في السجلات أو التحليلات.
- النسخة الحالية تمرر نص `.ovpn` المفكوك إلى `openvpn_flutter` في الذاكرة.
