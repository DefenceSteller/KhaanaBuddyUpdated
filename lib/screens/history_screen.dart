import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:khaanabuddy/services/firestore_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final String userId = "temp user"; // Replace with actual Firebase Auth UID

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Recipe History")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreService().getRecipes(userId, false),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading"));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

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
