import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  late SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Shared Preferences methods for non-sensitive data

  Future<bool> setString(String key, String value) async {
    return await _prefs.setString(key, value);
  }

  String? getString(String key) {
    return _prefs.getString(key);
  }

  Future<bool> setBool(String key, bool value) async {
    return await _prefs.setBool(key, value);
  }

  bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  Future<bool> setInt(String key, int value) async {
    return await _prefs.setInt(key, value);
  }

  int? getInt(String key) {
    return _prefs.getInt(key);
  }

  Future<bool> setDouble(String key, double value) async {
    return await _prefs.setDouble(key, value);
  }

  double? getDouble(String key) {
    return _prefs.getDouble(key);
  }

  Future<bool> setStringList(String key, List<String> value) async {
    return await _prefs.setStringList(key, value);
  }

  List<String>? getStringList(String key) {
    return _prefs.getStringList(key);
  }

  Future<bool> setObject(String key, Map<String, dynamic> value) async {
    return await _prefs.setString(key, jsonEncode(value));
  }

  Map<String, dynamic>? getObject(String key) {
    final String? jsonString = _prefs.getString(key);
    if (jsonString == null) return null;
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  Future<bool> remove(String key) async {
    return await _prefs.remove(key);
  }

  Future<bool> clear() async {
    return await _prefs.clear();
  }

  bool containsKey(String key) {
    return _prefs.containsKey(key);
  }

  // Secure Storage methods for sensitive data

  Future<void> setSecureString(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  Future<String?> getSecureString(String key) async {
    return await _secureStorage.read(key: key);
  }

  Future<void> setSecureObject(String key, Map<String, dynamic> value) async {
    await _secureStorage.write(key: key, value: jsonEncode(value));
  }

  Future<Map<String, dynamic>?> getSecureObject(String key) async {
    final String? jsonString = await _secureStorage.read(key: key);
    if (jsonString == null) return null;
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  Future<void> removeSecure(String key) async {
    await _secureStorage.delete(key: key);
  }

  Future<void> clearSecure() async {
    await _secureStorage.deleteAll();
  }

  Future<bool> containsSecureKey(String key) async {
    final value = await _secureStorage.read(key: key);
    return value != null;
  }

  // App specific methods

  Future<void> saveAuthToken(String token) async {
    await setSecureString('auth_token', token);
  }

  Future<String?> getAuthToken() async {
    return await getSecureString('auth_token');
  }

  Future<void> removeAuthToken() async {
    await removeSecure('auth_token');
  }

  Future<void> saveUserCredentials(String email, String password) async {
    await setSecureObject('user_credentials', {
      'email': email,
      'password': password,
    });
  }

  Future<Map<String, dynamic>?> getUserCredentials() async {
    return await getSecureObject('user_credentials');
  }

  Future<void> removeUserCredentials() async {
    await removeSecure('user_credentials');
  }

  Future<void> setDarkMode(bool value) async {
    await setBool('dark_mode', value);
  }

  bool isDarkMode() {
    return getBool('dark_mode') ?? false;
  }

  Future<void> setFirstLaunch(bool value) async {
    await setBool('first_launch', value);
  }

  bool isFirstLaunch() {
    return getBool('first_launch') ?? true;
  }
}