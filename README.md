# 🛡️ HackTricks Vault — Evrensel Çevrimdışı Siber Güvenlik ve Komut Cephaneliği Platformu

[![Release](https://img.shields.io/github/v/release/cihan-atas/hacktricks-offline?style=for-the-badge&color=ef4444)](https://github.com/cihan-atas/hacktricks-offline/releases)
[![Build Status](https://img.shields.io/github/actions/workflow/status/cihan-atas/hacktricks-offline/build-apk.yml?style=for-the-badge)](https://github.com/cihan-atas/hacktricks-offline/actions)
[![Offline](https://img.shields.io/badge/OFFLINE-%25100_Yerel-10b981?style=for-the-badge)](https://github.com/cihan-atas/hacktricks-offline)
[![Languages](https://img.shields.io/badge/DİL-TR_%26_EN-3b82f6?style=for-the-badge)](https://github.com/cihan-atas/hacktricks-offline)
[![Commands](https://img.shields.io/badge/ARSENAL-17.100%2B_Komut-f59e0b?style=for-the-badge)](https://github.com/cihan-atas/hacktricks-offline)

**HackTricks Vault**, resmi **HackTricks** ve **HackTricks Cloud** siber güvenlik bilgi tabanlarını (Web, Network, Windows, Linux, Active Directory, AWS, Azure, GCP, Kubernetes, CI/CD) tek bir çatıda birleştiren; **2.939+ tam metin dokümanı** ve **17.127+ canlı parametreli operasyonel pentest komutunu** hiçbir internet bağlantısına ihtiyaç duymadan mobil cihazınızda (Android) ve web tarayıcınızda kullanmanızı sağlayan nihai siber güvenlik platformudur.

---

## ⚡ Öne Çıkan Gelişmiş Yetenekler

### 1. 🎯 Canlı Komut Motoru & Arsenal (17.127+ Komut)
- **Dinamik Parametrelendirme:** Hedef IP (`target_ip`), Port (`target_port`), Alan Adı (`domain`), Dinleyici IP (`lhost`), Port (`lport`), Parola ve Wordlist değişkenlerini tek merkezden girin; 17.100'den fazla komut tek tıkla kopyalanmaya hazır hale gelsin.
- **🛠️ Akıllı Araç Kataloğu (100+ Araç):** `nmap`, `ffuf`, `sqlmap`, `impacket`, `netexec`, `mimikatz`, `aws`, `az`, `gcloud`, `kubectl`, `docker` gibi onlarca güvenlik aracını frekansa göre listeleyen, tek tıkla filtrelenebilir açılır araç seçici modalı.
- **Dokümanda Oku Entegrasyonu:** Komut kartındaki *"Dokümanda Oku"* butonuyla ilgili tekniğin detaylı HackTricks makalesine anında geçiş yapın.

### 2. 📚 Devasa Çevrimdışı Dokümantasyon (2.939 TR + 2.939 EN)
- **HackTricks Main + HackTricks Cloud Entegrasyonu:** AWS, Azure, Google Cloud, Kubernetes ve CI/CD güvenlik modüllerinin tamamı çevrimdışı arşivdedir.
- **Temizlenmiş Markdown Mimarisi:** Dokümanlardaki rahatsız edici eğitim/sponsor bannerları (`{{#include ...}}`), dipnot bağlantıları (`<sup>[[1]]</sup>`) ve bozuk HTML etiketleri arındırılmış, saf ve pürüzsüz bir okuma deneyimi sunulmuştur.
- **İçindekiler & Bölüm İlerlemesi (TOC Progress):** Uzun dokümanlarda her bölümün yanında interaktif tamamlandı (✓) kutucukları yer alır.
- **Otomatik Kaldığı Yerden Devam Etme:** Bir dokümandan çıktığınızda son kaldığınız bölüm hafızaya alınır; tekrar açtığınızda otomatik olarak oraya kaydırılır.

### 3. ⚔️ Ganimet Defteri (Loot Manager & Scratchpad)
- Sahada veya CTF sırasında elde edilen hedef IP'leri, kimlik bilgilerini, NTLM/Kerberos hash'lerini ve hızlı operasyonel notları güvenle saklayın.
- Kaydedilen ganimetleri tek tıkla canlı komut motorunun hedef parametrelerine aktarın.

### 4. 🔊 Gelişmiş Sesli Okuma Motoru (Floating TTS)
- Ekranın altında sabit kalan mini ses oynatıcı çubuğu (Play, Pause, Stop, Hız Ayarı).
- **4 Uzman Ses Profili:** SOC Analisti (sakin), Eğitmen (dengeli), Akademisyen, Kırmızı Takım (tempolu).
- Kod bloklarını ve sembolleri filtreleyerek akıcı dinleme deneyimi sunar.

### 5. ✨ İsteğe Bağlı AI Siber Güvenlik Asistanı
- Tamamen yerel ve internetsiz çalışma prensibine ek olarak; kullanıcı Google Gemini (`AIza...`), Groq Cloud (`gsk_...`) veya OpenRouter (`sk-or-...`) anahtarı eklediğinde anında devreye girer.
- Makale açıklama, saldırı analizi, Sigma savunma kuralları ve serbest soru-cevap geçmişi saklama imkanı.

### 6. ⚙️ Cephanelik ve Ayarlar Merkezi
- AI durumu, model seçici, kayıtlı soru-cevap arşivi, hızlı arama araçları, ses profili ayarları ve çevrimdışı veritabanı istatistikleri tek bir ekranda toplanmıştır.

---

## 📂 Proje Dizin Yapısı

```
hacktricks-wiki/
├── app/                           # Flutter mobil ve web uygulama kaynak kodları
│   ├── assets/data/               # Derlenmiş çevrimdışı JSON veritabanları (tr, en, stats, catalog)
│   ├── lib/                       # Ekranlar, servisler, temalar ve bileşenler
│   └── android/                   # Android release yapılandırması ve release keystore
├── dist/                          # Derlenen son sürüm çıktıları (HackTricks_Vault.apk, web/)
├── sources/                       # Upstream HackTricks ve HackTricks-Cloud kaynak repoları
│   ├── hacktricks-en/             # HackTricks İngilizce kaynakları
│   ├── hacktricks-tr/             # HackTricks Türkçe çeviri kaynakları
│   ├── hacktricks-cloud/          # HackTricks Cloud İngilizce kaynakları
│   └── hacktricks-cloud-tr/       # HackTricks Cloud Türkçe kaynakları
├── scripts/                       # İçerik çıkarma, indeksleme, komut ve release scriptleri
├── trigger_release.sh             # Manuel ve yerel release tetikleme betiği
└── .github/workflows/             # Otomatik CI/CD derleme iş akışı (build-apk.yml)
```

---

## 🛠️ Projede Kullanılan Tüm Scriptler ve Kullanımları

Projede içerik çıkarma, veri tabanı oluşturma, test etme ve sürüm yayınlama süreçlerini otomatikleştiren özel Python ve Bash scriptleri bulunmaktadır:

### 1. `trigger_release.sh` — Manuel Release & Derleme Tetikleyici
Hem yerel makinede hem de GitHub Actions üzerinde anında yeni sürüm/APK derlemesi başlatmak için kullanılır.

- **GitHub Actions Üzerinde Bulut Derlemesi Tetiklemek İçin:**
  ```bash
  ./trigger_release.sh
  ```
  *Ne yapar:* GitHub CLI üzerinden `Build HackTricks Vault APK` workflow'unu anında başlatır. Upstream repolardan en güncel verileri çeker, APK'yı derler, sürüm notunu oluşturur ve eski release'leri temizleyerek son sürümü yayınlar.

- **Kendi Bilgisayarınızda Yerel Olarak Derleyip Release'e Yüklemek İçin:**
  ```bash
  ./trigger_release.sh --local
  ```
  *Ne yapar:* GitHub kotası harcamadan makinenizde içeriği derler, `flutter build apk` çalıştırır ve üretilen `HackTricks_Vault.apk` dosyasını doğrudan GitHub Release'e yükler (`clobber`).

---

### 2. `scripts/build_hacktricks_content.py` — Evrensel İçerik Çıkarıcı & İndeksleyici
Ana HackTricks ve HackTricks Cloud kaynaklarını okuyup Flutter uygulaması için optimize edilmiş JSON formatına dönüştürür.

- **Kullanım:**
  ```bash
  python3 scripts/build_hacktricks_content.py
  ```
- **Ne Yapar:**
  - `sources/` altındaki EN, TR, Cloud EN ve Cloud TR `SUMMARY.md` dosyalarını tarar.
  - Markdown dosyalarındaki tüm reklam bannerlarını (`{{#include ...banners...}}`), sponsor linklerini ve 25.000+ dipnot (`<sup>`) HTML etiketini temizler.
  - Bulut dokümanlarını akıllıca analiz edip AWS, Azure, GCP, K8s, CI/CD ve Multi-Cloud kategorilerine dağıtır.
  - Sonuçları `app/assets/data/en/` ve `app/assets/data/tr/` dizinlerine (`hierarchy.json`, `articles.json`, `search_index.json`, `stats.json`) kaydeder.

---

### 3. `scripts/extract_hacktricks_commands.py` — Evrensel Komut & Cephanelik Çıkarıcı
2.939 dokümanın içindeki tüm kod bloklarını tarayarak operasyonel pentest komutlarını çıkarır ve parametrelendirir.

- **Kullanım:**
  ```bash
  python3 scripts/extract_hacktricks_commands.py
  ```
- **Ne Yapar:**
  - ````bash```` kod bloklarını regex ile analiz eder; sahte komutları ve düz metinleri eler.
  - Tespit edilen araçları (`nmap`, `mimikatz`, `ffuf`, `aws`, `kubectl` vb.) 8 operasyonel kategoriye ve platforma (Linux CLI, PowerShell, Windows CMD) ayırır.
  - IP adreslerini `{{target_ip}}`, alan adlarını `{{domain}}`, portları `{{target_port}}` gibi canlı değişkenlere dönüştürür.
  - Çıktıyı `app/assets/data/commands_catalog.json` (17.127+ komut) dosyasına yazar.

---

### 4. `scripts/generate_release_notes.py` — Akıllı Sürüm Notu & Changelog Motoru
GitHub Release açıklaması için detaylı, dinamik bir Markdown değişiklik günlüğü (`RELEASE_NOTES.md`) üretir.

- **Kullanım:**
  ```bash
  python3 scripts/generate_release_notes.py
  ```
- **Ne Yapar:**
  - Bir önceki derleme ile mevcut derleme arasındaki dosya farklarını (diff) tespit eder.
  - Yeni eklenen / güncellenen `.md` dokümanlarını listeler.
  - Komut kataloğundaki öne çıkan aktif komutları kod bloğu olarak döker.
  - Upstream repolardan (EN, TR, Cloud) çekilen son commit başlıklarını ve güncel doküman/komut sayılarını döküme ekler.

---

### 5. `scripts/serve_web.py` — Yerel Web Sunucusu
Derlenmiş Flutter Web sürümünü (`dist/web`) tarayıcınızda test etmek için hafif bir Python HTTP sunucusu başlatır.

- **Kullanım:**
  ```bash
  python3 scripts/serve_web.py
  ```
- **Erişim:** Tarayıcınızdan `http://localhost:8080` adresine gidin.

---

### 6. `scripts/serve_preview.py` — Canlı Önizleme Yardımcısı
Geliştirme aşamasında dokümanların ve web arayüzünün canlı test edilmesini sağlar.

- **Kullanım:**
  ```bash
  python3 scripts/serve_preview.py
  ```

---

### 7. `scripts/fetch_and_build.sh` — Kaynakları Sıfırdan İndirme ve Eşleme
Upstream HackTricks ve HackTricks Cloud repolarını yerel ortama ilk kez klonlamak veya en son sürüme `git fetch` etmek için kullanılan yardımcı kabuk betiğidir.

- **Kullanım:**
  ```bash
  chmod +x scripts/fetch_and_build.sh
  ./scripts/fetch_and_build.sh
  ```

---

## 📱 Yerel Olarak APK Derleme ve Yükleme

### 1. Flutter Bağımlılıkları ve Veri Derleme
```bash
# 1. İçerik ve komut veritabanlarını üretin:
python3 scripts/build_hacktricks_content.py
python3 scripts/extract_hacktricks_commands.py

# 2. Android Release APK derleyin:
cd app
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH
flutter pub get
flutter build apk --release --no-tree-shake-icons
cd ..
```

### 2. Telefona Yükleme (ADB)
Telefonunuz USB hata ayıklama moduyla bilgisayara bağlıyken:
```bash
adb install -r dist/HackTricks_Vault.apk
```

---

## 🌐 Sürekli Entegrasyon & Otomatik Yayınlama (CI/CD)

Proje deposundaki [`.github/workflows/build-apk.yml`](.github/workflows/build-apk.yml) iş akışı:
1. **Zamanlanmış Görev (Cron):** Her ayın **1'inde ve 15'inde** gece 00:00'da otomatik çalışır.
2. **Upstream Güncelleme:** HackTricks ve HackTricks Cloud repolarındaki en taze commit'leri çeker.
3. **Temiz Derleme:** Banner ve dipnot temizliğini yapar, komutları çıkarır ve dinamik changelog üretir.
4. **Temizleme Politikası:** Yeni release yayınlandıktan sonra önceki tüm eski sürümleri ve etiketleri otomatik siler; Releases sekmesinde daima **sadece en son sürüm** kalır.
5. **İndirme Bağlantısı:** En güncel release dosyasına her zaman [GitHub Releases](https://github.com/cihan-atas/hacktricks-offline/releases) sayfasından ulaşabilirsiniz.

---

## ⚖️ Lisans ve Yasal Uyarı

Bu uygulama yalnızca eğitim, laboratuvar araştırması ve yetkili sızma testi (penetration testing) senaryoları için geliştirilmiştir. Yetkisiz sistemlere karşı gerçekleştirilecek eylemler yasal sorumluluk doğurur. Orijinal içerikler [HackTricks](https://book.hacktricks.xyz/) ve [HackTricks Cloud](https://cloud.hacktricks.wiki/) topluluğuna aittir.
