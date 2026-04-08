
class StoryPage {
  final String id;
  String text;
  String imageDescription;
  String backgroundColor;

  StoryPage({
    required this.id,
    this.text = '',
    this.imageDescription = '',
    this.backgroundColor = '#FFD6E8',
  });

  StoryPage copyWith({
    String? text,
    String? imageDescription,
    String? backgroundColor,
  }) {
    return StoryPage(
      id: id,
      text: text ?? this.text,
      imageDescription: imageDescription ?? this.imageDescription,
      backgroundColor: backgroundColor ?? this.backgroundColor,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'imageDescription': imageDescription,
        'backgroundColor': backgroundColor,
      };

  factory StoryPage.fromJson(Map<String, dynamic> json) => StoryPage(
        id: json['id'] as String,
        text: json['text'] as String? ?? '',
        imageDescription: json['imageDescription'] as String? ?? '',
        backgroundColor: json['backgroundColor'] as String? ?? '#FFD6E8',
      );
}

class Story {
  final String id;
  String title;
  String coverColor;
  String coverEmoji;
  List<StoryPage> pages;
  bool isFavorite;
  final DateTime createdAt;
  DateTime updatedAt;

  Story({
    required this.id,
    required this.title,
    required this.coverColor,
    required this.coverEmoji,
    required this.pages,
    this.isFavorite = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Story copyWith({
    String? title,
    String? coverColor,
    String? coverEmoji,
    List<StoryPage>? pages,
    bool? isFavorite,
    DateTime? updatedAt,
  }) {
    return Story(
      id: id,
      title: title ?? this.title,
      coverColor: coverColor ?? this.coverColor,
      coverEmoji: coverEmoji ?? this.coverEmoji,
      pages: pages ?? this.pages,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'coverColor': coverColor,
        'coverEmoji': coverEmoji,
        'pages': pages.map((p) => p.toJson()).toList(),
        'isFavorite': isFavorite,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Story.fromJson(Map<String, dynamic> json) => Story(
        id: json['id'] as String,
        title: json['title'] as String,
        coverColor: json['coverColor'] as String,
        coverEmoji: json['coverEmoji'] as String,
        pages: (json['pages'] as List<dynamic>)
            .map((p) => StoryPage.fromJson(p as Map<String, dynamic>))
            .toList(),
        isFavorite: json['isFavorite'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

List<Story> sampleStories() {
  final now = DateTime.now();
  return [
    Story(
      id: 'sample_1',
      title: 'The Dragon and the Moon',
      coverColor: '#FFD6E8',
      coverEmoji: '🐉',
      isFavorite: true,
      createdAt: now.subtract(const Duration(days: 2)),
      updatedAt: now.subtract(const Duration(hours: 1)),
      pages: [
        StoryPage(
          id: 'p1',
          text:
              'Once upon a time, a tiny dragon named Ember loved to look at the moon every night.',
          imageDescription:
              'A small cute dragon sitting on a hill looking at the moon',
          backgroundColor: '#FFD6E8',
        ),
        StoryPage(
          id: 'p2',
          text: 'One night, the moon asked Ember to come play in the sky!',
          imageDescription: 'A dragon flying up toward a smiling moon',
          backgroundColor: '#C0E5FF',
        ),
        StoryPage(
          id: 'p3',
          text:
              'Together they danced among the stars and became the best of friends.',
          imageDescription:
              'A dragon and moon dancing with stars around them',
          backgroundColor: '#C2F5E9',
        ),
      ],
    ),
    Story(
      id: 'sample_2',
      title: 'Bunny in Space',
      coverColor: '#C0E5FF',
      coverEmoji: '🐰',
      isFavorite: false,
      createdAt: now.subtract(const Duration(days: 5)),
      updatedAt: now.subtract(const Duration(days: 1)),
      pages: [
        StoryPage(
          id: 'p1',
          text: 'Bella the Bunny always dreamed of visiting the stars.',
          imageDescription:
              'A bunny wearing an astronaut suit looking at the stars',
          backgroundColor: '#E5DEFF',
        ),
        StoryPage(
          id: 'p2',
          text: 'She built a rocket from carrots and launched into space!',
          imageDescription: 'A bunny in a carrot rocket ship blasting off',
          backgroundColor: '#C0E5FF',
        ),
      ],
    ),
  ];
}
