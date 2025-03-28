import 'package:flutter/material.dart';
import 'insta_textfield.dart';
import 'insta_button.dart';

class LoginPage extends StatefulWidget{
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column( 
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // logo / hello again
              //email / username textfield
              InstaTextField(
                controller: TextEditingController(),
                hintText: 'Email or Username',
              ),
              SizedBox(height: 10),
              //password textfield
              InstaTextField(
                controller: TextEditingController(),
                hintText: 'Password',
                obscureText: true,
              ),
              SizedBox(height: 10),
              //login button
              InstaButton(
                text: "Log in",
                isFilled: true,
                onPressed: () {
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
      )
    );
  }
}