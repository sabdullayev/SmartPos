import 'package:flutter/foundation.dart';
import '../../core/storage/hive_boxes.dart';

enum UserRole {
  owner,
  cashier,
}

class UserSession {
  static const String _keyRole = 'user_current_role';
  static const String _keyPin = 'boss_pin_code';
  static const String defaultPin = '0000';

  static final ValueNotifier<UserRole> currentRoleNotifier =
      ValueNotifier<UserRole>(UserRole.owner);

  static UserRole get currentRole => currentRoleNotifier.value;
  static bool get isBoss => currentRole == UserRole.owner;
  static bool get isCashier => currentRole == UserRole.cashier;

  static void init() {
    final savedRole = HiveBoxes.settingsBox.get(_keyRole, defaultValue: 'owner') as String;
    currentRoleNotifier.value = savedRole == 'cashier' ? UserRole.cashier : UserRole.owner;
  }

  static Future<void> switchRole(UserRole role) async {
    currentRoleNotifier.value = role;
    await HiveBoxes.settingsBox.put(_keyRole, role.name);
  }

  static String getBossPin() {
    return HiveBoxes.settingsBox.get(_keyPin, defaultValue: defaultPin) as String;
  }

  static Future<void> setBossPin(String newPin) async {
    await HiveBoxes.settingsBox.put(_keyPin, newPin);
  }

  static bool verifyBossPin(String enteredPin) {
    return enteredPin.trim() == getBossPin();
  }
}
