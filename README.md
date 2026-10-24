# HackTricks Offline Android APK & Otomasyon Sistemi

Bu proje, **[HackTricks](https://hacktricks.wiki)** siber güvenlik ve pentest dokümantasyonunu (hem **Türkçe** hem **İngilizce** olarak) %100 çevrimdışı (offline) çalışabilir bir Android APK uygulamasına dönüştürür ve dokümantasyonu sürekli taze tutmak için otomatik bir CI/CD derleme hattı sunar.

---

## 🚀 Temel Özellikler

- **%100 Offline (İnternetsiz):** Tüm sayfalar, komutlar, sekmeler ve kod blokları uygulamanın içerisine gömülüdür.
- **Çift Dil Desteği (TR & EN):**
  - 🇹🇷 **Türkçe:** `tr` branch'indeki topluluk çevirileri.
  - 🇬🇧 **İngilizce:** `master` branch'indeki en güncel ana dokümantasyon.
  - Şık açılış portalından tek dokunuşla dil seçimi.
- **Anlık Yerel Arama (Search Engine):** mdBook'un yerel arama motoru entegredir, internetsiz ortamda saniyeler içinde arama yapabilirsiniz.
- **Karanlık Mod (Dark Theme):** Gece ve uzun çalışma saatleri için optimize edilmiş HackTricks teması.
- **Otomatik Güncelleme (Taze Kalma Garantisi):** GitHub Actions sayesinde her 15 günde bir veya tek tuşa basıldığında HackTricks'ten yeni eklenen teknikleri çekerek otomatik yeni APK derler.

---

## 📁 Proje Mimarisi

```text
├── .github/workflows/
│   └── build-apk.yml          # GitHub Actions: Otomatik APK derleme ve Release oluşturma
├── android/                   # Hafif, yerel Android WebView projesi
│   ├── app/src/main/
│   │   ├── java/.../MainActivity.kt  # WebViewAssetLoader & Güvenli yerel navigasyon
│   │   └── assets/www/        # Derlenen HTML dokümantasyonu (index.html, /en, /tr)
│   └── gradlew                # Gradle derleme wrapper'ı
├── scripts/
│   ├── fetch_and_build.sh     # Upstream'den master & tr çekip mdBook derleyen script
│   └── serve_preview.py       # Bilgisayarda tarayıcı üzerinden önizleme sunucusu
└── bin/                       # mdbook & mdbook-tabs binary araçları
```

---

## 🛠️ Nasıl Kullanılır?

### Yöntem A: GitHub Actions ile Otomatik APK Çıkartma (Tavsiye Edilen)
En kolayıdır; bilgisayarınızda Android SDK kurmanıza gerek kalmaz:

1. Bu repoyu kendi GitHub hesabınıza push edin:
   ```bash
   git init
   git add .
   git commit -m "feat: HackTricks offline android setup"
   git remote add origin https://github.com/<kullanici-adiniz>/hacktricks-offline.git
   git push -u origin main
   ```
2. GitHub reponuzda **Actions** sekmesine gidin.
3. **Build HackTricks Offline APK** iş akışını seçip **Run workflow** butonuna tıklayın.
4. Derleme bittiğinde oluşturulan güncel `HackTricks-Offline-<TARIH>.apk` dosyasını telefonunuza indirin!
5. *(Ayrıca sistem her ayın 1'inde ve 15'inde otomatik olarak çalışıp yeni APK üretir.)*

---

### Yöntem B: Yerelde Dokümanları Derleme ve Önizleme

1. **Dokümanları Çek ve Derle:**
   ```bash
   ./scripts/fetch_and_build.sh
   ```
   *(Bu script `hacktricks` reposunun `master` ve `tr` dallarını sığ klon ile çeker ve mdBook ile HTML'e derler.)*

2. **Tarayıcıda Test Et (Önizleme):**
   ```bash
   ./scripts/serve_preview.py
   ```
   Ardından tarayıcınızdan `http://localhost:8080` adresine giderek mobil görünümü ve aramayı test edebilirsiniz.
