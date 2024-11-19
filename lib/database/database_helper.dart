import 'dart:io';
import '../models/user.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // Returns the database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('user.db');
    return _database!;
  }

  // Initialize the database at the custom path (external storage)
  Future<Database> _initDB(String filePath) async {
    final directory =
        await getExternalStorageDirectory(); // Use path_provider for dynamic directory path
    final dbPath = join(directory!.path, 'BingoGame', 'database', filePath);

    // Ensure the directory exists
    final dbDir = Directory(join(directory.path, 'BingoGame', 'database'));
    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }

    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: _createDB,
    );
  }

  // Create the users table
  Future<void> _createDB(Database db, int version) async {
    String sqlUsers = '''CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      email TEXT NOT NULL,
      password TEXT NOT NULL,
      username TEXT NOT NULL
    )''';

    String sqlTrans = '''CREATE TABLE transactions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      type TEXT NOT NULL, -- e.g., 'win', 'loss', 'purchase'
      amount INTEGER NOT NULL,
      timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY(user_id) REFERENCES users(id)
    )''';

    String sqlCredits = '''CREATE TABLE credits (
      user_id INTEGER PRIMARY KEY,
      balance INTEGER NOT NULL,
      FOREIGN KEY (user_id) REFERENCES users (id)
    )''';

    await db.execute(sqlUsers);
    await db.execute(sqlTrans);
    await db.execute(sqlCredits);
  }

  // Register the user and initialize credits
  Future<int> registerUser(User user) async {
    final db = await database;
    try {
      // Insert the user data
      int userId = await db.insert('users', user.toMap());

      // Initialize credits to 300 only during registration
      await initializeCredits(userId);

      return userId;
    } catch (e) {
      print("Error during registration: $e");
      return 0;
    }
  }

// Initialize credits for the new user
  Future<void> initializeCredits(int userId) async {
    final db = await database;

    // Check if the user already has credits before initializing them
    final existingCredits = await getCredits(userId);
    if (existingCredits == 0) {
      await db.insert('credits', {'user_id': userId, 'balance': 300});
    }
  }

// Check user login
  Future<User?> loginUser(String email, String password) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    if (result.isNotEmpty) {
      // Fetch the user but do NOT initialize or reset credits here
      return User.fromMap(result.first);
    } else {
      return null;
    }
  }

// Get the credits of a user
  Future<int> getCredits(int userId) async {
    final db = await database;
    final result = await db.query(
      'credits',
      columns: ['balance'],
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    if (result.isNotEmpty) {
      return result.first['balance'] as int;
    }
    return 0; // Default balance if not found
  }

  Future<bool> isEmailExists(String email) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    return result.isNotEmpty;
  }

  Future<bool> isUsernameExists(String username) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    return result.isNotEmpty;
  }

  Future<void> updateCredits(int userId, int amount, String type) async {
    final db = await database;
    await db.transaction((txn) async {
      // Update balance
      await txn.rawUpdate('''
      UPDATE credits 
      SET balance = balance + ?
      WHERE user_id = ?
    ''', [amount, userId]);

      await txn.insert('transactions', {
        'user_id': userId,
        'type': type,
        'amount': amount,
      });
    });
    print('Updating credits: $amount, Type: $type');
  }

  Future<List<Map<String, dynamic>>> getTransactions(int userId) async {
    final db = await database;
    return await db.query(
      'transactions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'timestamp DESC',
    );
  }
}
