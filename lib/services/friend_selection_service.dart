import 'package:shared_preferences/shared_preferences.dart';

class FriendSelectionService {
  static const String _friendKey = 'selected_friend';

  // Private constructor
  FriendSelectionService._internal();

  // Singleton instance
  static final FriendSelectionService _instance =
      FriendSelectionService._internal();

  // Factory constructor to return the singleton instance
  factory FriendSelectionService() {
    return _instance;
  }

  // Get the singleton instance directly
  static FriendSelectionService get instance => _instance;

  // Save selected friend
  Future<bool> saveFriend(String friendKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_friendKey, friendKey);
    } catch (e) {
      return false;
    }
  }

  // Get selected friend
  Future<String?> getSelectedFriend() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_friendKey);
    } catch (e) {
      return null;
    }
  }

  // Check if friend is selected
  Future<bool> hasFriendSelected() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final selectedFriend = prefs.getString(_friendKey);
      return selectedFriend != null && selectedFriend.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Clear selected friend (for logout or reset)
  Future<bool> clearFriend() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_friendKey);
    } catch (e) {
      return false;
    }
  }
}
