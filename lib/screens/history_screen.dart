import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:khaanabuddy/services/firestore_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final String userId = "temp_user"; // 🔑 Replace with Firebase Auth UID later

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Recipe History")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreService().getRecipes(userId, false), // false = history
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading recipes"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text("No recipes found"));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              return ListTile(
                title: Text(data["title"] ?? "Recipe"),
                subtitle: Text(data["ingredients"] ?? ""),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/recipe',
                    arguments: {
                      "ingredients": data["ingredients"],
                      "cuisine": data["cuisine"],
                      "userId": userId,
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
