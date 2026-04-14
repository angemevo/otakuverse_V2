// Données de test partagées entre tous les tests unitaires.

// ─── POST ─────────────────────────────────────────────────────────────────────

Map<String, dynamic> postJson({
  String  id            = 'post-001',
  String  userId        = 'user-001',
  String  caption       = 'Mon premier post otaku !',
  List<String>? mediaUrls,
  String? location,
  bool    allowComments = true,
  int     likesCount    = 42,
  int     commentsCount = 7,
  int     sharesCount   = 3,
  int     viewsCount    = 120,
  bool    isPinned      = false,
  String? musicTitle,
  String? musicArtist,
  String? username      = 'otaku_sensei',
  String? displayName   = 'Otaku Sensei',
  String? avatarUrl     = 'https://example.com/avatar.jpg',
  String? createdAt,
  String? updatedAt,
}) =>
    {
      'id':             id,
      'user_id':        userId,
      'caption':        caption,
      'media_urls':     mediaUrls ?? ['https://example.com/img1.jpg'],
      'location':       ?location,
      'allow_comments': allowComments,
      'likes_count':    likesCount,
      'comments_count': commentsCount,
      'shares_count':   sharesCount,
      'views_count':    viewsCount,
      'is_pinned':      isPinned,
      'music_title':    ?musicTitle,
      'music_artist':   ?musicArtist,
      'profiles': {
        'username':     username,
        'display_name': displayName,
        'avatar_url':   avatarUrl,
      },
      'created_at': createdAt ?? '2025-01-15T10:00:00.000Z',
      'updated_at': updatedAt ?? '2025-01-15T10:00:00.000Z',
    };

// ─── PROFILE ──────────────────────────────────────────────────────────────────

Map<String, dynamic> profileJson({
  String  userId         = 'user-001',
  String? displayName    = 'Otaku Sensei',
  String? bio            = 'Passionné d\'anime depuis toujours.',
  String? avatarUrl      = 'https://example.com/avatar.jpg',
  String? bannerUrl,
  int     followersCount = 150,
  int     followingCount = 80,
  int     postsCount     = 25,
  bool    isPrivate      = false,
  bool    isVerified     = true,
  String  otakuRank      = 'Senpai',
  int     otakuLevel     = 5,
  int     otakuPoints    = 420,
  int     watchlistCount = 33,
  int     reviewsCount   = 12,
  String? createdAt,
  String? updatedAt,
}) =>
    {
      'user_id':         userId,
      'display_name':    displayName,
      'bio':             bio,
      'avatar_url':      avatarUrl,
      'banner_url':      ?bannerUrl,
      'followers_count': followersCount,
      'following_count': followingCount,
      'posts_count':     postsCount,
      'is_private':      isPrivate,
      'is_verified':     isVerified,
      'favorite_anime':  ['Naruto', 'Attack on Titan'],
      'favorite_manga':  ['One Piece'],
      'favorite_games':  ['Elden Ring'],
      'favorite_genres': ['Shonen', 'Seinen'],
      'otaku_rank':      otakuRank,
      'otaku_level':     otakuLevel,
      'otaku_points':    otakuPoints,
      'watchlist_count': watchlistCount,
      'reviews_count':   reviewsCount,
      'created_at': createdAt ?? '2024-06-01T00:00:00.000Z',
      'updated_at': updatedAt ?? '2025-01-15T10:00:00.000Z',
    };

// ─── COMMENT ──────────────────────────────────────────────────────────────────

Map<String, dynamic> commentJson({
  String  id          = 'comment-001',
  String  postId      = 'post-001',
  String  userId      = 'user-001',
  String? parentId,
  String  content     = 'Super post !',
  int     likesCount  = 5,
  String? username    = 'otaku_sensei',
  String? displayName = 'Otaku Sensei',
  String? avatarUrl   = 'https://example.com/avatar.jpg',
  String? createdAt,
  String? updatedAt,
}) =>
    {
      'id':          id,
      'post_id':     postId,
      'user_id':     userId,
      'parent_id':   ?parentId,
      'content':     content,
      'likes_count': likesCount,
      'profiles': {
        'username':     username,
        'display_name': displayName,
        'avatar_url':   avatarUrl,
      },
      'created_at': createdAt ?? '2025-01-15T11:00:00.000Z',
      'updated_at': updatedAt ?? '2025-01-15T11:00:00.000Z',
    };
