import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../custom_widgets/insta_textfield.dart';
import '../custom_widgets/insta_button.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 120.h,),
          
                // Email / username textfield
                InstaTextField(
                  controller: _emailController,
                  hintText: 'Email ',
                ),
      
                SizedBox(height: 12.h),
          
                // Password textfield
                InstaTextField(
                  controller: _passwordController,
                  hintText: 'Password',
                  obscureText: true,
                ),

                SizedBox(height: 19.h),

                // Forgot password
                Padding(
                  padding: EdgeInsets.only(left: 253.w, right: 16.w),
                  child: GestureDetector(
                    onTap: () {
                      // Forgot Password Screen
                    },
                    child: Text(
                      'Forgot password?',
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            color: Theme.of(context).colorScheme.onSecondaryFixed,
                            fontSize: 12.sp,
                          ),
                    ),
                  ),
                ),

                SizedBox(height: 30.h),
          
                // Login button
                InstaButton(
                  text: 'Sign Up',
                  isFilled: true,
                  onPressed: () {
                    
                  },
                ),
                SizedBox(height: 12.h),
          
                SizedBox(
                  height: 44.h,
                  width: 343.w,
                  child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.onSurface, // border color
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r), // rounded corners
                    ),
                  ),
                  onPressed: () {
                    // Handle Google sign-in
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center , 
                    children: [
                      Image.asset(
                        'lib/assets/images/google_logo.png',
                        height: 30.h,
                        width: 30.w,
                      ),
                      SizedBox(width: 9.w),
                      Text(
                        'Continue with Google',
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 14.sp,
                            ),
                      ),
                    ],
                  ),
                                ),
                ),

                
                SizedBox(height: 12.h),
              ],)

      ),
      ),

    );
  }
}