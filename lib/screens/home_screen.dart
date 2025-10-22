import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:khaanabuddy/screens/history_screen.dart';
import 'package:khaanabuddy/screens/profile_screen.dart';
import 'package:khaanabuddy/screens/recipe_detail.dart';
import 'package:khaanabuddy/themes/theme.dart'; // ✅ Import your theme file
import 'package:khaanabuddy/providers/theme_provider.dart';
import 'package:provider/provider.dart';



class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController ingredientController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  String selectedCuisine = "Italian";
  String? userName;
  bool _loadingName = true;
  // bool _isDarkMode = false; // ✅ Dark mode flag
  final FocusNode _searchFocus = FocusNode();

  final List<String> cuisines = [
    "Italian",
    "Chinese",
    "Indian",
    "Mexican",
    "American",
    "Thai",
    "Pakistani",
    "English",
    "Mughlai",
    "French"
  ];

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null && data.containsKey('name')) {
          setState(() {
            userName = data['name'] ?? "User";
            _loadingName = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint("⚠️ Error loading name: $e");
    }

    setState(() {
      userName = "User";
      _loadingName = false;
    });
  }

  void _openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HistoryScreen()),
    );
  }

  void _openProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
    _loadUserName();
  }

  void _findRecipes() {
    FocusScope.of(context).unfocus();

    final ingredients = ingredientController.text.trim();
    if (ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter at least one ingredient')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetail(
          ingredients: ingredients,
          cuisine: selectedCuisine,
        ),
      ),
    );
  }

  void _searchRecipe() {
    final query = searchController.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a recipe name to search')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetail(
          ingredients: query,
          cuisine: "",
        ),
      ),
    );
  }

  void _scrollToSearch() {
    FocusScope.of(context).requestFocus(_searchFocus);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Type a recipe name in the top search bar')),
    );
  }

  // // ✅ Toggle dark mode
  // void _toggleTheme() {
  //   setState(() {
  //     _isDarkMode = !_isDarkMode;
  //   });
  // }

  @override
  Widget build(BuildContext context) {
final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false, // ✅ Remove debug watermark
theme: themeProvider.isDarkMode ? darkTheme : lightTheme,
      home: Scaffold(
        appBar: AppBar(
          title: SizedBox(
            height: 40,
            child: TextField(
              controller: searchController,
              focusNode: _searchFocus,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _searchRecipe(),
              style: TextStyle(
                color: themeProvider.isDarkMode ? Colors.white : Colors.black, // ✅ White text in dark mode
              ),
              decoration: InputDecoration(
                hintText: "Search any recipe...",
                hintStyle: TextStyle(
                    color: themeProvider.isDarkMode ? Colors.white70 : Colors.black54),
                filled: true,
                fillColor:
                    themeProvider.isDarkMode ? Colors.grey[850] : Colors.white, // ✅ Field color adapts
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                prefixIcon:
                    const Icon(Icons.search, color: Color(0xFFFF7A1A)),
              ),
            ),
          ),
          backgroundColor: const Color(0xFFFF7A1A),
          foregroundColor: Colors.white,
          actions: [
            // ✅ Dark mode toggle
            IconButton(
  icon: Icon(
    themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
  ),
  tooltip: themeProvider.isDarkMode ? "Light Mode" : "Dark Mode",
  onPressed: () => themeProvider.toggleTheme(),
),
            IconButton(
              icon: const Icon(Icons.person),
              tooltip: "Profile",
              onPressed: _openProfile,
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_loadingName)
                const LinearProgressIndicator(color: Color(0xFFFF7A1A))
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Text(
                    "Hello, ${userName ?? 'User'} 👋",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF7A1A),
                    ),
                  ),
                ),
              const Text(
                "Enter Ingredients",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: ingredientController,
                textInputAction: TextInputAction.done,
                style: TextStyle(
                    color:
                        themeProvider.isDarkMode ? Colors.white : Colors.black), // ✅ White text
                decoration: InputDecoration(
                  hintText: "e.g. tomato, chicken",
                  hintStyle: TextStyle(
                      color: themeProvider.isDarkMode ? Colors.white70 : Colors.black54),
                  filled: true,
                  fillColor: themeProvider.isDarkMode
                      ? Colors.grey[850]
                      : Colors.orange.shade50, // ✅ Background adapts
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide:
                        const BorderSide(color: Color(0xFFFF7A1A), width: 2),
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
                  color: themeProvider.isDarkMode
                      ? Colors.grey[850]
                      : Colors.orange.shade50, // ✅ Adapts with theme
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: const Color(0xFFFF7A1A), width: 1),
                ),
                child: DropdownButton<String>(
                  value: selectedCuisine,
                  isExpanded: true,
                  dropdownColor:
                      themeProvider.isDarkMode ? Colors.grey[850] : Colors.white, // ✅ Dark dropdown
                  underline: const SizedBox(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => selectedCuisine = value);
                  },
                  items: cuisines.map((cuisine) {
                    return DropdownMenuItem(
                      value: cuisine,
                      child: Text(
                        cuisine,
                        style: TextStyle(
                          color: themeProvider.isDarkMode
                              ? Colors.white
                              : Colors.black, // ✅ White text in dark mode
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const Spacer(flex: 2),
              ElevatedButton(
                onPressed: _findRecipes,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7A1A),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                    const Text("Find Recipes", style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 15),
              OutlinedButton.icon(
                onPressed: _openHistory,
                icon:
                    const Icon(Icons.bookmark, color: Color(0xFFFF7A1A)),
                label: const Text(
                  "View Saved Recipes",
                  style: TextStyle(
                      color: Color(0xFFFF7A1A),
                      fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  side: const BorderSide(
                      color: Color(0xFFFF7A1A), width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              OutlinedButton.icon(
                onPressed: _scrollToSearch,
                icon:
                    const Icon(Icons.search, color: Color(0xFFFF7A1A)),
                label: const Text(
                  "Search Recipe",
                  style: TextStyle(
                      color: Color(0xFFFF7A1A),
                      fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  side: const BorderSide(
                      color: Color(0xFFFF7A1A), width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
