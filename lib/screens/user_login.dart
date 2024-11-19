import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _passwordVisible = false; // Boolean to toggle password visibility

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),  // Duration of the animation
      vsync: this,
    )..repeat(reverse: true);  // Repeat the animation back and forth
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> saveUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', userId);
  }

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    // Function to handle login
    Future<void> _login() async {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();

      if (email.isEmpty || password.isEmpty) {
        _showMessage(context, 'Both email and password are required.');
        return;
      }

      try {
        final dbHelper = DatabaseHelper.instance;
        final user = await dbHelper.loginUser(email, password);

        if (user != null) {
          await saveUserId(user.id!); // Save user ID in SharedPreferences
          // Navigate to the Bingo screen on successful login
          Navigator.pushNamed(context, '/bingo');
        } else {
          _showMessage(context, 'Invalid email or password.');
        }
      } catch (e) {
        _showMessage(context, 'An error occurred: $e');
      }
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg.png'), // Set your background image path here
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Bingo Mania with neon glowing effect animation
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        stops: [
                          _animationController.value,
                          _animationController.value + 0.1, // Control where the light moves
                          _animationController.value + 0.2,
                          _animationController.value + 0.3,
                          _animationController.value + 0.4,
                          _animationController.value + 0.5,
                        ],
                        colors: [
                          Color(0xffb22222),
                          Colors.blueAccent,
                          Colors.pinkAccent,
                          Colors.greenAccent,
                          Colors.yellowAccent,
                          Colors.purpleAccent,
                        ], // Multiple neon colors
                      ).createShader(bounds);
                    },
                    child: Text(
                      'Bingo Mania',
                      style: TextStyle(
                        fontFamily: 'Bingo', // You can change the font to match your design
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // Fallback color if no glow
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 40), // Add some space between title and text fields

              // Email TextField
              TextField(
                controller: emailController,
                style: TextStyle(color: Colors.white),  // White text color
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Colors.white), // White label text
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white), // White line when not focused
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white), // White line when focused
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Password TextField with toggle visibility
              TextField(
                controller: passwordController,
                style: TextStyle(color: Colors.white),  // White text color
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: Colors.white), // White label text
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white), // White line when not focused
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white), // White line when focused
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _passwordVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _passwordVisible = !_passwordVisible; // Toggle visibility
                      });
                    },
                  ),
                ),
                obscureText: !_passwordVisible,  // Toggle the obscureText based on _passwordVisible
              ),
              const SizedBox(height: 30),

              // Login Button
              ElevatedButton(
                onPressed: _login,
                child: const Text('Login'),
              ),
              const SizedBox(height: 10),

              // Register Button
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/register');
                },
                child: const Text('Register', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessage(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
