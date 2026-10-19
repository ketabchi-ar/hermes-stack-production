# Hermes Stack Production (Secure, Autostart & Cloudflare Tunnel)

یک پکیج کامل، خودکار و امن برای راه‌اندازی و مدیریت مجموعه **Hermes Stack** بر روی سرورهای ابری (مانند Hetzner، DigitalOcean، Freestyle و Ubuntu 22.04 / 24.04).

این پروژه تمامی مراحل نصب، امن‌سازی، رمزگذاری، پروکسی Nginx، ایجاد سرویس‌های Systemd جهت راه‌اندازی خودکار بعد از ریستارت سرور (Auto-boot) و اکسپوز کردن سرویس‌ها از طریق **Cloudflare Tunnel با SSL معتبر** را در قالب یک اسکریپت آماده انجام می‌دهد.

---

## 🚀 سرویس‌های موجود در این پکیج

1. **Hermes Agent & CLI**: دستیار هوش مصنوعی و مدل‌های کلاینت.
2. **Hermes WebUI**: داشبورد وب برای مدیریت گفتگوها و هرمس روی پورت `8787` (محافظت‌شده با رمز عبور اختصاصی).
3. **9Router**: گیت‌وی توزیع مدل‌های هوش مصنوعی (پورت داخلی `20126`، پروکسی‌شده به پورت `20128` با Nginx و HTTP Basic Auth).
4. **OmniRoute**: روتر لودبالانسینگ و سوئیچ مدل‌ها روی پورت `20129`.
5. **Nginx Reverse Proxy**: لایه امنیتی، مدیریت هدرها، پروتکل IPv4/IPv6 دوگانه‌سوز و احراز هویت.
6. **Cloudflare Tunnels**: اتصال امن و رمزنگاری‌شده (HTTPS / SSL) بدون نیاز به باز کردن پورت فایروال یا آی‌پی ثابت.

---

## ⚡ نحوه نصب سریع با یک دستور (Quick Start)

روی سرور ابری (اوبونتو):

```bash
git clone https://github.com/ketabchi-ar/hermes-stack-prod.git ~/hermes-stack-prod
cd ~/hermes-stack-prod
chmod +x install.sh
./install.sh
```

### تنظیم رمزهای عبور اختصاصی هنگام نصب (اختیاری):

اگر متغیرها تعریف نشوند، اسکریپت به صورت خودکار یک رمز ایمن تصادفی تولید کرده و در سرور ذخیره می‌کند:

```bash
HERMES_WEBUI_PASSWORD="YourStrongPassword123!" \
HERMES_ROUTER_PASSWORD="YourStrongRouterPass!" \
HERMES_ROUTER_USER="admin" \
./install.sh
```

---

## 🔑 امنیت و رمزهای عبور

- اطلاعات ورود تولیدشده به صورت اختصاصی روی سرور شما در مسیر امن `~/.hermes/credentials.txt` ذخیره می‌شوند.
- هیچ رمز یا توکن پیش‌فرضی درون فایل‌های مخزن گیت‌هاب قرار ندارد.

---

## 🛠️ دستورات مدیریتی پس از نصب

پس از اجرای اسکریپت، دستورات زیر در خط فرمان لینوکس در دسترس خواهند بود:

- **مشاهده وضعیت سرویس‌ها**:
  ```bash
  hermes-stack-status
  ```
- **شروع تمام سرویس‌ها**:
  ```bash
  hermes-stack-start
  ```
- **توقف سرویس‌ها**:
  ```bash
  hermes-stack-stop
  ```
- **مشاهده آدرس‌های عمومی Cloudflare (SSL) و وضعیت سرور**:
  ```bash
  hermes-public-url
  ```
- **اجرای مستقیم ایجنت هرمس**:
  ```bash
  hermes
  ```

---

## 📂 ساختار فایل‌های پروژه

```text
.
├── install.sh                  # اسکریپت جامع نصب، پیکربندی و راه‌اندازی
├── config/
│   └── webui.env.example       # نمونه متغیرهای محیطی WebUI
├── nginx/
│   └── 9router.conf            # تنظیمات Nginx Reverse Proxy و هدرهای WebSocket
├── scripts/
│   ├── start.sh                # اسکریپت استارت یکپارچه
│   ├── stop.sh                 # اسکریپت استاپ
│   ├── status.sh               # چک وضعیت لحظه‌ای سرویس‌ها
│   └── hermes-public-url.sh    # واکشی آدرس‌های تونل کلودفلر
├── systemd/
│   ├── hermes-webui.service
│   ├── hermes-9router.service
│   ├── hermes-omniroute.service
│   ├── hermes-tunnel.service
│   └── hermes-9router-tunnel.service
└── README.md
```

---

## 🔄 راه‌اندازی خودکار با ریستارت سیستم (Auto-start)

تمامی سرویس‌ها دارای واحد‌های مستقل `systemd` هستند و بعد از هرگونه ریست یا کرش سیستم، به صورت کاملاً خودکار فعال می‌شوند.
برای چک کردن لاگ هر سرویس به صورت زنده:

```bash
journalctl -u hermes-webui -f
journalctl -u hermes-9router -f
journalctl -u hermes-tunnel -f
```

---

## 🛡️ تغییر رمزهای عبور در آینده

1. **تغییر رمز Hermes WebUI**:
   فایل `~/hermes-webui/.env` را ویرایش کرده و سرویس را ریستارت کنید:
   ```bash
   sudo systemctl restart hermes-webui
   ```

2. **تغییر رمز Nginx و ورودی 9Router**:
   ```bash
   sudo htpasswd -b /etc/nginx/.htpasswd admin NEW_PASSWORD
   sudo systemctl reload nginx
   ```
