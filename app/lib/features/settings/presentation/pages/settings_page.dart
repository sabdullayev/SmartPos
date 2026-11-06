import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/auth/pin_dialog.dart';
import '../../../../core/auth/user_session.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/storage/hive_boxes.dart';
import '../../../products/presentation/bloc/products_bloc.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _shopNameController = TextEditingController(text: AppConstants.defaultShopName);

  @override
  void dispose() {
    _shopNameController.dispose();
    super.dispose();
  }

  void _resetDemoData() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Перезагрузка каталога'),
        content: const Text('Загрузить демо-товары с новыми качественными фото и штрихкодами?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<ProductsBloc>().add(const SeedDemoProductsEvent());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Каталог с фото успешно загружен!')),
              );
            },
            child: const Text('Загрузить'),
          ),
        ],
      ),
    );
  }

  Future<void> _switchRole(UserRole targetRole) async {
    if (targetRole == UserRole.owner && !UserSession.isBoss) {
      final ok = await PinDialog.requestPin(context, title: 'Вход в режим Владельца');
      if (!ok) return;
    }
    await UserSession.switchRole(targetRole);
    setState(() {});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            targetRole == UserRole.owner ? 'Режим: Владелец (полный доступ)' : 'Режим: Кассир (только продажи)',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalProducts = HiveBoxes.productsBox.values.where((p) => !p.isDeleted).length;
    final totalSales = HiveBoxes.salesBox.length;
    final totalShifts = HiveBoxes.shiftsBox.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки и Управление'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Role selection card (RBAC)
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFF0F766E), width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.security, color: Color(0xFF0F766E)),
                      const SizedBox(width: 8),
                      Text(
                        'Роль пользователя (RBAC)',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Разделение прав: кассир не видит закупку и чистую прибыль, не может удалять товары.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 14),
                  SegmentedButton<UserRole>(
                    segments: const [
                      ButtonSegment(
                        value: UserRole.owner,
                        label: Text('Владелец (Босс)'),
                        icon: Icon(Icons.admin_panel_settings_outlined),
                      ),
                      ButtonSegment(
                        value: UserRole.cashier,
                        label: Text('Кассир (Продавец)'),
                        icon: Icon(Icons.person_outline),
                      ),
                    ],
                    selected: {UserSession.currentRole},
                    onSelectionChanged: (set) => _switchRole(set.first),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    UserSession.isBoss
                        ? '✅ Полный доступ к прибыли, складу и ценам'
                        : '🔒 Ограниченный режим: только касса и чеки',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: UserSession.isBoss ? const Color(0xFF0F766E) : Colors.orange.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // SaaS Plan Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Тариф: Free Trial',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '14 дней бесплатно',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Безлимит товаров, синхронизация с облаком и Telegram-отчеты владельцу всего за 5–10\$/мес.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Для активации PRO перейдите в бота: @SmartPosBot'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.telegram, color: Color(0xFF0F766E)),
                  label: const Text('Активировать PRO через Telegram'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0F766E),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Shop details
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Данные торговой точки',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _shopNameController,
                    decoration: const InputDecoration(
                      labelText: 'Название магазина в чеке',
                      prefixIcon: Icon(Icons.store),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Основная валюта'),
                    subtitle: Text('По умолчанию: ${AppConstants.currency}'),
                    leading: const Icon(Icons.monetization_on_outlined),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Local Database stats
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Оффлайн база данных (Hive)',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Все данные надежно хранятся на этом устройстве и доступны даже без интернета.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const Divider(height: 24),
                  _buildStatRow('Товаров в номенклатуре:', '$totalProducts шт'),
                  _buildStatRow('Пробитых чеков:', '$totalSales шт'),
                  _buildStatRow('Кассовых смен:', '$totalShifts шт'),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: _resetDemoData,
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Перезагрузить демо-товары с фото'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // About app
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline, color: Color(0xFF0F766E)),
              title: const Text('SmartPOS B2B SaaS v1.0.0'),
              subtitle: const Text('Offline-First Mobile & Desktop POS System'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
