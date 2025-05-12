import 'package:flutter/material.dart';
import '../custom_widgets/insta_textfield.dart';
import '../custom_widgets/insta_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Text controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future logIn() async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double logoFontSize = 64.sp; // Responsive font size
    return Scaffold(
      body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 120.h,),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 96.w,),
                  child: Text(
                    'Vivir',
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontFamily: 'Pacifico',
                          fontSize: logoFontSize, // Responsive font size
                        ),
                  ),
                ),
                SizedBox(height: 42.h),
          
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
                  text: 'Log in',
                  isFilled: true,
                  onPressed: () {
                    logIn();
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
          
                // Create new account
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            color: Theme.of(context).colorScheme.onSecondaryFixed,
                            fontSize: 14.sp,
                          ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // signup
                      },
                      child: Text(
                        'Sign up',
                        style: Theme.of(context).textTheme.displayLarge!.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 14.sp,
                            ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 40.h),

                // Debug login button
                 Padding(
                  padding: EdgeInsets.only(bottom: 24.h),
                  child: TextButton(
                    onPressed: () {
                      _emailController.text = "ruhma@gmail.com";
                      _passwordController.text = "password123";
                      logIn();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: Text(
                      'Debug Login',
                      style: TextStyle(
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                ),

                
              ],
            ),
          ),
        ),
      
    );
  }
}