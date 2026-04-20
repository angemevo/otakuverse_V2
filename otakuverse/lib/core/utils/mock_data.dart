import 'package:otakuverse/features/feed/models/post_model.dart';

/// Données fictives pour les tests UI (Phase développement)
/// À retirer en production — remplacer par PostService.getFeed()
final List<PostModel> mockPosts = [
  PostModel(
    id: '1',
    userId: 'user-001',
    username: 'Sh4dx',
    avatarUrl: 'https://i.pravatar.cc/150?img=1',
    caption:
        'Un soir de pluie à Tokyo 🌧️ Les lumières de la ville se reflètent sur le bitume mouillé... '
        'Rien de tel pour se sentir dans un anime 🎌 #Tokyo #Japon #Otaku',
    mediaUrls: ['https://picsum.photos/400/400?random=1'],
    location: 'Tokyo, Japon',
    isPinned: true,
    allowComments: true,
    likesCount: 1243,
    commentsCount: 87,
    sharesCount: 34,
    viewsCount: 8900,
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
  ),

  PostModel(
    id: '2',
    userId: 'user-002',
    username: 'DemonSlayerFan',
    avatarUrl: 'https://i.pravatar.cc/150?img=2',
    caption:
        'Ma collection Demon Slayer est enfin complète 😭🗡️ '
        '3 ans à chasser chaque figurine... Le résultat en vaut la peine ! '
        'Laquelle est votre préférée ?',
    mediaUrls: [
      'https://picsum.photos/400/400?random=2',
      'https://picsum.photos/400/400?random=3',
      'https://picsum.photos/400/400?random=4',
    ],
    location: 'Paris, France',
    isPinned: false,
    allowComments: true,
    likesCount: 3420,
    commentsCount: 214,
    sharesCount: 98,
    viewsCount: 15600,
    createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    updatedAt: DateTime.now().subtract(const Duration(hours: 5)),
  ),

  PostModel(
    id: '3',
    userId: 'user-003',
    username: 'ErenYeager_',
    avatarUrl: 'https://i.pravatar.cc/150?img=3',
    caption:
        'Attack on Titan S4 partie 3 m\'a brisé le cœur 💔 '
        'Je suis encore en train de pleurer une semaine après... '
        'Eren tu aurais pu faire autrement 😤 #AttackOnTitan #AOT #Eren',
    mediaUrls: ['https://picsum.photos/400/400?random=5'],
    location: null,
    isPinned: false,
    allowComments: true,
    likesCount: 876,
    commentsCount: 432,
    sharesCount: 67,
    viewsCount: 5400,
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    updatedAt: DateTime.now().subtract(const Duration(days: 1)),
  ),

  PostModel(
    id: '4',
    userId: 'user-004',
    username: 'ZeroTwo_Cosplay',
    avatarUrl: 'https://i.pravatar.cc/150?img=4',
    caption:
        'Mon cosplay Zero Two fait maison 🎭💕 6 mois de travail pour ce résultat ! '
        'Merci à tous pour le soutien ❤️ #Cosplay #ZeroTwo #DarlingInTheFranxx',
    mediaUrls: [
      'https://picsum.photos/400/400?random=6',
      'https://picsum.photos/400/400?random=7',
      'https://picsum.photos/400/400?random=8',
      'https://picsum.photos/400/400?random=9',
    ],
    location: 'Japan Expo, Paris',
    isPinned: true,
    allowComments: true,
    likesCount: 9870,
    commentsCount: 654,
    sharesCount: 312,
    viewsCount: 45000,
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
    updatedAt: DateTime.now().subtract(const Duration(days: 2)),
  ),

  PostModel(
    id: '5',
    userId: 'user-005',
    username: 'Gojo_Sensei',
    avatarUrl: 'https://i.pravatar.cc/150?img=5',
    caption:
        'Jujutsu Kaisen chapitre 260... je suis sans voix. '
        'Gege Akutami s\'en prend encore à nos émotions 😭 '
        'Qui a survécu à cette lecture ? #JJK #JujutsuKaisen',
    mediaUrls: ['https://picsum.photos/400/400?random=10'],
    location: null,
    isPinned: false,
    allowComments: true,
    likesCount: 2100,
    commentsCount: 389,
    sharesCount: 145,
    viewsCount: 12300,
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
    updatedAt: DateTime.now().subtract(const Duration(days: 3)),
  ),

  PostModel(
    id: '6',
    userId: 'user-006',
    username: 'NarutoGamer99',
    avatarUrl: 'https://i.pravatar.cc/150?img=6',
    caption:
        'Ma setup gaming/anime de rêve est enfin terminée 🎮✨ '
        'RTX 4090 + écran 4K avec des posters Naruto partout... '
        'le paradis existe 🍃 #Setup #Gaming #Naruto',
    mediaUrls: [
      'https://picsum.photos/400/400?random=11',
      'https://picsum.photos/400/400?random=12',
    ],
    location: 'Montréal, Canada',
    isPinned: false,
    allowComments: true,
    likesCount: 5432,
    commentsCount: 178,
    sharesCount: 89,
    viewsCount: 23000,
    createdAt: DateTime.now().subtract(const Duration(days: 5)),
    updatedAt: DateTime.now().subtract(const Duration(days: 5)),
  ),
];
