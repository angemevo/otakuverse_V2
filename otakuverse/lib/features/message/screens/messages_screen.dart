// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:otakuverse/core/constants/colors.dart';
import 'package:otakuverse/features/message/models/conversation_model.dart';
import 'package:otakuverse/features/message/widgets/conversation_card.dart';


class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> 
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  final List<ConversationModel> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadConversations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);
    
    try {
      // TODO: Appeler le service pour récupérer les conversations
      // final result = await MessagesService().getConversations();
      
      // Simuler un délai
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('❌ Error loading conversations: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepBlack,
      appBar: AppBar(
        backgroundColor: AppColors.deepBlack,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            HeroiconsOutline.arrowLeft,
            color: AppColors.pureWhite,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Messages',
          style: GoogleFonts.poppins(
            color: AppColors.pureWhite,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              HeroiconsOutline.pencilSquare,
              color: AppColors.pureWhite,
            ),
            onPressed: _showNewMessageSheet,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.crimsonRed,
          labelColor: AppColors.pureWhite,
          unselectedLabelColor: AppColors.mediumGray,
          labelStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'Tous'),
            Tab(text: 'Non lus'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildConversationsList(showUnreadOnly: false),
          _buildConversationsList(showUnreadOnly: true),
        ],
      ),
    );
  }

  Widget _buildConversationsList({required bool showUnreadOnly}) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.crimsonRed,
        ),
      );
    }

    final filteredConversations = showUnreadOnly
        ? _conversations.where((c) => c.unreadCount > 0).toList()
        : _conversations;

    if (filteredConversations.isEmpty) {
      return _buildEmptyState(showUnreadOnly);
    }

    return RefreshIndicator(
      color: AppColors.crimsonRed,
      backgroundColor: AppColors.deepBlack,
      onRefresh: _loadConversations,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: filteredConversations.length,
        itemBuilder: (context, index) {
          return ConversationCard(
            conversation: filteredConversations[index],
            onTap: () => _openConversation(filteredConversations[index]),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool showUnreadOnly) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            showUnreadOnly 
                ? HeroiconsOutline.checkCircle 
                : HeroiconsOutline.chatBubbleLeftRight,
            color: AppColors.mediumGray,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            showUnreadOnly 
                ? 'Aucun message non lu'
                : 'Aucune conversation',
            style: GoogleFonts.poppins(
              color: AppColors.pureWhite,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            showUnreadOnly
                ? 'Tous vos messages sont lus'
                : 'Commencez une conversation !',
            style: GoogleFonts.inter(
              color: AppColors.mediumGray,
              fontSize: 13,
            ),
          ),
          if (!showUnreadOnly) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showNewMessageSheet,
              icon: const Icon(
                HeroiconsOutline.pencilSquare,
                size: 18,
              ),
              label: const Text('Nouveau message'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.crimsonRed,
                foregroundColor: AppColors.pureWhite,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showNewMessageSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _NewMessageSheet(),
    );
  }

  void _openConversation(ConversationModel conversation) {
    // TODO: Navigator vers ChatScreen
    print('Open conversation with: ${conversation.displayNameOrUsername}');
  }
}

// ════════════════════════════════════════════════════════════════════
// NOUVEAU MESSAGE SHEET
// ════════════════════════════════════════════════════════════════════
class _NewMessageSheet extends StatefulWidget {
  @override
  State<_NewMessageSheet> createState() => _NewMessageSheetState();
}

class _NewMessageSheetState extends State<_NewMessageSheet> {
  final _searchController = TextEditingController();
  final List<dynamic> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      // TODO: Appeler le service de recherche
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        setState(() => _isSearching = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: AppColors.darkGray,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.mediumGray,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          
          // Titre
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Nouveau message',
                  style: GoogleFonts.poppins(
                    color: AppColors.pureWhite,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: GoogleFonts.inter(
                color: AppColors.pureWhite,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: 'Rechercher un utilisateur...',
                hintStyle: GoogleFonts.inter(
                  color: AppColors.mediumGray,
                ),
                prefixIcon: const Icon(
                  HeroiconsOutline.magnifyingGlass,
                  color: AppColors.mediumGray,
                ),
                filled: true,
                fillColor: AppColors.deepBlack,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _search,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Résultats
          Expanded(
            child: _isSearching
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.crimsonRed,
                    ),
                  )
                : _searchResults.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              HeroiconsOutline.userGroup,
                              color: AppColors.mediumGray,
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _searchController.text.isEmpty
                                  ? 'Recherchez un utilisateur'
                                  : 'Aucun résultat',
                              style: GoogleFonts.inter(
                                color: AppColors.mediumGray,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final user = _searchResults[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: AppColors.mediumGray,
                              child: const Icon(
                                HeroiconsOutline.user,
                                color: AppColors.pureWhite,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              'Username',
                              style: GoogleFonts.inter(
                                color: AppColors.pureWhite,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              // TODO: Ouvrir conversation
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}