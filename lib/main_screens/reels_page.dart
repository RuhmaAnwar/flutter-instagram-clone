import 'package:flutter/material.dart';
import '../theme/colors.dart';

class ReelsPage extends StatefulWidget {
  const ReelsPage({super.key});

  @override
  State<ReelsPage> createState() => _ReelsPageState();
}

class _ReelsPageState extends State<ReelsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // decoration: const BoxDecoration(
        //   gradient: AppColors.primaryGradient, // Match login page background
        // ),
        child: Center(
          child: Text(
            'Reels Page',
            style: Theme.of(context).textTheme.displayLarge, // Use theme typography
          ),
        ),
      ),
    );
  }
}