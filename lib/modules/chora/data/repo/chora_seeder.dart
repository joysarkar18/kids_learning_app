import 'package:cloud_firestore/cloud_firestore.dart';

class ChoraSeeder {
  static Future<void> seed() async {
    final firestore = FirebaseFirestore.instance;
    final collection = firestore.collection('choras');

    // Check if data already exists
    final existing = await collection.limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final choras = [
      {
        'title': 'টুকটুকি',
        'text':
            'টুক টুক টুক, দরজা খোলো\nকে এসেছে বলো বলো\nছোট্ট একটা পাখি এলো\nগান গেয়ে সে উড়ে গেলো।',
        'youtube_url': 'https://www.youtube.com/watch?v=z1iJsPdrICY',
        'thumbnail_url':
            'https://play-lh.googleusercontent.com/KLd2hnvpcSZqpM1ys5DWVepg0mETf8LYc4hKTJwkADzqwq9CxZkQyh8IMeuptPBeXWsD',
        'order': 1,
      },
      {
        'title': 'আয় আয় চাঁদ মামা',
        'text':
            'আয় আয় চাঁদ মামা\nটিপ দিয়ে যা\nচাঁদের কপালে চাঁদ\nটিপ দিয়ে যা।',
        'youtube_url': 'https://www.youtube.com/watch?v=z1iJsPdrICY',
        'thumbnail_url':
            'https://play-lh.googleusercontent.com/KLd2hnvpcSZqpM1ys5DWVepg0mETf8LYc4hKTJwkADzqwq9CxZkQyh8IMeuptPBeXWsD',
        'order': 2,
      },
      {
        'title': 'খোকন খোকন ডাক পাড়ি',
        'text':
            'খোকন খোকন ডাক পাড়ি\nখোকন যায় বাড়ি বাড়ি\nহাতে তার মোটা লাঠি\nপায়ে তার ময়লা চটি।',
        'youtube_url': 'https://www.youtube.com/watch?v=z1iJsPdrICY',
        'thumbnail_url':
            'https://play-lh.googleusercontent.com/KLd2hnvpcSZqpM1ys5DWVepg0mETf8LYc4hKTJwkADzqwq9CxZkQyh8IMeuptPBeXWsD',
        'order': 3,
      },
      {
        'title': 'ঘুম পাড়ানি মাসি পিসি',
        'text':
            'ঘুম পাড়ানি মাসি পিসি\nমোদের বাড়ি এসো\nখাট নাই পালং নাই\nমাটিতে শুয়ে ঘুমাও।',
        'youtube_url': 'https://www.youtube.com/watch?v=z1iJsPdrICY',
        'thumbnail_url':
            'https://play-lh.googleusercontent.com/KLd2hnvpcSZqpM1ys5DWVepg0mETf8LYc4hKTJwkADzqwq9CxZkQyh8IMeuptPBeXWsD',
        'order': 4,
      },
    ];

    final batch = firestore.batch();
    for (final chora in choras) {
      batch.set(collection.doc(), chora);
    }
    await batch.commit();
  }
}
