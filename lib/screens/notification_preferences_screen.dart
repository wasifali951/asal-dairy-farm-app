import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({Key? key}) : super(key: key);

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  late NotificationPreferences _prefs;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    _prefs = user?.notificationPrefs ?? NotificationPreferences();
  }

  Future<void> _savePreferences() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user == null) {
      return;
    }

    setState(() => _isSaving = true);

    await authProvider.updateNotificationPreferences(user.id, _prefs);

    if (!mounted) {
      return;
    }

    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preferences saved.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    if (authProvider.currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to edit preferences.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF2196F3)],
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Order updates'),
            value: _prefs.orderUpdates,
            onChanged: (value) {
              setState(() => _prefs = _prefs.copyWith(orderUpdates: value));
            },
          ),
          SwitchListTile(
            title: const Text('Promotional offers'),
            value: _prefs.promotionalOffers,
            onChanged: (value) {
              setState(
                () => _prefs = _prefs.copyWith(promotionalOffers: value),
              );
            },
          ),
          SwitchListTile(
            title: const Text('New products'),
            value: _prefs.newProducts,
            onChanged: (value) {
              setState(() => _prefs = _prefs.copyWith(newProducts: value));
            },
          ),
          SwitchListTile(
            title: const Text('Weekly deals'),
            value: _prefs.weeklyDeals,
            onChanged: (value) {
              setState(() => _prefs = _prefs.copyWith(weeklyDeals: value));
            },
          ),
          SwitchListTile(
            title: const Text('Reorder reminders'),
            value: _prefs.reorderReminders,
            onChanged: (value) {
              setState(
                () => _prefs = _prefs.copyWith(reorderReminders: value),
              );
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _savePreferences,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save preferences'),
            ),
          ),
        ],
      ),
    );
  }
}
