# 🛡️ HackTricks Vault — Çevrimdışı Mobil (APK) Platformu

HackTricks siber güvenlik, penetrasyon testi, privilege escalation ve exploit bilgi tabanını (2.260+ doküman) **%100 çevrimdışı (offline)** olarak mobil cihazınızda kullanmanızı sağlayan gelişmiş bir siber güvenlik çalışma ve referans platformudur.

---

## 🚀 Öne Çıkan Gelişmiş Özellikler

1. **🎨 Modern OLED Cyber Dark Mobil Tasarım:**
   - Siber güvenlik operasyonlarına uygun koyu tema, cam efekti (glassmorphism) ve neon vurgular.
   - 20 temel HackTricks kategorisi (Web Pentesting, Network Services, Windows, Linux, Binary Exploitation, AI Security, Cloud vb.).

2. **🔊 Gelişmiş Sesli Okuma Motoru (TTS — Text-to-Speech):**
   - Ekranın altından ayrılmayan yapışkan **Floating TTS Player Bar** (Oynat, Duraklat, Durdur, Hız 0.75x–1.50x).
   - **4 Özel Spiker Profili:** SOC Analisti (sakin), Eğitmen (dengeli), Akademisyen, Kırmızı Takım (hızlı tempo).
   - **Akıllı Markdown Temizleyici:** Kod bloklarını, ````bash```` etiketlerini ve işaretlemeleri atlayarak pürüzsüz dinleme sağlar.

3. **✨ İsteğe Bağlı AI Siber Güvenlik Asistanı:**
   - **Sıfır Ağ / Zero-Network:** Varsayılan olarak %100 internetsizdir.
   - Kullanıcı Google Gemini (`AIza...`), Groq Cloud (`gsk_...`) veya OpenRouter (`sk-or-...`) API anahtarı girdiğinde tek dokunuşla aktifleşir:
     - 💡 *"Bu Bölümü Basitçe Açıkla"*
     - ⚡ *"Komut & Saldırı Analizi Yap"*
     - 🛡️ *"Tespit & Savunma Kuralı Yaz (Sigma / Event ID)"*
     - 💬 *"Doküman Hakkında Serbest Soru Sor"*

4. **🌐 Çift Dil Desteği (🇹🇷 Türkçe & 🇬🇧 İngilizce):**
   - Uygulama içinden tek dokunuşla **Türkçe** çeviri arşivi veya en güncel **İngilizce** orijinal veri tabanı arasında geçiş.

5. **📈 Öğrenme ve Okuma İlerlemesi (Hero Progress Tracker):**
   - "Kaldığın Yerden Devam Et" kartı ve anlık ilerleme çubuğu (%X tamamlandı).
   - Tek dokunuşla **"Okundu Olarak İşaretle"** (✓) ve **"Yer İmi"** (🔖).
   - Dahili pentest not defteri (Scratchpad).

6. **🔍 Hızlı Çevrimdışı Arama:**
   - 2.260+ makale içinde internetsiz, anlık ve filtrelenebilir arama motoru.

---

## 🛠️ Yerelde APK Derleme

```bash
# Tek komutla tüm dokümanları tarar ve release APK'sını derler:
./build_apk.sh
```

- **Derlenen APK Konumu:** `dist/HackTricks_Vault.apk`
- **Dosya Boyutu:** ~62 MB (Hafif ve optimize)

### Telefona Yükleme
```bash
adb install -r dist/HackTricks_Vault.apk
```
veya yerel ağ üzerinden telefona indirmek için:
```bash
python3 -m http.server -d dist 8080
```
Telefon tarayıcısından `http://<BILGISAYAR_IP>:8080/HackTricks_Vault.apk` adresini açabilirsiniz.

---

## 🔄 Otomatik Güncelleme (GitHub Actions CI/CD)

- Repoda her ayın **1'inde ve 15'inde** veya **Actions -> Run workflow** tıklandığında otomatik yeni APK derlenir ve GitHub Releases bölümüne yüklenir.
