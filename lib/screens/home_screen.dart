import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TextEditingController ingredientController = TextEditingController();
  String selectedCuisine = "Italian";

  final List<String> cuisines = [
    "Italian", "Chinese", "Indian", "Mexican", "American", "Thai", "Pakistani", "English", "Mughlai",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("AI Chef")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Enter Ingredients", style: TextStyle(fontSize: 18)),
            TextField(
              controller: ingredientController,
              decoration: InputDecoration(hintText: "e.g. tomato, chicken"),
            ),
            SizedBox(height: 20),
            Text("Choose Cuisine", style: TextStyle(fontSize: 18)),
            DropdownButton<String>(
              value: selectedCuisine,
              isExpanded: true,
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
            Spacer(),

            // ✅ Logout Button (Firebase)
            ElevatedButton.icon(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, '/');
              },
              icon: Icon(Icons.logout),
              label: Text("Logout"),
            ),

            SizedBox(height: 10),

            // ✅ Find Recipes Button
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/recipe',
                  arguments: {
                    "ingredients": ingredientController.text,
                    "cuisine": selectedCuisine
                  },
                );
              },
              child: Text("Find Recipes"),
              style: ElevatedButton.styleFrom(minimumSize: Size.fromHeight(50)),
            )
          ],
        ),
      ),
    );
  }
}
