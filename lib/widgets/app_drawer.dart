import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/localization/locale_provider.dart';
import '../l10n/generated/app_localizations.dart';
import '../core/routing/app_routes.dart';
import '../services/api_service.dart';

class AppDrawer extends StatelessWidget {
  final LocaleProvider localeProvider;
  final ApiService? apiService;
  final VoidCallback? onLogout;

  const AppDrawer({
    super.key,
    required this.localeProvider,
    this.apiService,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFA2640A), Color(0xFF784107)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/granthalay_logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.appTitle,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'श्रावकरत्न सप्तम प्रतिमाधारी\nवसंत दादाश्री जिनवाणी महाग्रंथालय',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.25,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Navigation Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _DrawerItem(
                    icon: Icons.person_search_outlined,
                    title: l10n.quickSearchPerson,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.searchPerson);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.outbox_rounded,
                    title: l10n.quickIssueBook,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.issueBook);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.move_to_inbox_rounded,
                    title: l10n.quickReturnBook,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.returnBook);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.alarm_rounded,
                    title: l10n.overdueBooks,
                    iconColor: AppColors.error,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.overdueBooks);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.library_books_outlined,
                    title: l10n.currentlyIssuedTitle,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.currentlyIssued);
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.insights_rounded,
                    title: l10n.reportsTitle,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.reports);
                    },
                  ),
                  const Divider(height: 16),
                  _DrawerItem(
                    icon: Icons.settings_outlined,
                    title: l10n.navSettings,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.settings);
                    },
                  ),
                ],
              ),
            ),

            // Footer Language Switch & Logout
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border, width: 1)),
              ),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      localeProvider.toggleLocale();
                    },
                    icon: const Icon(Icons.language_rounded, size: 16),
                    label: Text(localeProvider.isMarathi ? 'EN' : 'मराठी'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(l10n.logout),
                          content: Text(l10n.logoutConfirm),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: Text(l10n.cancel),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  AppRoutes.login,
                                  (route) => false,
                                );
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                              child: Text(l10n.logout),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.logout, size: 16, color: AppColors.error),
                    label: Text(l10n.logout, style: const TextStyle(color: AppColors.error)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? iconColor;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.primary, size: 22),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      dense: true,
      visualDensity: const VisualDensity(vertical: -1),
      onTap: onTap,
    );
  }
}
