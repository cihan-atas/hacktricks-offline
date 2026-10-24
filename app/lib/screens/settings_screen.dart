import 'package:flutter/material.dart';
import '../services/content_service.dart';
import '../services/app_state.dart';
import '../services/tts_service.dart';
import '../services/ai_service.dart';
import '../theme/app_theme.dart';
import 'ai_setup_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_contentService, _appState, _tts, _ai]),
      builder: (context, _) {
        final isTr = _contentService.currentLanguage == 'tr';

        return Scaffold(
          backgroundColor: AppTheme.bgDark,
          appBar: AppBar(
            title: Text(isTr ? 'Ayarlar' : 'Settings'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 1. Dil Seçimi Bölümü
              _buildSectionHeader(isTr ? 'DİL & BÖLGE' : 'LANGUAGE & REGION'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildLanguageTile(
                        title: 'Türkçe Dokümantasyon',
                        subtitle: 'Topluluk Türkçe çeviri arşivi (tr branch)',
                        langCode: 'tr',
                        flag: '🇹🇷',
                        isSelected: isTr,
                      ),
                      const Divider(color: AppTheme.border, height: 24),
                      _buildLanguageTile(
                        title: 'English Documentation',
                        subtitle: 'Full & original database (master branch)',
                        langCode: 'en',
                        flag: '🇬🇧',
                        isSelected: !isTr,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 2. AI Siber Güvenlik Asistanı
              _buildSectionHeader(isTr ? 'YAPAY ZEKA ASİSTANI (AI)' : 'AI ASSISTANT'),
              Card(
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.redTeam.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.smart_toy, color: AppTheme.redTeam),
                  ),
                  title: Text(
                    isTr ? 'AI Sağlayıcı & API Anahtarı' : 'AI Provider & API Key',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    _ai.hasKeys
                        ? (_ai.activeKey != null
                            ? '${_ai.activeKey!.provider.label} (${_ai.activeKey!.activeModel})'
                            : 'Aktif')
                        : (isTr ? 'API anahtarı girilmedi (Opsiyonel)' : 'No API key (Optional)'),
                    style: TextStyle(
                      color: _ai.hasKeys ? AppTheme.sysAdmin : AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AiSetupScreen()),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // 3. TTS Sesli Okuma Ayarları
              _buildSectionHeader(isTr ? 'SESLİ OKUMA (TTS)' : 'TEXT-TO-SPEECH (TTS)'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.record_voice_over, color: AppTheme.blueTeam, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            isTr ? 'Spiker Profili' : 'Voice Profile',
                            style: const TextStyle(fontWeight: FontWeight.bold),
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

              const SizedBox(height: 24),

              // 4. Veri ve Sıfırlama
              _buildSectionHeader(isTr ? 'VERİ YÖNETİMİ' : 'DATA MANAGEMENT'),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.delete_sweep, color: AppTheme.toolsAmber),
                  title: Text(isTr ? 'İlerlemeyi Sıfırla' : 'Reset Progress'),
                  subtitle: Text(
                    isTr ? 'Okunan konuları ve yer imlerini temizler' : 'Clear read history and bookmarks',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppTheme.bgCard,
                        title: Text(isTr ? 'Sıfırlansın mı?' : 'Reset?'),
                        content: Text(isTr
                            ? 'Tüm okuma ilerlemeniz ve yer imleriniz silinecektir.'
                            : 'All read history and bookmarks will be cleared.'),
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
                          SnackBar(content: Text(isTr ? 'İlerleme sıfırlandı.' : 'Progress reset.')),
                        );
                      }
                    }
                  },
                ),
              ),

              const SizedBox(height: 30),

              // Uygulama Bilgisi
              Center(
                child: Column(
                  children: [
                    Text(
                      'HackTricks Vault v1.0.0',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isTr ? '100% Çevrimdışı Siber Güvenlik Platformu' : '100% Offline Cyber Security Platform',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
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
