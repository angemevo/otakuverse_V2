import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/widgets/cached_image.dart';
import 'package:otakuverse/features/message/screens/new_conversation_screen.dart';
import '../controllers/message_controller.dart';
import '../models/conversation_model.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(MessageController());

    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: _AppBar(ctrl: ctrl),
      body: Column(
        children: [
          _SearchBar(ctrl: ctrl),
          Expanded(
            child: Obx(() {
              if (ctrl.isLoading.value &&
                  ctrl.conversations.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.crimsonRed),
                );
              }

              if (ctrl.filtered.isEmpty) {
                return _EmptyState(
                  hasSearch: ctrl
                      .searchQuery.value.isNotEmpty,
                );
              }

              return RefreshIndicator(
                color:           AppColors.crimsonRed,
                backgroundColor: AppColors.deepBlack,
                onRefresh: ctrl.loadConversations,
                child: ListView.separated(
                  itemCount: ctrl.filtered.length,
                  separatorBuilder: (_, __) =>
                      const Divider(
                    color:  Color(0xFF1A1A1A),
                    height: 1,
                    indent: 76,
                  ),
                  itemBuilder: (_, i) =>
                      _ConversationTile(
                    conv: ctrl.filtered[i],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.crimsonRed,
        elevation:       4,
        // ✅ Ouvrir NewConversationScreen
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const NewConversationScreen(),
          ),
        ),
        child: const Icon(
            Icons.edit_outlined,
            color: Colors.white),
      ),
    );
  }
}

// ─── APP BAR ─────────────────────────────────────────────────────────
class _AppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final MessageController ctrl;
  const _AppBar({required this.ctrl});

  @override
  Size get preferredSize =>
      const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.deepBlack,
      elevation:       0,
      leading: IconButton(
        icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.pureWhite, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Messages',
            style: GoogleFonts.poppins(
              color:      AppColors.pureWhite,
              fontWeight: FontWeight.w700,
              fontSize:   18,
            ),
          ),
          Obx(() {
            final n = ctrl.totalUnread;
            if (n == 0) return const SizedBox.shrink();
            return Text(
              '$n non lu${n > 1 ? 's' : ''}',
              style: GoogleFonts.inter(
                color:    AppColors.crimsonRed,
                fontSize: 11,
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── BARRE DE RECHERCHE ──────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final MessageController ctrl;
  const _SearchBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          16, 8, 16, 4),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color:        AppColors.darkGray,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          onChanged: (v) =>
              ctrl.searchQuery.value = v,
          style: GoogleFonts.inter(
            color:    AppColors.pureWhite,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: 'Rechercher...',
            hintStyle: GoogleFonts.inter(
              color:    AppColors.mediumGray,
              fontSize: 14,
            ),
            prefixIcon: const Icon(
              Icons.search,
              color: AppColors.mediumGray,
              size:  18,
            ),
            border:         InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
                vertical: 10),
          ),
        ),
      ),
    );
  }
}

// ─── TUILE CONVERSATION ──────────────────────────────────────────────
class _ConversationTile extends StatelessWidget {
  final ConversationModel conv;
  const _ConversationTile({required this.conv});

  @override
  Widget build(BuildContext context) {
    final hasUnread = conv.unreadCount > 0;

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(conv: conv),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // ─ Avatar ────────────────────────────────────
            CachedAvatar(
              url:           conv.displayAvatar,
              radius:        26,
              fallbackLetter: conv.displayName,
            ),
            const SizedBox(width: 12),

            // ─ Contenu ───────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  // ─ Nom + Heure ──────────────────────
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          conv.displayName,
                          style: GoogleFonts.inter(
                            color:      AppColors.pureWhite,
                            fontWeight: hasUnread
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _fmtTime(conv.lastMessageAt),
                        style: GoogleFonts.inter(
                          color: hasUnread
                              ? AppColors.crimsonRed
                              : AppColors.mediumGray,
                          fontSize:   11,
                          fontWeight: hasUnread
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),

                  // ─ Dernier message + Badge ──────────
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conv.lastMessageText ??
                              'Nouvelle conversation',
                          style: GoogleFonts.inter(
                            color: hasUnread
                                ? AppColors.pureWhite
                                : AppColors.mediumGray,
                            fontSize:   13,
                            fontWeight: hasUnread
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          constraints:
                              const BoxConstraints(
                            minWidth:  20,
                            minHeight: 20,
                          ),
                          padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 1, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.crimsonRed,
                            borderRadius:
                                BorderRadius.circular(10),
                          ),
                          child: Text(
                            conv.unreadCount > 99
                                ? '99+'
                                : '${conv.unreadCount}',
                            style: GoogleFonts.inter(
                              color:      Colors.white,
                              fontSize:   11,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtTime(DateTime? t) {
    if (t == null) return '';
    final now  = DateTime.now();
    final diff = now.difference(t);
    if (diff.inMinutes < 1)  return 'maintenant';
    if (diff.inHours   < 1)  return '${diff.inMinutes}min';
    if (diff.inDays    < 1)  return '${diff.inHours}h';
    if (diff.inDays    < 7) {
      const j = ['Lun','Mar','Mer','Jeu','Ven','Sam','Dim'];
      return j[t.weekday - 1];
    }
    return '${t.day}/${t.month}';
  }
}

// ─── EMPTY STATE ─────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool hasSearch;
  const _EmptyState({required this.hasSearch});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasSearch
                ? Icons.search_off_outlined
                : Icons.chat_bubble_outline_rounded,
            color: AppColors.mediumGray,
            size:  56,
          ),
          const SizedBox(height: 16),
          Text(
            hasSearch
                ? 'Aucun résultat'
                : 'Aucune conversation',
            style: GoogleFonts.poppins(
              color:      AppColors.pureWhite,
              fontWeight: FontWeight.w600,
              fontSize:   16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasSearch
                ? 'Essaie un autre nom'
                : 'Appuie sur ✏️ pour démarrer',
            style: GoogleFonts.inter(
              color:    AppColors.mediumGray,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}