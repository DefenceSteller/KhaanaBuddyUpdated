import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

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
      "ingredients" : ingredients,
      "cuisine": cuisine,
      "fullText": fullText,
      "Timestamp" : FieldValue.serverTimestamp(),
    };

    final path = isFavorite ?  "favorites" : "history";

    await _db
    .collection("users")
    .doc(userId)
    .collection(path)
    .orderBy("timestamp", descending: true)
    .snapshots();
  }
}