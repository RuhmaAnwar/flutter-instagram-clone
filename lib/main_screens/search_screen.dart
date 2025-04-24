import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, String>> _allUsers = [
    {'username': 'khadija_z', 'name': 'Khadija'},
    {'username': 'ruhma:)', 'name': 'Ruhma Anwar'},
    {'username': 'noor.x', 'name': 'Noor'},
  ];

  List<Map<String, String>> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterUsers);
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      setState(() {
        _filteredUsers = [];
      });
      return;
    }

    setState(() {
      _filteredUsers =
          _allUsers.where((user) {
            final username = user['username']!.toLowerCase();
            final name = user['name']!.toLowerCase();
            return username.contains(query) || name.contains(query);
          }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        automaticallyImplyLeading: false, // No back button
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search',
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child:
                _filteredUsers.isEmpty
                    ? const SizedBox() // Show nothing unless there are results
                    : ListView.builder(
                      itemCount: _filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = _filteredUsers[index];
                        return ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.grey,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          title: Text(user['username']!),
                          subtitle: Text(user['name']!),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF7F50), // Coral color
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Follow',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          onTap: () {
                            // Follow logic goes here
                          },
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
