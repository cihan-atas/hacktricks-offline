import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/content_service.dart';
import '../services/app_state.dart';
import '../services/tts_service.dart';
import '../services/ai_service.dart';
import '../services/command_service.dart';
import '../theme/app_theme.dart';
import '../widgets/code_block_builder.dart';
import 'ai_setup_screen.dart';
import 'model_picker_sheet.dart';
import 'search_screen.dart';
import 'command_generator_screen.dart';
import 'scratchpad_screen.dart';
import 'bookmarks_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ContentService _contentService = ContentService();
  final AppState _appState = AppState();
  final TtsService _tts = TtsService();
  final AiService _ai = AiService();
  final CommandService _commands = CommandService();

  @override
  void initState() {
    super.initState();
    _ai.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _ai.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  void _showSavedChatsSheet(BuildContext context, bool isTr) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _SavedChatsViewerModal(isTr: isTr),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_contentService, _appState, _tts, _ai, _commands]),
      builder: (context, _) {
        final isTr = _contentService.currentLanguage == 'tr';
        final activeKey = _ai.activeKey;

        return Scaffold(
          backgroundColor: AppTheme.bgDark,
          appBar: AppBar(
            title: Row(
              children: [
                const Icon(Icons.settings, color: AppTheme.toolsAmber, size: 22),
                const SizedBox(width: 8),
                Text(isTr ? 'Ayarlar ve Cephanelik Merkezi' : 'Settings & Vault Hub'),
              ],
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ==========================================
              // 1. AI ENTEGRASYONU VE ANAHTAR DURUMU
              // ==========================================
              _buildSectionHeader(
                isTr ? 'AI GÜVENLİK ASİSTANI YAPILANDIRMASI' : 'AI SECURITY ASSISTANT CONFIG',
                Icons.auto_awesome,
                AppTheme.blueTeam,
              ),
              const SizedBox(height: 8),
              Card(
                color: AppTheme.bgCard,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppTheme.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (_ai.isConfigured ? AppTheme.blueTeam : AppTheme.textMuted).withAlpha(25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _ai.isConfigured ? Icons.check_circle : Icons.warning_amber_rounded,
                              color: _ai.isConfigured ? AppTheme.blueTeam : AppTheme.textMuted,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _ai.isConfigured
                                      ? (isTr ? 'AI Servisi Aktif' : 'AI Service Active')
                                      : (isTr ? 'AI Yapılandırılmadı' : 'AI Not Configured'),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _ai.isConfigured
                                      ? '${activeKey?.provider.label} · ${activeKey?.activeModel}'
                                      : (isTr
                                          ? 'İsteğe bağlı Gemini, Groq veya OpenRouter anahtarı ekleyin'
                                          : 'Optional Gemini, Groq or OpenRouter API key'),
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.blueTeam,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.vpn_key, size: 16),
                              label: Text(
                                isTr ? 'Anahtar Yöneticisi' : 'Key Manager',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const AiSetupScreen()),
                                );
                              },
                            ),
                          ),
                          if (_ai.isConfigured && activeKey != null) ...[
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.blueTeam,
                                side: const BorderSide(color: AppTheme.blueTeam),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.smart_toy_outlined, size: 16),
                              label: Text(isTr ? 'Model Seç' : 'Pick Model'),
                              onPressed: () async {
                                await showModelPickerSheet(context, keyObj: activeKey);
                                if (mounted) setState(() {});
                              },
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ==========================================
              // 2. KAYITLI AI SOHBETLERİ
              // ==========================================
              _buildSectionHeader(
                isTr ? 'KAYITLI AI SOHBETLERİ' : 'SAVED AI CHATS & QA',
                Icons.bookmark,
                AppTheme.toolsAmber,
              ),
              const SizedBox(height: 8),
              Card(
                color: AppTheme.bgCard,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppTheme.border),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.toolsAmber.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.history, color: AppTheme.toolsAmber, size: 20),
                  ),
                  title: Text(
                    isTr ? 'Soru-Cevap Geçmişi' : 'Q&A History',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                  ),
                  subtitle: Text(
                    _ai.savedChats.isEmpty
                        ? (isTr ? 'Henüz kaydedilmiş sohbet yok' : 'No saved chats yet')
                        : (isTr
                            ? '${_ai.savedChats.length} adet kayıtlı analiz ve taktiksel soru'
                            : '${_ai.savedChats.length} saved analyses and questions'),
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                  onTap: () => _showSavedChatsSheet(context, isTr),
                ),
              ),
              const SizedBox(height: 20),

              // ==========================================
              // 3. HIZLI ARAMA VE ETKİLEŞİMLİ ARAÇLAR
              // ==========================================
              _buildSectionHeader(
                isTr ? 'ARAMA VE ETKİLEŞİMLİ ARAÇLAR' : 'SEARCH & INTERACTIVE TOOLS',
                Icons.explore,
                AppTheme.sysAdmin,
              ),
              const SizedBox(height: 8),
              Card(
                color: AppTheme.bgCard,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.search, color: AppTheme.toolsAmber),
                      title: Text(
                        isTr ? 'Genel İçerik ve Doküman Arama' : 'Global Content Search',
                        style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        isTr
                            ? 'Tüm makaleleri, araçları ve sızma testi modüllerini anında filtreleyin'
                            : 'Search all articles, pentest modules, and techniques',
                        style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SearchScreen()),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.tune, color: AppTheme.redTeam),
                      title: Text(
                        isTr ? 'İnteraktif Komut Oluşturucu' : 'Command Generator & Arsenal',
                        style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        isTr
                            ? '17.100+ komutu hedef IP ve port parametreleriyle canlı derleyin'
                            : 'Compile 17,100+ commands customized with target context',
                        style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CommandGeneratorScreen()),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.shield_outlined, color: AppTheme.toolsAmber),
                      title: Text(
                        isTr ? '⚔️ Ganimet ve Karalama Defteri (Loot Manager)' : '⚔️ Loot & Scratchpad Manager',
                        style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        isTr
                            ? 'Hedef IP, kullanıcı, parola ve hashleri yerel saklayın; komut motoruna aktarın'
                            : 'Store target IPs, creds, and hashes; push to command engine',
                        style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ScratchpadScreen()),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.bookmark_outline, color: AppTheme.blueTeam),
                      title: Text(
                        isTr ? 'Kayıtlı Yer İmleri & Favoriler' : 'Saved Bookmarks & Favorites',
                        style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        isTr
                            ? '${_appState.bookmarkedCount} adet kaydedilmiş önemli makale ve not'
                            : '${_appState.bookmarkedCount} saved articles and notes',
                        style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const BookmarksScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ==========================================
              // 4. ÇEVRİMD IŞI CEPHANELİK VERİTABANI
              // ==========================================
              _buildSectionHeader(
                isTr ? 'ÇEVRİMD IŞI CEPHANELİK VERİTABANI' : 'OFFLINE VAULT DATABASE',
                Icons.storage,
                AppTheme.redTeam,
              ),
              const SizedBox(height: 8),
              Card(
                color: AppTheme.bgCard,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppTheme.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem('2.939+', isTr ? 'Doküman' : 'Articles', Icons.description, AppTheme.blueTeam),
                          _buildStatItem(
                            '${_commands.commands.isNotEmpty ? _commands.commands.length : 17100}+',
                            isTr ? 'Komut' : 'Commands',
                            Icons.terminal,
                            AppTheme.redTeam,
                          ),
                          _buildStatItem('%100', isTr ? 'Çevrimdışı' : 'Offline', Icons.wifi_off, AppTheme.sysAdmin),
                          _buildStatItem('TR & EN', isTr ? 'Çift Dil' : 'Dual Lang', Icons.translate, AppTheme.toolsAmber),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 10),
                      Text(
                        isTr
                            ? 'Tüm içerikler cihazınızda yerel olarak depolanır. İnternet bağlantısı olmadan sahadaki veya laboratuvardaki tüm sızma testi dokümantasyonuna ve komut cephaneliğine erişebilirsiniz.'
                            : 'All content is stored locally on your device. Access all penetration testing documentation and command arsenal offline in the field.',
                        style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted, height: 1.4),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ==========================================
              // 5. DİL & BÖLGE SEÇİMİ
              // ==========================================
              _buildSectionHeader(
                isTr ? 'DİL & BÖLGE' : 'LANGUAGE & REGION',
                Icons.language,
                AppTheme.toolsAmber,
              ),
              const SizedBox(height: 8),
              Card(
                color: AppTheme.bgCard,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppTheme.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildLanguageTile(
                        title: 'Türkçe Dokümantasyon',
                        subtitle: 'Topluluk Türkçe çeviri arşivi (tr branch + Cloud TR)',
                        langCode: 'tr',
                        flag: '🇹🇷',
                        isSelected: isTr,
                      ),
                      const Divider(color: AppTheme.border, height: 24),
                      _buildLanguageTile(
                        title: 'English Documentation',
                        subtitle: 'Full & original database (master branch + Cloud EN)',
                        langCode: 'en',
                        flag: '🇬🇧',
                        isSelected: !isTr,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ==========================================
              // 6. SESLİ OKUMA (TTS) YAPILANDIRMASI
              // ==========================================
              _buildSectionHeader(
                isTr ? 'SESLİ OKUMA (TTS) YAPILANDIRMASI' : 'TEXT-TO-SPEECH (TTS)',
                Icons.record_voice_over,
                AppTheme.blueTeam,
              ),
              const SizedBox(height: 8),
              Card(
                color: AppTheme.bgCard,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppTheme.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.spatial_audio_off, color: AppTheme.blueTeam, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            isTr ? 'Spiker Profili' : 'Voice Profile',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13.5),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: TtsProfile.values.map((prof) {
                          final isSelected = _tts.profile == prof;
                          return ChoiceChip(
                            label: Text(prof.label.split(' ').first),
                            selected: isSelected,
                            onSelected: (_) => _tts.setProfile(prof),
                            selectedColor: AppTheme.blueTeam.withAlpha(40),
                            labelStyle: TextStyle(
                              color: isSelected ? AppTheme.blueTeam : AppTheme.textMuted,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                            side: BorderSide(
                              color: isSelected ? AppTheme.blueTeam : AppTheme.border,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${isTr ? 'Okuma Hızı' : 'Speech Rate'}: ${_tts.speechRate.toStringAsFixed(2)}x',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                      Slider(
                        value: _tts.speechRate,
                        min: 0.5,
                        max: 1.5,
                        divisions: 10,
                        activeColor: AppTheme.blueTeam,
                        inactiveColor: AppTheme.border,
                        onChanged: (val) => _tts.setSpeechRate(val),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ==========================================
              // 7. VERİ VE İLERLEME YÖNETİMİ
              // ==========================================
              _buildSectionHeader(
                isTr ? 'VERİ VE İLERLEME YÖNETİMİ' : 'DATA & PROGRESS MANAGEMENT',
                Icons.delete_sweep,
                AppTheme.toolsAmber,
              ),
              const SizedBox(height: 8),
              Card(
                color: AppTheme.bgCard,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.check_circle_outline, color: AppTheme.sysAdmin),
                      title: Text(
                        isTr ? 'Okuma Durumu Özeti' : 'Reading Progress Summary',
                        style: const TextStyle(color: Colors.white, fontSize: 13.5),
                      ),
                      subtitle: Text(
                        isTr
                            ? '${_appState.readCount} makale tamamlandı · ${_appState.bookmarkedCount} yer imi'
                            : '${_appState.readCount} articles completed · ${_appState.bookmarkedCount} bookmarks',
                        style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.restart_alt, color: AppTheme.redTeam),
                      title: Text(
                        isTr ? 'Tüm Okuma İlerlemesini Sıfırla' : 'Reset All Reading Progress',
                        style: const TextStyle(color: AppTheme.redTeam, fontSize: 13.5, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        isTr
                            ? 'Bölüm okundu tiklerini, son kalınan yerleri ve yer imlerini temizler'
                            : 'Clears section checkmarks, last read positions, and bookmarks',
                        style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                      ),
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: AppTheme.bgCard,
                            title: Text(isTr ? 'İlerleme Sıfırlansın mı?' : 'Reset Progress?'),
                            content: Text(
                              isTr
                                  ? 'Tüm makale okuma kayıtları, bölüm tikleri ve yer imleriniz silinecektir. Bu işlem geri alınamaz.'
                                  : 'All article reading history, section checks, and bookmarks will be cleared. This cannot be undone.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text(isTr ? 'İptal' : 'Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: Text(isTr ? 'Sıfırla' : 'Reset', style: const TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await _appState.resetProgress();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isTr ? 'İlerleme başarıyla sıfırlandı.' : 'Progress reset successfully.'),
                                backgroundColor: AppTheme.bgCard,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // ==========================================
              // 8. UYGULAMA BİLGİSİ
              // ==========================================
              Center(
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/logo.png',
                          width: 22,
                          height: 22,
                          errorBuilder: (_, __, ___) => const Icon(Icons.security, size: 20, color: AppTheme.redTeam),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'HackTricks Vault v2.0.0',
                          style: TextStyle(color: AppTheme.textPrimary, fontSize: 13.5, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isTr
                          ? '100% Çevrimdışı Evrensel Siber Güvenlik Platformu'
                          : '100% Offline Universal Cyber Security Platform',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
        ),
      ],
    );
  }

  Widget _buildLanguageTile({
    required String title,
    required String subtitle,
    required String langCode,
    required String flag,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => _contentService.switchLanguage(langCode),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isSelected ? AppTheme.redTeam : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppTheme.redTeam, size: 20)
            else
              const Icon(Icons.circle_outlined, color: AppTheme.border, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Kayıtlı AI Sohbetleri ve Soru-Cevap Geçmişi Görüntüleyici Modalı
class _SavedChatsViewerModal extends StatefulWidget {
  final bool isTr;

  const _SavedChatsViewerModal({required this.isTr});

  @override
  State<_SavedChatsViewerModal> createState() => _SavedChatsViewerModalState();
}

class _SavedChatsViewerModalState extends State<_SavedChatsViewerModal> {
  final AiService _ai = AiService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  SavedAiChat? _viewingChat;

  @override
  void initState() {
    super.initState();
    _ai.addListener(_onAiChanged);
  }

  @override
  void dispose() {
    _ai.removeListener(_onAiChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onAiChanged() {
    if (mounted) {
      if (_viewingChat != null) {
        final updated = _ai.savedChats.where((c) => c.id == _viewingChat!.id).firstOrNull;
        _viewingChat = updated;
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final allChats = _ai.savedChats;

    final filteredChats = allChats.where((chat) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.trim().toLowerCase();
      final inTitle = chat.articleTitle.toLowerCase().contains(q);
      final inMod = chat.moduleTitle.toLowerCase().contains(q);
      final inPrompt = chat.prompt.toLowerCase().contains(q);
      final inMsgs = chat.messages.any((m) => m.text.toLowerCase().contains(q));
      return inTitle || inMod || inPrompt || inMsgs;
    }).toList();

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: _viewingChat != null
            ? _buildChatDetail(_viewingChat!)
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.toolsAmber.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.history, color: AppTheme.toolsAmber, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.isTr ? 'Kayıtlı AI Soru-Cevap Geçmişi' : 'Saved AI Q&A History',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            Text(
                              widget.isTr
                                  ? '${allChats.length} kayıtlı analiz ve taktiksel soru'
                                  : '${allChats.length} saved analyses and questions',
                              style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                      if (allChats.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppTheme.redTeam, size: 20),
                          tooltip: widget.isTr ? 'Tümünü Temizle' : 'Clear All',
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: AppTheme.bgCard,
                                title: Text(widget.isTr ? 'Tümü Silinsin mi?' : 'Delete All?'),
                                content: Text(
                                  widget.isTr
                                      ? 'Tüm kayıtlı AI soru-cevap geçmişi silinecektir.'
                                      : 'All saved AI Q&A history will be deleted.',
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(widget.isTr ? 'İptal' : 'Cancel')),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: Text(widget.isTr ? 'Sil' : 'Delete', style: const TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await _ai.clearAllChats();
                            }
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Arama
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: widget.isTr ? 'Sohbet veya soru ara...' : 'Search Q&A...',
                      hintStyle: const TextStyle(fontSize: 12.5, color: AppTheme.textMuted),
                      prefixIcon: const Icon(Icons.search, size: 18, color: AppTheme.textMuted),
                      filled: true,
                      fillColor: AppTheme.bgDark,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppTheme.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppTheme.border),
                      ),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  Flexible(
                    child: filteredChats.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Text(
                                widget.isTr
                                    ? 'Kayıtlı analiz veya soru bulunamadı'
                                    : 'No saved analyses or questions found',
                                style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: filteredChats.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.border),
                            itemBuilder: (ctx, idx) {
                              final chat = filteredChats[idx];
                              return ListTile(
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                leading: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.toolsAmber.withAlpha(25),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.question_answer_outlined, color: AppTheme.toolsAmber, size: 16),
                                ),
                                title: Text(
                                  chat.prompt.isNotEmpty ? chat.prompt : chat.articleTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  '${chat.articleTitle} · ${chat.messages.length} mesaj',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.close, size: 16, color: AppTheme.textMuted),
                                  onPressed: () => _ai.deleteChat(chat.id),
                                ),
                                onTap: () {
                                  setState(() {
                                    _viewingChat = chat;
                                  });
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildChatDetail(SavedAiChat chat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              onPressed: () {
                setState(() {
                  _viewingChat = null;
                });
              },
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat.prompt.isNotEmpty ? chat.prompt : chat.articleTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    chat.articleTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.toolsAmber, fontSize: 11),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy, size: 18, color: AppTheme.blueTeam),
              tooltip: widget.isTr ? 'Kopyala' : 'Copy',
              onPressed: () {
                final fullText = chat.messages.map((m) => '${m.isUser ? "Soru" : "Cevap"}:\n${m.text}').join('\n\n---\n\n');
                Clipboard.setData(ClipboardData(text: fullText));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(widget.isTr ? 'Sohbet panoya kopyalandı 📋' : 'Copied to clipboard'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
          ],
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: chat.messages.length,
            itemBuilder: (ctx, idx) {
              final msg = chat.messages[idx];
              final isUser = msg.isUser;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isUser ? const Color(0xFF1E2638) : const Color(0xFF141A26),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isUser ? AppTheme.blueTeam.withAlpha(60) : AppTheme.border,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isUser ? Icons.person : Icons.smart_toy,
                          size: 15,
                          color: isUser ? AppTheme.blueTeam : AppTheme.toolsAmber,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isUser ? (widget.isTr ? 'Sorunuz' : 'User') : (widget.isTr ? 'AI Asistanı' : 'AI Assistant'),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: isUser ? AppTheme.blueTeam : AppTheme.toolsAmber,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    MarkdownBody(
                      data: msg.text,
                      builders: {
                        'code': CodeElementBuilder(context),
                      },
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(fontSize: 13, color: Colors.white, height: 1.5),
                        code: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Color(0xFFFACC15)),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
