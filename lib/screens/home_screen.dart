import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController ingredientController = TextEditingController();
  String selectedCuisine = "Italian";

  final List<String> cuisines = [
    "Italian", "Chinese", "Indian", "Mexican", "American",
    "Thai", "Pakistani", "English", "Mughlai",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Chef"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Enter Ingredients",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: ingredientController,
              decoration: InputDecoration(
                hintText: "e.g. tomato, chicken",
                filled: true,
                fillColor: Colors.orange.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.orange, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 30),

            const Text(
              "Choose Cuisine",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange, width: 1),
              ),
              child: DropdownButton<String>(
                value: selectedCuisine,
                isExpanded: true,
                underline: const SizedBox(),
                onChanged: (value) {
                  setState(() => selectedCuisine = value!);
                },
                items: cuisines.map((cuisine) {
                  return DropdownMenuItem(
                    value: cuisine,
                    child: Text(cuisine),
                  );
                }).toList(),
              ),
            ),

            const Spacer(),

            // 🔸 Find Recipes Button
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/recipe',
                  arguments: {
                    "ingredients": ingredientController.text,
                    "cuisine": selectedCuisine,
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Find Recipes", style: TextStyle(fontSize: 16)),
            ),

            const SizedBox(height: 12),

            // 🔸 Logout Button
            OutlinedButton.icon(
              onPressed: () {
                _logout();
              },
              icon: const Icon(Icons.logout, color: Colors.orange),
              label: const Text(
                "Logout",
                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                side: const BorderSide(color: Colors.orange, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/');
  }
}