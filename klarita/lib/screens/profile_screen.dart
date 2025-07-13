import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/klarita_logo.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const KlaritaLogo(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Section
            Text('Account', style: textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.md),
            Card(
              child: ListTile(
                leading: const Icon(Icons.email_outlined, color: AppTheme.textSecondary),
                title: Text(authProvider.userEmail ?? 'No email found'),
                subtitle: const Text('Email Address'),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            
            // Appearance Section
            Text('Appearance', style: textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.md),
            Card(
              child: ListTile(
                leading: Icon(
                  themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: AppTheme.textSecondary,
                ),
                title: const Text('Dark Mode'),
                subtitle: Text(themeProvider.isDarkMode ? 'Enabled' : 'Disabled'),
                trailing: Switch(
                  value: themeProvider.isDarkMode,
                  onChanged: (value) {
                    themeProvider.setTheme(value);
                  },
                  activeColor: AppTheme.primary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            
            const Spacer(),
            
            // Logout Button
            ElevatedButton(
              onPressed: () {
                Provider.of<AuthProvider>(context, listen: false).logout();
                // After logout, you might want to navigate to the login screen.
                // This depends on how your auth gate is set up.
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: AppTheme.error,
              ),
              child: const Text('Logout'),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
} 