import 'package:flutter/material.dart';

import 'main_screens/home_page.dart';
import 'main_screens/profile/profile_page.dart';
import 'main_screens/add_post.dart';
import 'main_screens/reels_page.dart';
import 'main_screens/search_screen.dart';

class MainHomeScreen extends StatefulWidget {
  @override
  _MainHomeScreenState createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> widgetOptions =  [
    HomePage(),
    SearchScreen(),
    AddPost(),
    ReelsPage(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      backgroundColor: Colors.black,
      title: Image.asset(
        'lib/assets/images/vivir_icon.png',
        height: 60, // adjust as needed
        color: Colors.white,
      ),
    ),

      body: widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
      showSelectedLabels: false, // Hide selected labels
      showUnselectedLabels: false, // Hide unselected labels
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.blueGrey,
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: '', // Remove label
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
          icon: Icon(Icons.video_label),
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
