# NOVA VPN Health Agent

## التشغيل المحلي

```bash
cd backend
python3 -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
python health_agent.py
```

ضع بيانات الخوادم في `servers.json` أو عيّن `SERVERS_JSON`. الوضع الافتراضي يكتب إلى Firestore باستخدام `FIREBASE_SERVICE_ACCOUNT`. لتشغيل MongoDB استخدم `DATABASE=mongo` و`MONGO_URI`.

## Cron كل 5 دقائق

```cron
*/5 * * * * cd /opt/nova-vpn/backend && . .venv/bin/activate && /usr/bin/flock -n /tmp/nova-health.lock python health_agent.py >> /var/log/nova-health.log 2>&1
```

`FASTEST` يذهب إلى أفضل خادم نشط حسب ping ثم load ثم response. `LOW PING` يذهب لأفضل ثلاثة خوادم نشطة. الخادم لا يصبح غير نشط بعد فشل واحد؛ يلزم `MAX_FAILURES` (الافتراضي 2) لتجنب التقلبات.

> WireGuard يستخدم UDP، لذلك لا يوجد TCP handshake تقليدي على 51820. فحص UDP يثبت قابلية الوصول المحلية فقط. للحصول على صحة حقيقية، أضف `metrics_url` على كل خادم يعيد `active_connections` و`max_connections` ويفضل `latest_handshake_age_seconds` من `wg show`.
