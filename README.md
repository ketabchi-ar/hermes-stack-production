# Hermes Stack Production (Secure, Autostart & Cloudflare Tunnel)

یک پکیج کامل، خودکار و امن برای راه‌اندازی و مدیریت مجموعه **Hermes Stack** بر روی سرورهای ابری (مانند Hetzner، DigitalOcean، Freestyle و Ubuntu 22.04 / 24.04).

این پروژه تمامی مراحل نصب، امن‌سازی، رمزگذاری، پروکسی Nginx، ایجاد سرویس‌های Systemd جهت راه‌اندازی خودکار بعد از ریستارت سرور (Auto-boot) و اکسپوز کردن سرویس‌ها از طریق **Cloudflare Tunnel با SSL معتبر** را در قالب یک اسکریپت آماده انجام می‌دهد.

---

## 🚀 ویژگی‌ها و سرویس‌های موجود در این پکیج

1. **Hermes Agent & CLI**: دستیار هوش مصنوعی و مدل‌های کلاینت.
2. **Hermes WebUI**: داشبورد وب برای مدیریت گفتگوها و هرمس روی پورت `8787` (محافظت‌شده با رمز عبور اختصاصی).
3. **9Router**: گیت‌وی توزیع مدل‌های هوش مصنوعی (پورت داخلی `20126`، پروکسی‌شده به پورت `20128` با Nginx و HTTP Basic Auth).
4. **OmniRoute**: روتر لودبالانسینگ و سوئیچ مدل‌ها روی پورت `20129`.
5. **Nginx Reverse Proxy**: لایه امنیتی، مدیریت هدرها، پروتکل IPv4/IPv6 دوگانه‌سوز و احراز هویت.
6. **Cloudflare Tunnels**: اتصال امن و رمزنگاری‌شده (HTTPS / SSL) بدون نیاز به باز کردن پورت فایروال یا آی‌پی ثابت.
7. **🤖 مدل پیش‌فرض Gemini 3.8 Flash (Medium) (اختیاری)**: تنظیم مستقیم مدل سریع و پرقدرت `ag/gemini-3.8-flash-medium` از طریق 9Router Antigravity به همراه سطح استدلال متوسط (Medium Reasoning).
8. **🇮🇷 بومی‌سازی کامل فارسی و فونت وزیرمتن (اختیاری)**: ادغام رسمی با پروژه [hermes-agent-farsi](https://github.com/m4tinbeigi-official/hermes-agent-farsi) جهت فارسی‌سازی کامل داشبورد، چیدمان راست‌چین (RTL) و فونت زیبای وزیرمتن (Vazirmatn).

---

## ⚡ نحوه نصب سریع (Quick Start)

روی سرور ابری (اوبونتو):

```bash
git clone https://github.com/ketabchi-ar/hermes-stack-production.git ~/hermes-stack-production
cd ~/hermes-stack-production
chmod +x install.sh
./install.sh
```

در حالت پیش‌فرض و تعاملی، اسکریپت گزینه‌های زیر را از شما سوال می‌پرسد:
- آیا مایلید مدل پیش‌فرض روی **Gemini 3.8 Flash (Medium)** تنظیم شود؟ `[Y/n]`
- آیا مایلید **بومی‌سازی فارسی و فونت وزیرمتن (hermes-agent-farsi)** فعال شود؟ `[Y/n]`

---

## ⚙️ گزینه‌ها و فلگ‌های خط فرمان (CLI Flags)

می‌توانید گزینه‌های دلخواه خود را مستقیماً هنگام اجرای اسکریپت تعیین کنید:

```bash
# نصب کامل با فعال‌سازی فارسی و مدل جمینای ۳.۸ فلش:
./install.sh --gemini-flash --farsi

# نصب بدون تغییر مدل یا بدون زبان فارسی:
./install.sh --no-gemini-flash --no-farsi

# تعیین مدل دلخواه دیگر:
./install.sh --model "ag/gemini-pro-agent"

# اجرای خودکار بدون پرسش (Non-interactive):
./install.sh -y --gemini-flash --farsi
```

### جدول گزینه‌های خط فرمان:

| فلگ | توضیح |
| :--- | :--- |
| `--farsi`, `--persian` | نصب و فعال‌سازی زبان فارسی و فونت وزیرمتن ([hermes-agent-farsi](https://github.com/m4tinbeigi-official/hermes-agent-farsi)) |
| `--no-farsi` | عدم نصب بسته زبان فارسی |
| `--gemini-flash` | تنظیم مدل پیش‌فرض هرمس روی `ag/gemini-3.8-flash-medium` از طریق ۹Router |
| `--no-gemini-flash` | عدم تغییر مدل پیش‌فرض |
| `--model <ID>` | تنظیم شناسه مدل پیش‌فرض سفارشی |
| `--webui-password <P>` | تنظیم رمز عبور داشبورد WebUI |
| `--router-password <P>` | تنظیم رمز عبور امنیتی 9Router |
| `--router-user <U>` | نام کاربری 9Router (پیش‌فرض: `admin`) |
| `-y`, `--non-interactive` | اجرای خودکار بدون توقف برای سوالات تعاملی |
| `-h`, `--help` | نمایش راهنمای اسکریپت |

---

## 🔧 تنظیم با متغیرهای محیطی (Environment Variables)

برای استفاده در اسکریپت‌های اتوماسیون (مانند CI/CD یا Cloud-init):

```bash
HERMES_SET_GEMINI_FLASH=true \
HERMES_INSTALL_FARSI=true \
HERMES_WEBUI_PASSWORD="YourStrongPassword123!" \
HERMES_ROUTER_PASSWORD="YourStrongRouterPass!" \
HERMES_ROUTER_USER="admin" \
./install.sh -y
```

---

## 🔑 امنیت و رمزهای عبور

- اطلاعات ورود تولیدشده به صورت اختصاصی روی سرور شما در مسیر امن `~/.hermes/credentials.txt` ذخیره می‌شوند.
- در این فایل وضعیت مدل پیش‌فرض انتخابی و زبان سیستم نیز ثبت می‌گردد.
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
├── install.sh                  # اسکریپت جامع نصب، پیکربندی و راه‌اندازی (با پشتیبانی از Farsi و Gemini 3.8)
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
