import 'package:flutter/material.dart';
import '../models/user.dart'; // Ensure this import is correct
import '../database/database_helper.dart'; // Ensure this import is correct
import 'package:permission_handler/permission_handler.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final ValueNotifier<String?> _usernameError = ValueNotifier<String?>(null);
  final ValueNotifier<String?> _passwordError = ValueNotifier<String?>(null);

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
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
      _usernameError.value = null; // Valid username
    }
  }

  void _validatePassword() {
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      _passwordError.value = "Password cannot be empty.";
    } else if (!RegExp(r'^(?=.*[0-9])(?=.*[!@#$%^&*(),.?":{}|<>]).+$')
        .hasMatch(password)) {
      _passwordError.value =
          "Password must contain at least a number and a special character.";
    } else {
      _passwordError.value = null; // Valid password
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

    // Check for empty fields
    if (email.isEmpty || confirmPassword.isEmpty) {
      _showMessage('All fields are required.');
      return;
    }

    if (password != confirmPassword) {
      _showMessage('Passwords do not match.');
      return;
    }

    // Check if email is valid
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      _showMessage('Please enter a valid email address.');
      return;
    }

    try {
      final dbHelper = DatabaseHelper.instance;

      // Check if email or username already exists
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

      // Create a user object
      final user = User(
        email: email,
        password: password,
        username: username,
      );

      // Register the user in the database
      final userId = await dbHelper.registerUser(user);

      if (userId > 0) {
        // Show success message and redirect to login page
        _showMessage('Registration successful!', isSuccess: true);
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
                Navigator.of(context).pop(); // Close the dialog
                if (isSuccess) {
                  Navigator.pushReplacementNamed(
                      context, '/login'); // Redirect to login page
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
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                helperText: 'Username must be at least 6 characters long.',
                errorText: _usernameError.value,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: !_passwordVisible,
              decoration: InputDecoration(
                labelText: 'Password',
                helperText:
                    'Password must contain at least a number and a special character.',
                errorText: _passwordError.value,
                suffixIcon: IconButton(
                  icon: Icon(
                    _passwordVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _passwordVisible = !_passwordVisible;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              obscureText: !_confirmPasswordVisible,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _confirmPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _confirmPasswordVisible = !_confirmPasswordVisible;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _register,
              child: const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}
