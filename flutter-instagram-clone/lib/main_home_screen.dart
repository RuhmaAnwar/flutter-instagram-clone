import 'package:flutter/material.dart';
import 'package:flutter_instagram_clone/main_screens/chat_page.dart';
import 'main_screens/home_page.dart';
import 'main_screens/add_post.dart';
import 'main_screens/search_screen.dart';
import 'main_screens/profile_page.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  static final GlobalKey<_MainHomeScreenState> mainKey = GlobalKey<_MainHomeScreenState>();

  @override
  _MainHomeScreenState createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> widgetOptions = [
    const HomePage(),
    const SearchScreen(),
    const AddPost(),
    const ChatPage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void switchToHomeTab() {
    setState(() {
      _selectedIndex = 0; // Switch to HomePage tab
    });
  }

  @override
  Widget build(BuildContext context) {
    double logoFontSize = 30.sp;
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      key: MainHomeScreen.mainKey, // Assign the GlobalKey
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Vivir',
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                color: isDarkMode ? Colors.white : Colors.black,
                fontFamily: 'Pacifico',
                fontSize: logoFontSize,
              ),
        ),
      ),
      body: widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: isDarkMode ? Colors.white : Colors.black,
        unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.messenger),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}