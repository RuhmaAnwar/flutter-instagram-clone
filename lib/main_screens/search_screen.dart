import 'package:flutter/material.dart';
import '../custom_widgets/insta_textfield.dart';
import '../theme/colors.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

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
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient, // Match login page background
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: InstaTextField(
                controller: _searchController,
                hintText: 'Search',
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: 3, // Placeholder for 3 items
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(
                      'username_${index + 1}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    subtitle: Text(
                      'User ${index + 1}',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient, // Use gradient for button
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Follow',
                        style: Theme.of(context).textTheme.labelLarge!.copyWith(
                              color: Colors.white, // White text for contrast
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    onTap: () {
                      // Placeholder for follow logic
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}