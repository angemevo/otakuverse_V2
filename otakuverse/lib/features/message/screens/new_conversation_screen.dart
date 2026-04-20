import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/utils/helpers.dart';
import 'package:otakuverse/core/widgets/cached_image.dart';
import '../services/message_service.dart';
import '../models/conversation_model.dart';
import 'chat_screen.dart';

class NewConversationScreen extends StatefulWidget {
  const NewConversationScreen({super.key});

  @override
  State<NewConversationScreen> createState() =>
      _NewConversationScreenState();
}

class _NewConversationScreenState
    extends State<NewConversationScreen> {
  final _supabase   = Supabase.instance.client;
  final _service    = MessageService();
  final _searchCtrl = TextEditingController();

  String get _uid => _supabase.auth.currentUser!.id;

  List<Map<String, dynamic>> _results      = [];
  bool                       _isSearching  = false;
  bool                       _isOpening    = false;
  String?                    _openingId;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ─── Recherche ───────────────────────────────────────────────────

  Future<void> _search(String query) async {
    final q = query.trim();
    if (q.isEmpty) { setState(() => _results = []); return; }

    setState(() => _isSearching = true);
    try {
      final data = await _supabase
          .from('profiles')
          .select('user_id, username, display_name, avatar_url, bio')
          .or('username.ilike.%$q%,display_name.ilike.%$q%')
          .neq('user_id', _uid)
          .limit(20);
      if (mounted) setState(() {
        _results = (data as List).cast<Map<String, dynamic>>();
      });
    } catch (e) {
      debugPrint('❌ search: $e');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  // ─── Ouvrir / créer conversation ─────────────────────────────────

  Future<void> _openConversation(
      Map<String, dynamic> user) async {
    final userId = user['user_id'] as String;
    setState(() { _isOpening = true; _openingId = userId; });

    try {
      final convId =
          await _service.getOrCreateConversation(userId);

      if (!mounted) return;
      if (convId == null) {
        // ✅ Helpers remplace ScaffoldMessenger avec couleurs hardcodées
        Helpers.showErrorSnackbar(
            'Impossible de créer la conversation');
        return;
      }

      final conv = ConversationModel(
        id:               convId,
        type:             'direct',
        otherUserId:      userId,
        otherUsername:    user['username']     as String?,
        otherDisplayName: user['display_name'] as String?,
        otherAvatarUrl:   user['avatar_url']   as String?,
      );

      Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => ChatScreen(conv: conv)));
    } catch (e, s) {
      debugPrint('❌ openConversation: $e\n$s');
      if (mounted) Helpers.showErrorSnackbar('Erreur: $e');
    } finally {
      if (mounted) setState(() { _isOpening = false; _openingId = null; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        elevation:       0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Nouveau message',
            style: GoogleFonts.poppins(
              color:      AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize:   16,
            )),
      ),
      body: Column(children: [
        _buildSearchField(),
        Expanded(child: _buildResults()),
      ]),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color:        AppColors.bgCard,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: _searchCtrl,
          autofocus:  true,
          onChanged:  _search,
          style: GoogleFonts.inter(
              color: AppColors.textPrimary, fontSize: 15),
          decoration: InputDecoration(
            hintText:  'Recherche un utilisateur...',
            hintStyle: GoogleFonts.inter(
                color: AppColors.textMuted, fontSize: 15),
            prefixIcon: const Icon(Icons.search,
                color: AppColors.textMuted, size: 20),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close,
                        color: AppColors.textMuted, size: 18),
                    onPressed: () {
                      _searchCtrl.clear();
                      _search('');
                    },
                  )
                : null,
            border:         InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_searchCtrl.text.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.person_search_outlined,
              color: AppColors.textMuted, size: 56),
          const SizedBox(height: 16),
          Text('Recherche par nom ou @username',
              style: GoogleFonts.inter(
                  color: AppColors.textMuted, fontSize: 14)),
        ]),
      );
    }
    if (_results.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.search_off_outlined,
              color: AppColors.textMuted, size: 48),
          const SizedBox(height: 12),
          Text('Aucun utilisateur trouvé',
              style: GoogleFonts.poppins(
                color:      AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize:   15,
              )),
          const SizedBox(height: 6),
          Text('Essaie un autre nom',
              style: GoogleFonts.inter(
                  color: AppColors.textMuted, fontSize: 13)),
        ]),
      );
    }

    return ListView.separated(
      padding:          const EdgeInsets.symmetric(vertical: 8),
      itemCount:        _results.length,
      separatorBuilder: (_, __) => const Divider(
          color: Color(0xFF1A1A1A), height: 1, indent: 76),
      itemBuilder: (_, i) {
        final user      = _results[i];
        final userId    = user['user_id'] as String;
        final isLoading = _isOpening && _openingId == userId;

        return InkWell(
          onTap: isLoading ? null : () => _openConversation(user),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
            child: Row(children: [
              CachedAvatar(
                url: user['avatar_url'] as String?,
                radius:         26,
                fallbackLetter:
                    user['display_name'] as String? ??
                    user['username']     as String? ??
                    '?',
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['display_name'] as String? ??
                          user['username']  as String,
                      style: GoogleFonts.inter(
                        color:      AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize:   15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text('@${user['username']}',
                        style: GoogleFonts.inter(
                            color:    AppColors.textMuted,
                            fontSize: 13)),
                    if (user['bio'] != null &&
                        (user['bio'] as String).isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(user['bio'] as String,
                          style: GoogleFonts.inter(
                              color:    AppColors.textMuted,
                              fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                      color: AppColors.primary, strokeWidth: 2),
                )
              else
                const Icon(Icons.chevron_right,
                    color: AppColors.textMuted, size: 20),
            ]),
          ),
        );
      },
    );
  }
}
