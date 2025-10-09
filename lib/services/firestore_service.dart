import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {


  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// ✅ Save a recipe to Firestore (in either 'history' or 'favorites')
  Future<void> saveRecipe({
    required String userId,
    required String title,
    required String ingredients,
    required String cuisine,
    required String fullText,
    required bool isFavorite,
  }) async {

    try {
      final recipeData = {
        "title": title,
        "ingredients": ingredients,
        "cuisine": cuisine,
        "fullText": fullText,
        "isFavorite": isFavorite,
        "timestamp": FieldValue.serverTimestamp(),
      };

      final path = isFavorite ? "favorites" : "history";

      await _db
          .collection("users")
          .doc(userId)
          .collection(path)
          .add(recipeData);

      print("✅ Recipe saved successfully under users/$userId/$path");
    } catch (e) {
      print("❌ Error saving recipe: $e");
      rethrow;
    }
  }

  /// ✅ Retrieve a stream of recipes (history or favorites)
  Stream<QuerySnapshot<Map<String, dynamic>>> getRecipes(
      String userId, bool isFavorite) {
    final path = isFavorite ? "favorites" : "history";

    return _db
        .collection("users")
        .doc(userId)
        .collection(path)
        .orderBy("timestamp", descending: true)
        .snapshots();
  }
}
