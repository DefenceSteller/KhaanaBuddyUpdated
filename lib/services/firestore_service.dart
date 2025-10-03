import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  /// Save a recipe (either in history or favorites)
  Future<void> saveRecipe({
    required String userId,
    required String title,
    required String ingredients,
    required String cuisine,
    required String fullText,
    required bool isFavorite,
  }) async {
    final recipeData = {
      "title": title,
      "ingredients": ingredients,
      "cuisine": cuisine,
      "fullText": fullText,
      "timestamp": FieldValue.serverTimestamp(),
    };

    final path = isFavorite ? "favorites" : "history";

    await _db
        .collection("users")
        .doc(userId)
        .collection(path)
        .add(recipeData); // ✅ this actually saves the recipe
  }

  /// Get recipes as a stream (history or favorites)
  Stream<QuerySnapshot> getRecipes(String userId, bool isFavorite) {
    final path = isFavorite ? "favorites" : "history";

    return _db
        .collection("users")
        .doc(userId)
        .collection(path)
        .orderBy("timestamp", descending: true)
        .snapshots();
  }
}
