// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {


  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// ✅ Save a recipe to Firestore (for each user's UID)
  Future<void> saveRecipe({
    required String userId,
    required String title,
    required String ingredients,
    required String cuisine,
    required String fullText, // <-- full recipe details
    required bool isFavorite,
  }) async {

    try {
      final recipeData = {
        "title": title,
        "ingredients": ingredients,
        "cuisine": cuisine,
        "fullText": fullText, // <-- make sure this is included
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

  /// ✅ Delete a recipe from Firestore (history or favorites)
  Future<void> deleteRecipe(String userId, String docId,
      {bool isFavorite = false}) async {
    try {
      final path = isFavorite ? "favorites" : "history";
      await _db
          .collection("users")
          .doc(userId)
          .collection(path)
          .doc(docId)
          .delete();

      print("🗑️ Recipe deleted successfully from users/$userId/$path/$docId");
    } catch (e) {
      print("❌ Error deleting recipe: $e");
      rethrow;
    }
  }

  /// ✅ Fetch all recipes once (optional helper)
  Future<List<Map<String, dynamic>>> getRecipesOnce(String userId, bool isFavorite) async {
    final path = isFavorite ? "favorites" : "history";
    final snapshot = await _db
        .collection("users")
        .doc(userId)
        .collection(path)
        .orderBy("timestamp", descending: true)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}
