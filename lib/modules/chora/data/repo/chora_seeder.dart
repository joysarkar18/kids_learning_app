import 'package:cloud_firestore/cloud_firestore.dart';

class ChoraSeeder {
  static Future<void> seed() async {
    final firestore = FirebaseFirestore.instance;
    final collection = firestore.collection('choras');

    final choras = [
      {
        'title': 'টুকটুকি',
        'audio_url':
            'https://firebasestorage.googleapis.com/v0/b/your-project-id.appspot.com/o/audios%2Ftuktuki.wav?alt=media',
        'cover_image':
            'https://firebasestorage.googleapis.com/v0/b/your-project-id.appspot.com/o/images%2Ftuktuki_cover.jpg?alt=media',
        'background_image':
            'https://firebasestorage.googleapis.com/v0/b/your-project-id.appspot.com/o/images%2Ftuktuki_bg.jpg?alt=media',
        'text':
            'টুক টুক টুক, দরজা খোলো\nকে এসেছে বলো বলো\nছোট্ট একটা পাখি এলো\nগান গেয়ে সে উড়ে গেলো।',
        'order': 1,
        'duration': 30.0,
      },
      {
        'title': 'আয় আয় চাঁদ মামা',
        'audio_url':
            'https://firebasestorage.googleapis.com/v0/b/your-project-id.appspot.com/o/audios%2Fchand_mama.wav?alt=media',
        'cover_image':
            'https://firebasestorage.googleapis.com/v0/b/your-project-id.appspot.com/o/images%2Fchand_mama_cover.jpg?alt=media',
        'background_image':
            'https://firebasestorage.googleapis.com/v0/b/your-project-id.appspot.com/o/images%2Fchand_mama_bg.jpg?alt=media',
        'text':
            'আয় আয় চাঁদ মামা\nটিপ দিয়ে যা\nচাঁদের কপালে চাঁদ\nটিপ দিয়ে যা।',
        'order': 2,
        'duration': 25.0,
      },
      {
        'title': 'খোকন খোকন ডাক পাড়ি',
        'audio_url':
            'https://firebasestorage.googleapis.com/v0/b/your-project-id.appspot.com/o/audios%2Fkhokon.wav?alt=media',
        'cover_image':
            'https://firebasestorage.googleapis.com/v0/b/your-project-id.appspot.com/o/images%2Fkhokon_cover.jpg?alt=media',
        'background_image':
            'https://firebasestorage.googleapis.com/v0/b/your-project-id.appspot.com/o/images%2Fkhokon_bg.jpg?alt=media',
        'text':
            'খোকন খোকন ডাক পাড়ি\nখোকন যায় বাড়ি বাড়ি\nহাতে তার মোটা লাঠি\nপায়ে তার ময়লা চটি।',
        'order': 3,
        'duration': 28.0,
      },
      {
        'title': 'ঘুম পাড়ানি মাসি পিসি',
        'audio_url':
            'https://firebasestorage.googleapis.com/v0/b/your-project-id.appspot.com/o/audios%2Fghum_parani.wav?alt=media',
        'cover_image':
            'https://firebasestorage.googleapis.com/v0/b/your-project-id.appspot.com/o/images%2Fghum_parani_cover.jpg?alt=media',
        'background_image':
            'https://firebasestorage.googleapis.com/v0/b/your-project-id.appspot.com/o/images%2Fghum_parani_bg.jpg?alt=media',
        'text':
            'ঘুম পাড়ানি মাসি পিসি\nমোদের বাড়ি এসো\nখাট নাই পালং নাই\nমাটিতে শুয়ে ঘুমাও।',
        'order': 4,
        'duration': 32.0,
      },
    ];

    final batch = firestore.batch();
    for (final chora in choras) {
      batch.set(collection.doc(), chora);
    }
    await batch.commit();
  }
}
