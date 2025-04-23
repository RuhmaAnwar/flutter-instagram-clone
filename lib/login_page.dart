import 'package:flutter/material.dart';
import 'insta_textfield.dart';
import 'insta_button.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget{
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  //text controllers
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
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column( 
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // vivir icon
                Image.asset('lib/assets/images/vivir_icon.png',
                  height: 200,
                  scale: 2.5,),

                //email / username textfield
                InstaTextField(
                  controller: _emailController,
                  hintText: 'Email or Username',
                ),
                SizedBox(height: 10),

                //password textfield
                InstaTextField(
                  controller: _passwordController,
                  hintText: 'Password',
                  obscureText: true,
                ),
                SizedBox(height: 10),

                //login button
                InstaButton(
                  text: "Log in",
                  isFilled: true,
                  onPressed: () {
                    logIn();
                  },
                ),
                SizedBox(height: 10),
            
                //forgot password
                GestureDetector(
                  onTap: () {
                    //Forgot Password Screen
                  },
                  child: Text(
                    "Forgot password?",
                    style: TextStyle(
                      color: Colors.black, 
                      fontSize: (screenWidth * 0.039 + screenHeight * 0.023) / 2, 
                    ),
                  ),
                ),
                SizedBox(height: 70),
                InstaButton(
                  text: "Create new account",
                  isFilled: false,
                  onPressed: () {
                  },
                )
            
            
                //sign in button 
                // create new account
              ],
            ),
          ),
        ),
      )
    );
  }
}