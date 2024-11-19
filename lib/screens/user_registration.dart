import 'package:flutter/material.dart';
import '../models/user.dart'; // Ensure this import is correct
import '../database/database_helper.dart'; // Ensure this import is correct
import 'package:permission_handler/permission_handler.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final ValueNotifier<String?> _usernameError = ValueNotifier<String?>(null);
  final ValueNotifier<String?> _passwordError = ValueNotifier<String?>(null);

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    requestPermissions();
    _usernameController.addListener(_validateUsername);
    _passwordController.addListener(_validatePassword);
  }

  Future<void> requestPermissions() async {
    PermissionStatus status = await Permission.storage.request();
    if (status.isGranted) {
      print("Permission granted");
    } else if (status.isDenied) {
      print("Permission denied");
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  void _validateUsername() {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      _usernameError.value = "Username cannot be empty.";
    } else if (username.length < 6) {
      _usernameError.value = "Username must be at least 6 characters long.";
    } else {
      _usernameError.value = null;
    }
  }

  void _validatePassword() {
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      _passwordError.value = "Password cannot be empty.";
    } else if (!RegExp(r'^(?=.*[0-9])(?=.*[!@#$%^&*(),.?":{}|<>]).+$').hasMatch(password)) {
      _passwordError.value = "Password must contain at least a number and a special character.";
    } else {
      _passwordError.value = null;
    }
  }

  void _register() async {
    final email = _emailController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    _validateUsername();
    _validatePassword();

    if (_usernameError.value != null || _passwordError.value != null) {
      _showMessage("Please fix the inputs before submitting.");
      return;
    }

    if (email.isEmpty || confirmPassword.isEmpty) {
      _showMessage('All fields are required.');
      return;
    }

    if (password != confirmPassword) {
      _showMessage('Passwords do not match.');
      return;
    }

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      _showMessage('Please enter a valid email address.');
      return;
    }

    try {
      final dbHelper = DatabaseHelper.instance;

      final isEmailExists = await dbHelper.isEmailExists(email);
      final isUsernameExists = await dbHelper.isUsernameExists(username);

      if (isEmailExists) {
        _showMessage('This email is already registered.');
        return;
      }

      if (isUsernameExists) {
        _showMessage('This username is already taken.');
        return;
      }

      final user = User(email: email, password: password, username: username);
      final userId = await dbHelper.registerUser(user);

      if (userId > 0) {
        _showMessage('Registration successful! You have been awarded 300 free credits.', isSuccess: true);
      } else {
        _showMessage('Registration failed. Try again.');
      }
    } catch (e) {
      _showMessage('An error occurred: $e');
    }
  }

  void _showMessage(String message, {bool isSuccess = false}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (isSuccess) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg.png'),
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
                          _animationController.value + 0.1,
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
                        ],
                      ).createShader(bounds);
                    },
                    child: Text(
                      'Bingo Mania',
                      style: TextStyle(
                        fontFamily: 'Bingo', // You can change the font to match your design
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),

              // Email TextField
              TextField(
                controller: _emailController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

              // Username TextField
              TextField(
                controller: _usernameController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Username',
                  labelStyle: TextStyle(color: Colors.white),
                  errorText: _usernameError.value,
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Password TextField
              TextField(
                controller: _passwordController,
                style: TextStyle(color: Colors.white),
                obscureText: !_passwordVisible,
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: Colors.white),
                  errorText: _passwordError.value,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _passwordVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _passwordVisible = !_passwordVisible;
                      });
                    },
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Confirm Password TextField
              TextField(
                controller: _confirmPasswordController,
                style: TextStyle(color: Colors.white),
                obscureText: !_confirmPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  labelStyle: TextStyle(color: Colors.white),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _confirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _confirmPasswordVisible = !_confirmPasswordVisible;
                      });
                    },
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Register Button
              ElevatedButton(
                onPressed: _register,
                child: const Text('Register'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 80),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
